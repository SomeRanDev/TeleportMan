package myds;

#if cxx

// @:cxxStd
// @:cppStd
@:nativeTypeCode("std::vector<{type0}>")
@:include("vector", true)
extern class MyVector<T>  {
	public function new();

	public var length(get, never): Int;

	@:nativeName("size")
	function get_length(): Int;

	@:nativeName("push_back")
	public function push(obj: T): Void;

	public function at(pos: Int): T;

	// public function at(pos: cxx.num.SizeT): T;
	// public function front(): T;
	// public function back(): T;
	// public function data(): cxx.CArray<T>;

	// public function empty(): Bool;
	// public function size(): cxx.num.SizeT;
	// public function maxSize(): cxx.num.SizeT;

	// public function fill(value: T): Void;
}

#elseif gdscript

abstract MyVector<T>(Array<T>) from Array<T> to Array<T> {
	public inline function new() {
		this = [];
	}

	public var length(get, never): Int;
	function get_length(): Int return this.length;

	public inline function push(obj: T): Void {
		this.push(obj);
	}

	public function at(pos: Int): T {
		return this[pos];
	}
}

#end
