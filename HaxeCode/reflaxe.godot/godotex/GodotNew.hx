package godotex;

import haxe.macro.Expr;

class GodotNew {
	#if cxx

	@:include("godot_cpp/core/memory.hpp")
	@:nativeFunctionCode("memnew({type0})")
	public static extern function _new<T>(cls: Class<T>): cxx.Ptr<T>;

	#elseif gdscript

	public static extern inline function _new<T>(cls: Class<T>): cxx.Ptr<T> {
		return untyped __gdscript__("{0}.new()", cls);
	}

	#end
}
