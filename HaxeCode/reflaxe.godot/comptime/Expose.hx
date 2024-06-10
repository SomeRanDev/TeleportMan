/**
	Adds the necessary stuff to make a Godot Object/Node from Haxe function.

	What occurs depends on whether we're compiling for C++ or GDScript.

	[[Reflaxe/C++]]
	1) Adds `@:internalContent("GDCLASS(...)")` meta to the class.
	2) Finds all public functions (+ `@:forceBind` fields) and add them to `static function _bind_methods()`.

	[[Reflaxe/GDScript]]
	(Nothing yet...)
**/

package comptime;

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;

using reflaxe.helpers.ExprHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.NullableMetaAccessHelper;

#if macro

function gdPackage(packageName: String): Void {
	Compiler.addGlobalMetadata(packageName, "@:build(comptime.Expose.setup())");
}

function setup() {
	final clsRef = Context.getLocalClass();
	if(clsRef == null) {
		return null;
	}

	final cls = clsRef.get();

	final extendsFromGodotObject = {
		var baseClass = cls;
		while(baseClass.superClass != null) {
			baseClass = baseClass.superClass.t.get();
		}

		switch(baseClass) {
			case { name: "Object", pack: ["godot"] }: true;
			case _: false;
		}
	}

	final FORCE_CPP = false;

	if(extendsFromGodotObject) {
		if(cls.hasMeta(":godot")) {
			switch(cls.meta.extractExpressionsFromFirstMeta(":godot")) {
				case [macro cpp] | [macro gdscript] if(FORCE_CPP): {
					return expose(false);
				}
				case [macro cpp]: return expose(false);
				case [macro gdscript]: return expose(true);
				case _: {
					final msg = "@:godot can only have one argument that's either \"cpp\" or \"gdscript\".";
					Context.error(msg, cls.meta.getFirstPosition(":godot"));
				}
			}
		}
	}

	return null;
}

/**
	Called on all classes with `@:godot` metadata.
**/
function expose(isGDScriptWrapper: Bool = false): Null<Array<Field>> {
	// Need to figure out output .gd file for both targets if wrapper.
	var wrapperGDFile = null;
	if(isGDScriptWrapper) {
		final basePath = "Z:/Desktop/GithubProjects/TeleportMan/GDScriptOutput/";
		wrapperGDFile = basePath + Context.getLocalClass().get().name + ".gd";
	}

	#if gdscript
	return exposeGDScript(isGDScriptWrapper, wrapperGDFile);
	#elseif cxx
	return exposeCpp(isGDScriptWrapper, wrapperGDFile);
	#else
	return null;
	#end
}

/**
	Handle classes generating for Reflaxe/GDScript.
**/
function exposeGDScript(isGDScriptWrapper: Bool, wrapperGDFile: Null<String>) {
	final cls = Context.getLocalClass().get();

	if(!isGDScriptWrapper) {
		cls.meta.add(":extern", [], Context.currentPos());
		return Metadata.process();
	}

	final pos = Context.currentPos();
	cls.meta.add(":outputFile", [macro $v{wrapperGDFile}], pos);
	cls.meta.add(":dontAddToPlugin", [], pos);
	//cls.meta.add(":native", [macro $v{cls.name + "_GD"}], pos);
	cls.meta.add(":wrapper", [], pos);
	cls.meta.add(":wrapPublicOnly", [], pos);

	var hasConstructor = false;

	final fields = Metadata.process();
	for(f in fields) {
		if(f.name == "new") {
			hasConstructor = true;
		}

		switch(f.kind) {
			case FFun(_): {
				// "wrap_" prefix added to function in GDScript compiler (from @:wrapper).
				continue;
			}
			case _ if(f.access?.contains(APublic) ?? false): {
				f.meta.push({
					name: ":reflaxe_extern",
					params: [],
					pos: Context.currentPos()
				});
			}
			case _: {
				if(f.meta == null) f.meta = [];
				f.meta.push({
					name: ":bypass_wrapper",
					params: [],
					pos: Context.currentPos()
				});
			}
		}
	}

	// Ensure constructor exists.
	if(!hasConstructor) {
		fields.push((macro class {
			public function new() {
				super();
			}
		}).fields[0]);
	}

	return fields;
}

function complexTypeToGodotProp(ct: ComplexType) {
	return switch(ct) {
		case macro : Bool: "BOOL";
		case macro : Int: "INT";
		case macro : Float: "FLOAT";
		case macro : String: "STRING";
		case (macro : Vector2) | (macro : godot.Vector2): "VECTOR2";
		case (macro : Vector3) | (macro : godot.Vector3): "VECTOR3";
		case (macro : Vector4) | (macro : godot.Vector4): "VECTOR4";
		case (macro : Rect2) | (macro : godot.Rect2): "RECT2";
		case (macro : Vector2i) | (macro : godot.Vector2i): "VECTOR2I";
		case (macro : Vector3i) | (macro : godot.Vector3i): "VECTOR3I";
		case (macro : Vector4i) | (macro : godot.Vector4i): "VECTOR4I";
		case (macro : Rect2i) | (macro : godot.Rect2i): "RECT2I";
		case (macro : Color) | (macro : godot.Color): "COLOR";
		case (macro : PackedStringArray) | (macro : godot.PackedStringArray): "PACKED_STRING_ARRAY";
		case TPath({ name: "GodotRef", pack: [], params: [_] }) | TPath({ name: "Ptr", pack: [], params: [_] }): "OBJECT";
		case _: "FLOAT";
	};
}

/**
	Handle classes generating for Reflaxe/C++.
**/
function exposeCpp(isGDScriptWrapper: Bool, wrapperGDFile: Null<String>) {
	final fields = Metadata.process();

	// Make sure extending from Godot class
	final clsRef = Context.getLocalClass();
	final cls = clsRef.get();
	if(cls.superClass == null) {
		Context.error("Godot superclass required", cls.pos);
		return null;
	}

	cls.meta.add(":valueType", [], cls.pos);

	if(isGDScriptWrapper) {
		cls.meta.add(":gdscript", [macro $v{wrapperGDFile}], Context.currentPos());
	}

	// Add to "register" C++ code
	#if cxx
	comptime.RegisterTypesGenerator.exposedTypes.push(clsRef);
	#end

	// Add `GDCLASS` C++ macro
	final className = cls.name;
	cls.meta.add(":headerClassCode", [
		macro $v{'\tGDCLASS(${className}, ${cls.superClass.t.get().name})\n\n'}
	], Context.currentPos());

	var hasConstructor = false;

	final toBeRemovedFields = [];

	final defaultPropertyCategory = "Properties";

	// Find all @:gdCallable fields and generate expressions for "_bind_methods"
	final bindMethodExprs = [];
	final exposedFields: Map<String, Array<Expr>> = [];
	for(field in fields) {
		// Ignore macro functions
		if(field.access != null && field.access.contains(AMacro)) {
			continue;
		}

		// Check for constructor, never bind it.
		if(field.name == "new") {
			hasConstructor = true;
			continue;
		}

		// Prevent "_" names for arguments on GDScript wrapper class.
		if(isGDScriptWrapper) {
			var index = 1;
			switch(field.kind) {
				case FFun(func): {
					func.args = func.args.map(a -> {
						if(a.name == "_") {
							a.name += (index++);
						}
						return a;
					});
				}
				case _:
			}
		}

		final access = field.access ?? [];

		// Never bind `override` field.
		final isOverride = access.contains(AOverride) ?? false;
		if(isOverride) {
			continue;
		}

		// All public functions and properties are bound, but @:forceBind allows
		// for private ones to be bound as well.
		var forceBind = false;
		var dontBind = false;
		var isSignal = false;
		if(field.meta != null) {
			for(m in field.meta) switch(m.name) {
				case ":forceBind": forceBind = true;
				case ":dontBind": dontBind = true;
				case ":signal": isSignal = true;
				case _:
			}
		}

		if(isSignal) {
			switch(field.kind) {
				case FFun(f): {
					final args = f.args.map(a -> 'godot::PropertyInfo(godot::Variant::${complexTypeToGodotProp(a.type)}, "${a.name}")');
					exposedFields.get(defaultPropertyCategory).push(
						macro untyped __cpp__($v{'ADD_SIGNAL(godot::MethodInfo("${field.name}", ${args.join(", ")}))'})
					);
					toBeRemovedFields.push(field);
					continue;
				}
				case _:
			}
		}

		if(dontBind || (!access.contains(APublic) && !forceBind)) {
			// Remove non-bound fields if C++ wrapper.
			if(isGDScriptWrapper) {
				toBeRemovedFields.push(field);
			}
			continue;
		}

		final isStatic = access.contains(AStatic);

		final D_METHOD_args = switch(field.kind) {
			case FFun(f): {
				f.args.map(a -> '"${a.name}"');
			}
			case FProp("get", "set", ct, _): {
				// Find metadata info
				var category = defaultPropertyCategory;
				var enumCases = null;
				var hintCpp = null;
				var hintStringCpp = null;
				for(m in field.meta) {
					switch(m.params) {
						case [{ expr: EConst(CString(s, _)) }]: {
							switch(m.name) {
								case ":category": category = s;
								case ":hintCpp": hintCpp = s;
								case ":hintStringCpp": hintStringCpp = s;
								case ":resource": {
									hintCpp = "godot::PropertyHint::PROPERTY_HINT_RESOURCE_TYPE";
									hintStringCpp = '"$s"';
								}
								case _:
							}
						}
						case args: {
							switch(m.name) {
								case ":enumCases": {
									hintCpp = "godot::PropertyHint::PROPERTY_HINT_ENUM";
									hintStringCpp = args.map(a -> switch(a.expr) {
										case EConst(CIdent(s)): s;
										case _:
									}).join(",");

									// wrap with quotes
									hintStringCpp = '"$hintStringCpp"';
								}
								case _:
							}
						}
					}
				}

				// Add to exposed fields map if it doesn't exist
				if(!exposedFields.exists(category)) {
					exposedFields.set(category, []);
				}

				// Determine VARIANT type from ComplexType.
				final godotTypeCpp = complexTypeToGodotProp(ct);

				final args = [
					'godot::Variant::${godotTypeCpp}',
					'"${field.name}"',
					hintCpp ?? "godot::PropertyHint::PROPERTY_HINT_NONE",
					hintStringCpp ?? '""'
				];
				exposedFields.get(category).push(
					macro untyped __cpp__($v{'ADD_PROPERTY(godot::PropertyInfo(${args.join(", ")}), "set_${field.name}", "get_${field.name}")'})
				);
				continue;
			}
			case _ if(!isGDScriptWrapper): {
				continue; // Ignore variables for pure C++ class (for now).
			}

			//! From this point forward, these are only for GDScript wrapper C++ class.

			case FVar(_, _) | FProp(_, _, _, _) if(access.contains(APublic)): {
				Context.error("All public GDScript variables must be get/set properties.", field.pos);
			}
			case _ : {
				// Private variables are only stored in GDScript
				field.meta.push({
					name: ":reflaxe_extern",
					params: [],
					pos: Context.currentPos()
				});
				continue;
			}
		}

		D_METHOD_args.unshift('"${field.name}"');

		final expr = if(isStatic) {
			final cpp = 'godot::ClassDB::bind_static_method("${cls.name}", godot::D_METHOD(${D_METHOD_args.join(", ")}), &${cls.name}::${field.name})';
			macro untyped __cpp__($v{cpp});
		} else {
			final cpp = 'godot::ClassDB::bind_method(godot::D_METHOD(${D_METHOD_args.join(", ")}), &${cls.name}::${field.name})';
			macro untyped __cpp__($v{cpp});
		}

		bindMethodExprs.push(expr);
	}

	// Ensure constructor exists.
	if(!hasConstructor) {
		fields.push((macro class {
			public function new() {
				super();
			}
		}).fields[0]);
	}

	// Add exposed fields (separated by sections)
	if(exposedFields.exists(defaultPropertyCategory)) {
		bindMethodExprs.push(macro untyped __cpp__($v{'ADD_GROUP("$defaultPropertyCategory", "")'}));
		for(e in exposedFields.get(defaultPropertyCategory))
			bindMethodExprs.push(e);
	}
	for(section => exprs in exposedFields) {
		if(section != defaultPropertyCategory) {
			bindMethodExprs.push(macro untyped __cpp__($v{'ADD_GROUP("$section", "")'}));
			for(e in exprs)
				bindMethodExprs.push(e);
		}
	}

	// If there are methods to be bound, include `ClassDB`
	if(bindMethodExprs.length > 0) {
		bindMethodExprs.unshift(macro untyped __include__("godot_cpp/core/class_db.hpp"));
	}

	// Add `_bind_methods` function
	fields.push((macro class {
		public static function _bind_methods() $b{bindMethodExprs};
	}).fields[0]);

	// Remove unwanted fields
	for(f in toBeRemovedFields) {
		switch(f.kind) {
			case FFun(_func): {
				// Debugging purposes, feel free to remove.
				if(_func.ret == null) {
					checkForReturn(f, _func.expr, _func);
				}

				f.access.push(AExtern);
				f.kind = FFun({
					args: _func.args,
					ret: _func.ret ?? (macro : Void),
					expr: null
				});
			}
			case _:
		}
		
		//fields.remove(f);
	}

	// We done!
	return fields;
}

/**
	Checks if a function we want to make "extern" requires a return type.
**/
function checkForReturn(field: Field, expr: Expr, func: Function) {
	// Used for debugging, feel free to remove?
	var hasReturn = false;
	function findRet(e: haxe.macro.Expr) {
		switch(e.expr) {
			case EReturn(e) if(e != null): {
				hasReturn = true;
				return;
			}
			case _:
		}
		haxe.macro.ExprTools.iter(e, findRet);
	}
	findRet(func.expr);

	if(hasReturn) {
		Context.error("For dumb reasons, private functions that return a value must have an explicit return type.", field.pos);
	}
}

#end
