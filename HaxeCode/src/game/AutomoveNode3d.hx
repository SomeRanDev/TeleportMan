package game;

import godot.*;

class AutomoveNode3d extends Node3D {
	@:export public var speed = 0.0;
	@:export public var direction: Vector3;

	public override function _process(delta: Float) {
		if(speed > 0.0) {
			this.position += direction * speed * delta;
		}
	}
}
