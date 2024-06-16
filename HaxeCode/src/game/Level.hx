package game;

import godot.*;

using game.MacroHelpers;
using game.NodeHelpers;

class Level extends Node3D {
	@:export var levelId: Int = 0;
	@:export var nextLevelName: String;

	var playerSpellCount: Int;
	var nextLevelInst: Level;

	public function getNextLevel(): Level { 
		return nextLevelInst;
	}

	public override function _ready() {
		//this.get_node_3d("DirectionalLight3D").visible = false;
	}

	public override function _process(delta: Float) {
		if(nextLevelInst != null) {
			final portalCamera: Camera3D = cast nextLevelInst.get_node("BasePortalViewport/PortalCamera");
			final exportPortalPoint: Node3D = cast nextLevelInst.get_node("PlayerStart/ExitPortalPoint");
			final transitionHole: Node3D = cast this.get_node("../TransitionHole");
			final player: Player = cast this.get_persistent_node("Player");

			final relative_transform = transitionHole.global_transform.affine_inverse() * player.getCamera().global_transform;
			portalCamera.set_global_transform(exportPortalPoint.global_transform * relative_transform);
		}
	}

	public function onPlayerOccupy() {
		if(nextLevelName.length == 0) return;

		final nextLevel: PackedScene = cast ResourceLoader.load("res://Levels/" + nextLevelName + ".tscn");
		nextLevelInst = cast nextLevel.instantiate();
		nextLevelInst.position.x = 400.0;
		nextLevelInst.name = nextLevelName;
		get_tree().get_current_scene().add_child(nextLevelInst);

		get_node("BasePortalViewport").queue_free();
		get_node("PlayerStart/ExitPortalPoint").queue_free();

		final hole: MeshInstance3D = cast get_node("../TransitionHole");
		hole.global_transform = cast(get_node("TransitionHole"), Node3D).global_transform;

		final shader = new ShaderMaterial();
		shader.set_shader(cast ResourceLoader.load("res://Code/Shaders/TransitionHole.gdshader"));
		shader.set_shader_parameter("_view_texture", cast(nextLevelInst.get_node("BasePortalViewport"), SubViewport).get_texture());
		hole.set_surface_override_material(0, shader);

		final player: Player = cast this.get_persistent_node("Player");
		playerSpellCount = player.getSpellCount();

		//this.get_node_3d("DirectionalLight3D").visible = true;
	}

	public function resetLevel() {
		final player = this.get_persistent_node("Player").as(Player);
		player.setSpellCount(playerSpellCount);
		if(levelId == 1) {
			player.obtainGoodJump(false);
			respawnSpell("JumpSpell");
		} else if(levelId == 2) {
			final monkeyHead = this.get_scene_node("MonkeyHead").as(AutomoveNode3d);
			monkeyHead.speed = 0.0;
			monkeyHead.position = new Vector3(-21.853, -18.703, 6.433);

			respawnSpell("MonkeyHeadSpell");
		} else if(levelId == 3) {
			this.get_scene_node("Geometry/JunkHolder").as(Node3D).position.y = -3.0;

			player.obtainTeleport(false);

			respawnSpell("TeleportSpell");
			respawnSpell("SummonJunkSpell");
		} else if(levelId == 4) {
			player.setHasDoubleJump(false);

			respawnSpell("DoubleJumpSpell");
			respawnSpell("FakeSpell");
		} else if(levelId == 6) {
			final lava = this.get_scene_node("Lava").as(Lava);
			lava.initLavaLevel();

			respawnSpell("LowerLavaSpell");
		}
	}

	function respawnSpell(name: String) {
		final s = this.get_node_3d(name);
		if(s.position.y > 9000) {
			s.position.y -= 9999.0;
		}
	}
}
