package game;

import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.ExprTools;
using reflaxe.helpers.ExprHelper;

class Syntax {
	#if macro
	/**
		Given a `container` expression containing `_` identifiers, replaces all the
		identifiers with the `replacement` expression.
	**/
	static function replaceUnderline(container: Expr, replacement: Expr) {
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

	/**
		A compile-time macro that converts an expression like this:
		```haxe
		[First, Second, ..., Last].repeatExpr( insert_custom_expression_here(_ + 123) );
		```

		into this:
		```haxe
		insert_custom_expression_here(First + 123);
		insert_custom_expression_here(Second + 123);
		...
		insert_custom_expression_here(Last + 123);
		```
	**/
	public static macro function repeatExpr(self: Expr, repeatExpr: Expr) {
		final values = switch(self.unwrapParenthesisMetaAndStoredType().expr) {
			case EArrayDecl(values) if(values.length > 0): values;
			case _: throw Std.string(self.unwrapParenthesisMetaAndStoredType().expr) + " must be array declaration.";
		}

		final expressions = values.map((v) -> replaceUnderline(repeatExpr, v));
		return macro @:mergeBlock $b{expressions};
	}

	/**
		A compile-time macro that converts an expression like this:
		```haxe
		myCppArray().forSized(_.size(), trace(_));
		```

		into this:
		```haxe
		final arr = myCppArray();
		for(i in 0...arr.size()) {
			trace(arr[i]);
		}
		```
	**/
	public static macro function forSized(self: Expr, sizeExpr: Expr, contentExpr: Expr) {
		return macro {
			final temp = $self;
			for(i in 0...${replaceUnderline(sizeExpr, macro temp)})
				${replaceUnderline(contentExpr, macro temp[i])}
		}
	}

	/**
		A compile-time macro that converts an expression like this:
		```haxe
		myExpr().ifThen(_.getCondition() == 123, _.doThing());
		```

		into this:
		```haxe
		final temp = myExpr();
		if(temp.getCondition() == 123) {
			temp.doThing();
		}
		```
	**/
	public static macro function ifThen(self: Expr, condition: Expr, content: Expr) {
		return macro {
			final temp = $self;
			if(${replaceUnderline(condition, macro temp)}) {
				${replaceUnderline(content, macro temp)};
			}
		}
	}
}
