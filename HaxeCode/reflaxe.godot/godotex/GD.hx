package godotex;

import haxe.macro.Context;
import haxe.macro.Expr;

using reflaxe.helpers.ExprHelper;

class GD {
	public static macro function dontProcessInEditor(whenNotEditor: Null<Expr> = null): Expr {
		if(whenNotEditor == null) {
			whenNotEditor = macro @:mergeBlock {};
		}

		return macro if(Engine.is_editor_hint()) {
			set_process_mode(PROCESS_MODE_DISABLED);
		} else {
			set_process_mode(PROCESS_MODE_INHERIT);
			$whenNotEditor;
		}
	}

	public static macro function emitSignal(name: ExprOf<String>, exprs: Array<Expr>) {
		final injectIndexes = [];
		for(i in 0...exprs.length) {
			injectIndexes.push('{$i}');
		}
		var code = 'emit_signal("${name.getConstString()}", ${injectIndexes.join(", ")})';
		#if gdscript
		code = "_self." + code;
		#end
		final args = [macro $v{code}].concat(exprs);
		return {
			expr: ECall(macro untyped #if gdscript __gdscript__ #elseif cxx __cpp__ #end, args),
			pos: Context.currentPos()
		};
	}

	public static macro function packedStringArray(exprs: Array<Expr>): Expr {

		final pushBackExprs = exprs.map(e -> macro result.push_back($e));
		return macro {
			final result = new PackedStringArray();
			@:mergeBlock $b{pushBackExprs};
			result;
		}

		// final injectIndexes = [];
		// for(i in 0...exprs.length) {
		// 	injectIndexes.push('{$i}');
		// }
		// final code = #if gdscript 'PackedStringArray(${injectIndexes.join(", ")})' #elseif cxx 'godot::PackedStringArray({${injectIndexes.join(", ")}})' #end;
		// final args = [macro $v{code}].concat(exprs);
		// #if gdscript
		// return {
		// 	expr: ECall(macro untyped __gdscript__, args),
		// 	pos: Context.currentPos()
		// };
		// #elseif cxx
		// final cpp = {
		// 	expr: ECall(macro untyped __cpp__, args),
		// 	pos: Context.currentPos()
		// };
		// //#include <godot_cpp/variant/packed_string_array.hpp>
		// return macro {
		// 	untyped __include__("godot_cpp/variant/packed_string_array.hpp");
		// 	$cpp;
		// }
		// #end
	}
}
