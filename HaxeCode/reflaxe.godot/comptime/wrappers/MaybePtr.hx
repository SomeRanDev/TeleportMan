package comptime.wrappers;

import haxe.macro.Expr;

import comptime.helpers.ExprHelper;

import cxx.Ptr;

@:forwardMemoryManagement
@:using(comptime.wrappers.MaybePtr.MayberPtrHelpers)
@:forward(addrEquals, addrNotEquals)
extern abstract MaybePtr<T>(Ptr<T>) from Ptr<T> from T {
	public inline function trustPtr(/* why: Comment */): Ptr<T> {
		#if !macro
		if(__internalTrust().isNull()) {
			trace("I TRUSTED YOU.");
		}
		#end
		return this;
	}

	@:noCompletion
	public extern inline function __internalTrust(): Ptr<T> return this;
}

class MayberPtrHelpers {
	public static macro function existsAnd<T>(maybePtrExpr: ExprOf<MaybePtr<T>>, otherCondition: Expr) {
		return macro $maybePtrExpr.__internalTrust().toBool() && ${replaceUnderline(otherCondition, macro $maybePtrExpr.__internalTrust())};
	}

	public static macro function ifExists(maybePtrExpr: Expr, block: Expr) {
		return generateIfExpr(maybePtrExpr, block);
	}

	public static macro function ifExistsWithElse(maybePtrExpr: Expr, ifContent: Expr, elseContent: Expr) {
		return generateIfExpr(maybePtrExpr, ifContent, elseContent);
	}

	#if macro
	static function generateIfExpr(maybePtrExpr: Expr, ifContent: Expr, elseContent: Null<Expr> = null) {
		final ifExpr = macro if(!temp.__internalTrust().isNull()) ${replaceUnderline(ifContent, macro temp.__internalTrust())};

		ifExpr.expr = switch(ifExpr.expr) {
			case EIf(econd, eif, null) if(elseContent != null): {
				EIf(econd, eif, elseContent);
			}
			case _: ifExpr.expr;
		}

		return macro {
			final temp = @:privateAccess $maybePtrExpr;
			$ifExpr;
		}
	}
	#end
}
