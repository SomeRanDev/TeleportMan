package comptime.godot;

import haxe.macro.Expr;
import haxe.macro.ExprTools;

using reflaxe.helpers.ExprHelper;

macro function StaticCast(input: Expr, className: Expr): Expr {
	final typePath = className.getIdentifierDotPath();

	if(typePath == null) {
		throw "The argument should be an identifier or dot-path.";
	}

	final ct = haxe.macro.MacroStringTools.toComplex(typePath);
	return StaticCastImpl(input, ct);
}

#if macro

function StaticCastImpl(input: Expr, ct: ComplexType): Expr {
	#if cxx
	return macro ($input.AutoStaticCast() : Ptr<$ct>);
	#elseif gdscript
	return macro cast($input, Ptr<$ct>);
	#end
}

#end
