package game;

import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.ExprTools;
using haxe.macro.MacroStringTools;

class MacroHelpers {
	public static macro function as(expr: Expr, ctExpr: Expr): Expr {
		final ct = ctExpr.toString().toComplex();
		return macro cast($expr, $ct);
	}
}
