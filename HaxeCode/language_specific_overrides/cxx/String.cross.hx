package;

@:coreApi
@:cxxStd
@:haxeStd
@:native("godot::String", "String")
@:include("godot_cpp/variant/string.hpp", true)
@:valueType
@:filename("GodotString")
@:godotStd
extern class String {
	@:nativeName("ptr")
	private function c_str(): cxx.ConstCharPtr;

	@:nativeName("length()")
	var length(default, null):Int;

	function new(string:String):Void;
	function toUpperCase():String;
	function toLowerCase():String;
	function charAt(index:Int):String;
	function charCodeAt(index:Int):Null<Int>;
	function indexOf(str:String, ?startIndex:Int):Int;
	function lastIndexOf(str:String, ?startIndex:Int):Int;
	function split(delimiter:String):Array<String>;
	function substr(pos:Int, ?len:Int):String;
	function substring(startIndex:Int, ?endIndex:Int):String;
	function toString():String;
	@:pure static function fromCharCode(code:Int):String;
}
