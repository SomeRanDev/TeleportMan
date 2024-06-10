package comptime.helpers;

#if (macro || display)

import haxe.macro.Expr;

using haxe.macro.ExprTools;


/**
	Given a `container` expression containing `_` identifiers, replaces all the
	identifiers with the `replacement` expression.
**/
function replaceUnderline(container: Expr, replacement: Expr) {
	var targetIdentifier = "_";

	// If passed a function, use its argument as the replacement identifier.
	container = switch(container.expr) {
		case EFunction(_, funcData) if(funcData.args.length == 1): {
			targetIdentifier = funcData.args[0].name;
			funcData.expr.map(function(e) {
				return switch(e.expr) {
					case EReturn(e2): e2;
					case _: e;
				}
			});
		}
		case _: container;
	}

	function m(e: Expr): Expr {
		return switch(e.expr) {
			case EConst(CIdent(_ == targetIdentifier => true)): replacement;
			case _: e.map(m);
		}
	}
	return macro @:mergeBlock ${m(container)};
}

#end
