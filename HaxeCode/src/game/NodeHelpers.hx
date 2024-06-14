package game;

import godot.*;

import game.Game;

class NodeHelpers {
	public static function get_node_3d(self: Node, path: String): Node3D {
		return cast self.get_node(path);
	}

	public static function get_game_node(self: Node): Game {
		return cast self.get_tree().get_current_scene();
	}

	public static function get_scene_node(self: Node, path: String): Node {
		return get_persistent_node(self, "CurrentLevel/" + path);
	}
	
	public static function get_persistent_node(self: Node, path: String): Node {
		return self.get_tree().get_current_scene().get_node(path);
	}
}
