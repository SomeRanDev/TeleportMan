package comptime.godot;

macro function getNode(path: ExprOf<String>, typeName: haxe.macro.Expr) {
	return macro get_node(new godot.NodePath($path)).StaticCast($typeName);
}

macro function asVariant(e: haxe.macro.Expr) {
	return macro new GodotVariant($e);
}
