package comptime;

#if (macro || display)

import haxe.io.Path;
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Type;

import cxx.Compiler as CxxConfig;
import cxxcompiler.Compiler as CxxCompiler;
import cxxcompiler.subcompilers.Types;

import reflaxe.data.ClassVarData;
import reflaxe.data.ClassFuncData;
import reflaxe.input.ClassModifier;
import reflaxe.input.ExpressionModifier;
import reflaxe.output.PluginHook;

using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.NullableMetaAccessHelper;
using reflaxe.helpers.NullHelper;
using reflaxe.helpers.TypeHelper;

class Init {
	public static function init() {
		NameMetaHelper.setNativeNameOverride("String", "godot::String");

		CxxCompiler.ToStringFromPrim = "godot::UtilityFunctions::str";
		CxxCompiler.ToStringFromPrimInclude = ["godot_cpp/variant/utility_functions.hpp", false];

		CxxCompiler.onCompileBegin(function(comp: CxxCompiler) {
			comp.addReservedVarName("self");
			comp.compileClassHook.addHook(function(defaultContent, compiler, classType, vars, funcs) {
				return classHook(defaultContent, cast compiler, classType, vars, funcs);
			});
			comp.compileExpressionHook.addHook(function(defaultContent, compiler, expr, isTopLevel) {
				return exprHook(defaultContent, cast compiler, expr, isTopLevel);
			});
		});

		//Compiler.addGlobalMetadata("tweenxcore.Tools.Easing", "@:build(comptime.Init.removeEasingShake())");
		ClassModifier.mod("tweenxcore.FloatTools", "shake", macro return 0.0);
	}

	static function removeEasingShake() {
		final fields = Context.getBuildFields();

		for(i in 0...fields.length) {
			final f = fields[i];
			if(f.name == "shake") {
				switch(f.kind) {
					case FFun(fun): {
						fun.expr = macro return 0.0;
					}
					case _:
				}
			}
		}

		return fields;
	}

	static function exprHook(defaultContent: String, compiler: CxxCompiler, expr: TypedExpr, isTopLevel: Bool): PluginHookResult<String> {
		// var possiblyArrayExpr = expr;
		// final isUntyped = switch(expr.expr) {
		// 	case TMeta({ name: ":untyped" }, inner): {
		// 		possiblyArrayExpr = inner;
		// 		true;
		// 	}
		// 	case _: false;
		// }

		var possiblyArrayExpr = expr;
		final isUntyped = true;

		switch(possiblyArrayExpr.expr) {
			case TArrayDecl(el): {
				//Main.onTypeEncountered(expr.t, compilingInHeader, expr.pos);

				final IComp = @:privateAccess compiler.IComp;
				final XComp = @:privateAccess compiler.XComp;
				final TComp = @:privateAccess compiler.TComp;

				final arrayType = @:privateAccess compiler.getExprType(expr).unwrapArrayType();

				var include = "godot_cpp/templates/vector.hpp";
				var startCpp = 'godot::Vector<${TComp.compileType(arrayType, possiblyArrayExpr.pos)}>({';
				var endCpp = "})";

				if(isUntyped) {
					include = "godot_cpp/variant/typed_array.hpp";
					startCpp = "godot::Array::make(";
					endCpp = ")";
				}

				IComp.addInclude(include, XComp.compilingInHeader, true);

				final t = TComp.compileType(arrayType, expr.pos);
				//final d = "std::deque<" + t + ">";
				return startCpp + ({
					if(el.length > 0) {
						final cppList: Array<String> = el.map(e -> XComp.compileExpressionForType(e, arrayType).trustMe());
						var newLines = false;
						for(cpp in cppList) {
							if(cpp.length > 5) {
								newLines = true;
								break;
							}
						}
						newLines ? ("\n\t" + cppList.join(",\n\t") + "\n") : (cppList.join(", "));
					} else {
						"";
					}
				}) + endCpp;
			}
			case _:
		}
		return null;
	}

	static function classHook(defaultContent: String, compiler: CxxCompiler, classType: ClassType, variables: Array<ClassVarData>, functions: Array<ClassFuncData>): PluginHookResult<String> {
		if(classType.hasMeta(":gdscript")) {
			final path = classType.meta.extractStringFromFirstMeta(":gdscript");
			if(path == null) {
				throw "Expected String parameter for @:gdscript";
			}

			// Modify the "expr" for all the functions
			for(f in functions) {
				final originalExpr = f.expr;

				//if(f.isStatic)
				if(f.isStatic) {
					continue;
				}

				if(!f.field.isPublic) {
					f.field.meta.add(":extern", [], f.field.pos);
					continue;
				}

				final hasReturn = f.ret != null && !f.ret.isVoid();

				f.setExpr({
					expr: TCall({
						expr: TIdent("__cpp__"),
						pos: originalExpr.pos,
						t: originalExpr.t
					}, [
						{
							expr: TConst(TString({
								if(f.field.name == "new") {
									"_setupSelf()";
								} else {
									final stringArgs = ['"wrap_${f.field.name}"', "this"];
									// if(!f.isStatic) {
									// 	stringArgs.push("this");
									// }
									final args = stringArgs.concat(f.args.map(a -> a.name));
									var result = 'self.call(${args.join(", ")})';
									if(hasReturn) {
										switch(f.ret) {
											case TAbstract(_.get() => cls, [_]) if(cls.name == "Ptr" && cls.pack.length == 1 && cls.pack[0] == "cxx"): {
												final TComp = @:privateAccess compiler.TComp;
												result = "static_cast<" + TComp.compileType(f.ret, f.field.pos) + ">(" + result + ".operator Object *())";
											}
											case _:
										}
										result = "return " + result;
									}
									result;
								}
							})),
							pos: originalExpr.pos,
							t: originalExpr.t
						}
					]),
					pos: originalExpr.pos,
					t: originalExpr.t
				});
			}

			final clsRef = switch(compiler.getCurrentModule()) {
				case TClassDecl(clsRef): clsRef;
				case _: throw "Impossible";
			}
			comptime.RegisterTypesGenerator.exposedTypes.push(clsRef);

			classType.meta.add(":headerInclude", [macro "godot_cpp/classes/gd_script.hpp"], classType.pos);
			classType.meta.add(":headerInclude", [macro "godot_cpp/variant/variant.hpp"], classType.pos);
			classType.meta.add(":headerInclude", [macro "godot_cpp/variant/string.hpp"], classType.pos);
			classType.meta.add(":headerInclude", [macro "godot_cpp/variant/utility_functions.hpp"], classType.pos);
			classType.meta.add(":headerInclude", [macro "fstream", macro true], classType.pos);
			classType.meta.add(":headerClassCode", [macro '\tvoid _setupSelf();\n'], classType.pos);

			final pathFileName = {
				final p = new Path(path);
				p.file + "." + p.ext;
			}

			classType.meta.add(":cppFileCode", [macro $v{'void ${{
				final ns = classType.pack.join("::");
				ns.length > 0 ? (ns + "::") : "";
			}}${classType.name}::_setupSelf() {
	static bool script_setup = false;
	static godot::GDScript script;
	if(!script_setup) {
		script_setup = true;
		std::fstream file("$path", std::ios::in);
		std::string line;
		godot::String result;
		while (std::getline(file, line)) {
			result += line.c_str();
			result += "\\n";
		}
		file.close();

		script.set_name("$pathFileName");
		script.set_path("$path");
		script.set_source_code(result);
		script.reload();
	}
	self = script.new_(this);
	// self.call("wrap_new");
	// add_child(static_cast<godot::Node*>(self.operator Object*()));
}\n'}], classType.pos);

			classType.meta.add(":headerClassCode", [macro "\tgodot::Variant self;\n"], classType.pos);
		}

		return null;
	}
}

#end
