package comptime.godot;

#if macro
import haxe.macro.Expr;
#end

extern class GodotPtr {
	#if cxx
	@:native("godot::String({arg0})")
	@:include("godot_cpp/variant/string.hpp")
	public static function toString<T>(p: cxx.Ptr<T>): String;
	#else
	public static extern inline function toString<T>(p: cxx.Ptr<T>): String {
		return Std.string(p);
	}
	#end
	
	#if cxx
	@:nativeFunctionCode("static_cast<{type1}>({arg0})")
	public static function AutoStaticCast<T, U>(input: cxx.Ptr<T>): U;
	#else
	public static extern inline function StaticCast<T, U>(input: cxx.Ptr<T>): cxx.Ptr<U> {
		return cast input;
	}

	public static extern inline function AutoStaticCast<T, U>(input: cxx.Ptr<T>): cxx.Ptr<U> {
		return cast input;
	}
	#end
}
