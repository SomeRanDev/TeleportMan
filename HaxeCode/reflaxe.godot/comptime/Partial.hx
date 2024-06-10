/**
	Class partials implementation loosely based on `haxe-partials`.

	https://github.com/hamaluik/haxe-partials
	https://github.com/hamaluik/haxe-partials/blob/master/LICENSE
**/

package comptime;

#if macro

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;

using StringTools;

using reflaxe.helpers.ArrayHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.NullableMetaAccessHelper;

@:persistent var mergedFields: Map<String, Array<Field>> = [];

/**
	Call on class with fields to be merged into main class.
**/
function gather() {
	final m = Context.getLocalModule();
	mergedFields.set(m, Context.getBuildFields());
	Compiler.exclude(m);
	return [];
}

/**
	Call on main class.

	The main class must have `@:partial(...)` with list of partial labels as identifiers.

	This is called automatically if `@:godot` metadata is on the class.
**/
function make(inputFields: Null<Array<Field>> = null): Array<Field> {
	final fields = inputFields ?? Context.getBuildFields();
	final cls = Context.getLocalClass().get();

	if(cls.hasMeta("-handled-partial")) {
		return fields;
	}

	cls.meta.add("-handled-partial", [], Context.currentPos());

	if(!cls.hasMeta(":partial")) {
		throw "Missing @:partial";
	}

	final exprs = cls.meta.extractExpressionsFromFirstMeta(":partial");
	for(expr in exprs) {
		var moduleName = switch(expr.expr) {
			case EConst(CIdent(partialLabel)): {
				// Look for `path.to.Class_PARTIALLABEL`
				final result = cls.pack.joinAppend(".") + cls.name + "_" + partialLabel;
				try {
					Context.getModule(result);
					result;
				} catch(_) {
					continue;
				}
			}
			case _: continue;
		}

		final moduleFields: Null<Array<Field>> = mergedFields.get(moduleName);
		if(moduleFields != null) {
			for(field in moduleFields) {
				//field.pos = Context.currentPos();
				fields.push(field);
			}
		}
	}

	return fields;
}

#end
