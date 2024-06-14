package game;

import godot.*;

using game.NodeHelpers;

class NextLevelTrigger extends Area3D {
	var player: Player;

	public override function _ready() {
		this.connect("body_entered", new Callable(this, "on_body_entered"));
	}

	public override function _process(delta: Float) {
		if(player != null) {
			if(player.getCamera().global_position.y < global_position.y) {
				this.get_game_node().goToNextLevel();
				player = null;
			}
		}
	}

	public function on_body_entered(body: Node3D) {
		if(body.name == "Player") {
			//player = cast body;
			this.get_game_node().goToNextLevel();
			player = null;
		}
	}
}
