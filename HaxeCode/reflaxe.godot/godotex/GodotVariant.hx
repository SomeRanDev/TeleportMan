package godotex;

import cxx.Ptr;

#if cxx

@:forward
@:valueType
extern abstract GodotVariant(IGodotVariant) from IGodotVariant to IGodotVariant {
	public extern inline function new(v: cxx.Auto)
		this = new IGodotVariant(v);

	// @:from
	// public extern inline static function fromBool(b: Bool): GodotVariant
	// 	return new GodotVariant(new IGodotVariant(b));

	// @:from
	// public extern inline static function fromInt(i: Int): GodotVariant
	// 	return new GodotVariant(IGodotVariant.from(i));

	// @:from
	// public extern inline static function fromString(s: String): GodotVariant
	// 	return new GodotVariant(IGodotVariant.from(s));

	// @:from
	// public extern inline static function fromNullableObject<T>(s: Null<T>): GodotVariant {
	// 	if(s == null) return new IGodotVariant();
	// 	final temp: T = s;
	// 	return new GodotVariant(temp);
	// }

	@:from
	public extern inline static function fromObject<T>(s: T): GodotVariant
		return new GodotVariant(s);

	@:to public extern inline function toRID(): godot.RID return this.toRID();
	@:to public extern inline function toInt(): Int return this.toInt();
	@:to public extern inline function toFloat(): Float return this.toFloat();
	@:to public extern inline function toVector2(): godot.Vector2 return this.toVector2();
	@:to public extern inline function toVector3(): godot.Vector3 return this.toVector3();
	@:to public extern inline function toRect2(): godot.Rect2 return this.toRect2();
	@:to public extern inline function toObject(): Ptr<godot.Object> return this.toObject();
}

@:native("godot::Variant")
@:include("godot_cpp/variant/variant.hpp")
@:valueType
extern class IGodotVariant {
	public function new(anything: cxx.Untyped.UntypedNotNull = null);

	// @:constructor
	// public overload static function from(b: Bool): GodotVariant;

	// @:constructor
	// public overload static function from(b: Int): GodotVariant;

	// @:constructor
	// public overload static function from(b: Float): GodotVariant;

	// @:constructor
	// public overload static function from(b: String): GodotVariant;

	// @:constructor
	// public overload static function from<T>(b: T): GodotVariant;

	@:nativeName("operator godot::String")
	public function toString(): String;

	#if cxx @:nativeName("operator godot::RID") #end
	public function toRID(): godot.RID;

	#if cxx @:nativeName("operator int32_t") #end
	public function toInt(): Int;

	#if cxx @:nativeName("operator double") #end
	public function toFloat(): Int;

	#if cxx @:nativeName("operator godot::Vector2") #end
	public function toVector2(): godot.Vector2;

	#if cxx @:nativeName("operator godot::Vector3") #end
	public function toVector3(): godot.Vector3;

	#if cxx @:nativeName("operator godot::Rect2") #end
	public function toRect2(): godot.Rect2;

	#if cxx @:nativeName("operator godot::Object*") #end
	public function toObject(): Ptr<godot.Object>;
}

#else

extern abstract GodotVariant(Dynamic) from Dynamic to Dynamic {
	public extern inline function new(v: Dynamic) this = v;
	@:from public extern inline static function fromBool(b: Bool): GodotVariant return new GodotVariant(b);
	@:from public extern inline static function fromInt(i: Int): GodotVariant return new GodotVariant(i);
	@:from public extern inline static function fromString(s: String): GodotVariant return new GodotVariant(s);
	@:from public extern inline static function fromObject<T>(s: T): GodotVariant return new GodotVariant(s);

	public extern inline function toRID(): godot.RID { return cast this; }
	public extern inline function toInt(): Int { return cast this; }
	public extern inline function toFloat(): Int { return cast this; }
	public extern inline function toVector2(): godot.Vector2 { return cast this; }
	public extern inline function toVector3(): godot.Vector3 { return cast this; }
	public extern inline function toRect2(): godot.Rect2 { return cast this; }
	public extern inline function toObject(): Ptr<godot.Object> { return cast this; }
}

#end

/*operator bool() const;
	operator int64_t() const;
	operator int32_t() const;
	operator uint64_t() const;
	operator uint32_t() const;
	operator double() const;
	operator float() const;
	operator String() const;
	operator Vector2() const;
	operator Vector2i() const;
	operator Rect2() const;
	operator Rect2i() const;
	operator Vector3() const;
	operator Vector3i() const;
	operator Transform2D() const;
	operator Vector4() const;
	operator Vector4i() const;
	operator Plane() const;
	operator Quaternion() const;
	operator godot::AABB() const;
	operator Basis() const;
	operator Transform3D() const;
	operator Projection() const;
	operator Color() const;
	operator StringName() const;
	operator NodePath() const;
	operator godot::RID() const;
	operator ObjectID() const;
	operator Object *() const;
	operator Callable() const;
	operator Signal() const;
	operator Dictionary() const;
	operator Array() const;
	operator PackedByteArray() const;
	operator PackedInt32Array() const;
	operator PackedInt64Array() const;
	operator PackedFloat32Array() const;
	operator PackedFloat64Array() const;
	operator PackedStringArray() const;
	operator PackedVector2Array() const;
	operator PackedVector3Array() const;
	operator PackedColorArray() const;*/
