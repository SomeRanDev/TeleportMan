package godotex;

import haxe.macro.Expr;

using reflaxe.helpers.ExprHelper;

class GodotCallable {
	public static macro function makeCallable(ptrExpr: Expr/*, className: ExprOf<String>*/, methodName: ExprOf<String>) {
		#if cxx
		//final methodPtr = '&${className.getConstString()}::${methodName.getConstString()}';
		//final callableCpp = 'callable_mp({0}, $methodPtr)';
		final callableCpp = 'godot::Callable({0}, "${methodName.getConstString()}")';
		return macro {
			//untyped __include__("godot_cpp/variant/callable_method_pointer.hpp");
			untyped __include__("godot_cpp/variant/callable.hpp");
			untyped __cpp__($v{callableCpp}, $ptrExpr);
		}
		#else
		//return macro $ptrExpr.
		return macro new godot.Callable($ptrExpr, $methodName);
		
		//macro untyped __gdscript__($v{methodName.getConstString()});//new godot.Callable($ptrExpr, $methodName);
		#end
	}
}
