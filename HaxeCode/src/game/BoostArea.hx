package game;

import godot.*;

import game.Player;

using game.MacroHelpers;

class BoostArea extends Area3D {
	var player: Player;

	public override function _ready() {
		this.connect("body_entered", new Callable(this, "on_body_entered"));
		this.connect("body_exited", new Callable(this, "on_body_exited"));
	}

	public override function _process(delta: Float) {
		if(player != null && player.is_on_floor()) {
			var velocity = new Vector2(0.0, 25.0);
			trace(velocity);
			trace(velocity.rotated(-global_rotation.y));
			player.forceGroundVelocity(velocity.rotated(-global_rotation.y));
		}
	}

	public function on_body_entered(body: Node3D) {
		if(body.name == "Player") {
			player = body.as(Player);
		}
	}

	public function on_body_exited(body: Node3D) {
		if(body.name == "Player") {
			player = null;
		}
	}
}
