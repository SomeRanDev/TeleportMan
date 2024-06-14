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

		this.get_node_3d("Player").global_position = this.get_scene_node("PlayerStart").as(Node3D).global_position;

		currentLevel.onPlayerOccupy();
	}

	public function goToNextLevel() {
		currentLevel.position.x = -400;

		final next = currentLevel.getNextLevel();
		if(next != null) {
			next.position.x = 0;
			this.get_node_3d("Player").global_position = next.get_node_3d("ExitPortalPoint").global_position;
			next.onPlayerOccupy();
		}

		currentLevel.queue_free();
	}
}
