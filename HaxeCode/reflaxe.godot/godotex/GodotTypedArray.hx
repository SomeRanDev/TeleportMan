package godotex;

#if gdscript

//typedef GodotTypedArray<T> = Array<T>;

@:forward
abstract GodotTypedArray<T>(Array<T>) from Array<T> to Array<T> {
	public extern inline function size(): Int {
		return untyped __gdscript__("{0}.size()", this);
	}

	@:arrayAccess
	public extern inline function arrayAccessGet(k: Int): GodotVariant return this[k];

	@:arrayAccess
	public extern inline function arrayAccessSet(k: Int, v: GodotVariant): GodotVariant return this[k] = v;
}

#elseif cxx

@:forward
abstract GodotTypedArray<T>(godot.GodotArray) from godot.GodotArray to godot.GodotArray {
	@:arrayAccess
	public extern inline function arrayAccessGet(key: Int): GodotVariant {
		return untyped __cpp__("({0}[{1}])", this, key);
	}

	@:arrayAccess
	public extern inline function arrayAccessSet(k: Int, v: GodotVariant): GodotVariant {
		untyped __cpp__("({0}[{1}] = {2})", this, key, value);
		return v;
	}
}

#end

