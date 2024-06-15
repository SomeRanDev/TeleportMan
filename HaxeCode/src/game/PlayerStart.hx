package game;

import godot.*;

using game.NodeHelpers;

class PlayerStart extends Node3D {
	public override function _ready() {
		this.get_node_3d("ExitPortalPoint").global_position.y = 90;
	}
}
