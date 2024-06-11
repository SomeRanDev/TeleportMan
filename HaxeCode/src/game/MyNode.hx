package game;

import godot.Vector3;

@:godot(cpp)
class MyNode extends godot.Node3D {
	public override function _ready() {
		trace("in ready...");
	}

	public override function _process(delta: Float) {
		this.set_rotation_degrees(new Vector3(this.get_rotation_degrees().x + delta * 3.0, 0.0, 0.0));
	}
}
