package comptime;

import reflaxe.helpers.Context;
import haxe.macro.Expr;

using reflaxe.helpers.ExprHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.NullableMetaAccessHelper;

typedef AssignmentExprs = Array<{
	field: Field,
	ct: ComplexType,
	?path: Null<String>,
	?expr: Null<Expr>,
	pos: Position
}>;

/**
	Finds all `@:getNode` and `@:onReady` fields and initializes them in the _ready function.

	Also handles `@:partial` if not already handled.
**/
function process(): Array<Field> {
	var fields = Context.getBuildFields();
	final cls = Context.getLocalClass().get();

	// Handle partials before anything else...
	if(cls.hasMeta(":partial") && !cls.hasMeta("-handled-partial")) {
		fields = comptime.Partial.make(fields);
	}

	// Find all "_ready" fields.
	var _readyFields: AssignmentExprs = [];
	var _readyFunction = null;

	// Find all "reset" fields.
	var resetFields: AssignmentExprs = [];
	var resetFunction = null;

	for(f in fields) {
		switch(f.kind) {
			case FFun(fun) if(f.name == "_ready"): {
				_readyFunction = fun;
			}
			case FFun(fun) if(f.name == "reset"): {
				resetFunction = fun;
			}
			case FVar(ct, e) if(f.meta != null): {
				final metaMap: Map<String, MetadataEntry> = [];
				for(m in f.meta) {
					metaMap.set(m.name, m);
				}

				for(name => m in metaMap) {
					final hasArgs = m.params.length > 0;
					if(hasArgs && m.name == ":getNode") {
						_readyFields.push({ field: f, ct: ct, path: m.params[0].getConstString(), pos: m.pos});
					} else if(hasArgs && m.name == ":onReady") {
						_readyFields.push({ field: f, ct: ct, expr: m.params[0], pos: m.pos});
					} else if(m.name == ":reset") {
						resetFields.push({
							field: f,
							ct: ct,
							expr: {
								if(e != null) {
									e;
								} else if(m.params.length > 0) {
									m.params[0];
								} else {
									final onReadyMeta = metaMap.get(":onReady");
									if(onReadyMeta != null && onReadyMeta.params.length > 0) {
										onReadyMeta.params[0];
									} else {
										throw "Default expression required for @:reset.";
									}
								}
							},
							pos: m.pos
						});
					} else if(m.name == ":autoProp") {
						trace("@:autoProp used on variable that isn't get/set");
					}
				}
			}
			case FProp("get", "set", ct, expr) if(f.meta != null): {
				var autoPropParams = null;
				for(m in f.meta) if(m.name == ":autoProp") {
					autoPropParams = m.params ?? [];
				}

				if(autoPropParams != null) {
					final internalName = "_" + f.name;
					final getName = "get_" + f.name;
					final setName = "set_" + f.name;

					// Add internal field
					fields.push((if(expr != null) {
						macro class { var $internalName: $ct = $expr; }
					} else {
						macro class { var $internalName: $ct; }
					}).fields[0]);

					// Add getter and setter fields
					final newFields = macro class {
						public function $getName() return $i{internalName};
						public function $setName(v) {
							$i{internalName} = v;
							$b{autoPropParams}
							return v;
						}
					}
					for(f in newFields.fields) {
						fields.push(f);
					}

					// Remove expression from property if it exists
					if(expr != null) {
						f.kind = FProp("get", "set", ct, null);
					}
				}
			}
			case _:
		}
	}

	prependAssignmentsToFunction(_readyFunction, _readyFields);
	prependAssignmentsToFunction(resetFunction, resetFields);

	return fields;
}

function prependAssignmentsToFunction(func: Function, assignments: AssignmentExprs) {
	if(func != null) {
		final exprs = [];
		for(fieldData in assignments) {
			if(fieldData.path != null) {
				final ct = fieldData.ct;
				final expr = comptime.godot.GodotPtrMacro.StaticCastImpl(macro get_node($v{fieldData.path}), ct);
				exprs.push(
					@:pos(fieldData.pos)
					macro $i{fieldData.field.name} = $expr
				);
			} else if(fieldData.expr != null) {
				exprs.push(
					@:pos(fieldData.pos)
					macro $i{fieldData.field.name} = ${fieldData.expr}
				);
			}
		}

		final oldExpr = func.expr;

		func.expr = @:pos(func.expr.pos) macro {
			$b{exprs}
			@:mergeBlock $oldExpr;
		};
	} else if(assignments.length > 0) {
		Context.error("_ready function required to use this metadata.", assignments[0].pos);
	}
}
