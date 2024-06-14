package game;

import godot.*;

using game.MacroHelpers;

class UnaliveBox extends Area3D {
	public override function _ready() {
		this.connect("body_entered", new Callable(this, "on_body_entered"));
	}

	public function on_body_entered(body: Node3D) {
		if(body.name == "Player") {
			body.as(Player).perishByLava();
		}
	}
}