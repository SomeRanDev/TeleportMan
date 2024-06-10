package cxx;

// @:using(cxx.Ptr.Helpers)
// typedef Ptr<T> = T;

#if !cxx

@:forward
abstract Ptr<T>(T) from T to T {
	public static var Null(get, never): Ptr<Dynamic>;
	public static function get_Null<T>(): Ptr<T> return null;

	public function isNull(): Bool {
		return this == null;
	}

	public extern inline function addrEquals(other: Ptr<T>): Bool {
		return this == other;
	}

	public extern inline function addrNotEquals(other: Ptr<T>): Bool {
		return this != other;
	}

	@:from
    @:nativeFunctionCode("{arg0}")
	static function fromSubType<T, U: T>(other: Ptr<U>): Ptr<T> {
		return cast other;
	}

	@:to
	public function toBool(): Bool {
		return !isNull();
	}
}

#end
