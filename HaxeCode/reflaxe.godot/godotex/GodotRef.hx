package godotex;

import cxx.Ptr;

#if cxx

@:cxxStd
@:arrowAccess
@:overrideMemoryManagement
@:valueType
@:forward
@:nativeTypeCode("godot::Ref<{type0}>")
@:include("godot_cpp/classes/ref.hpp")
extern abstract GodotRef<T>(T) {
	@:nativeFunctionCode("{this}.ptr()")
	public extern function asPtr(): Ptr<T>;

	@:nativeFunctionCode("{this}.is_valid()")
	public extern function isValid(): Bool;

	@:nativeFunctionCode("{this}.is_null()")
	public extern function isNull(): Bool;

	@:nativeFunctionCode("static_cast<godot::Ref<{type0}>>({this})")
	public extern function castTo<U>(): GodotRef<U>;

	@:from
	//@:nativeFunctionCode("{arg0}")
	overload extern inline static function fromSubType<T, U: T>(other: GodotRef<U>): GodotRef<T> {
		return cast other;
	}

	// @:from
	// //@:nativeFunctionCode("{arg0}")
	// overload extern inline static function fromSubType<T, U: T>(other: Null<GodotRef<U>>): GodotRef<T> {
	// 	return cast other;
	// }
}

#else

@:using(GodotRef.Helpers)
typedef GodotRef<T> = T;

extern class Helpers {
	public static extern inline function asPtr<T>(self: GodotRef<T>): Ptr<T> {
		return cast self;
	}

	public static extern inline function isValid<T>(self: GodotRef<T>): Bool {
		return self != null;
	}

	public static extern inline function isNull<T>(self: GodotRef<T>): Bool {
		return self == null;
	}

	public static extern inline function castTo<T, U>(self: GodotRef<T>): GodotRef<U> {
		return cast self;
	}

	@:from
	public static extern inline function fromSubType<T, U: T>(other: GodotRef<U>): GodotRef<T> {
		return cast other;
	}
}

#end
