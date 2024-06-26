package game;

import game.Level;

import godot.*;

using game.NodeHelpers;
using game.MacroHelpers;

class Game extends Node3D {
	@:export var firstLevelName: String;

	var currentLevel: Level;

	public override function _ready() {
		final firstLevel: PackedScene = cast ResourceLoader.load("res://Levels/" + firstLevelName + ".tscn");
		currentLevel = cast firstLevel.instantiate();
		currentLevel.name = "CurrentLevel";
		add_child(currentLevel);

		this.get_node_3d("Player").as(Player).start(this.get_scene_node("PlayerStart").as(Node3D).global_position);

		currentLevel.onPlayerOccupy();
	}

	public function goToNextLevel() {
		currentLevel.position.x = -400;
		currentLevel.name = "OldLevel";

		final next = currentLevel.getNextLevel();
		currentLevel.queue_free();
		currentLevel = null;

		if(next != null) {
			next.position.x = 0;
			next.name = "CurrentLevel";

			final player: Player = cast get_node("Player");
			player.global_position = next.get_node_3d("PlayerStart/ExitPortalPoint").global_position;
			player.setTargetFallingSpot(next.get_node_3d("PlayerStart").global_position);
			next.onPlayerOccupy();
			currentLevel = next;
		}
	}
}
