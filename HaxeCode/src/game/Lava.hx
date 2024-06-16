package game;

import godot.*;

import game.ShiftingNoiseTexture;

using game.MacroHelpers;
using game.NodeHelpers;

class Lava extends ShiftingNoiseTexture {
	@:export public var initialLavalLevel = -35.0;

	var currentLavaLevel = -35.0;
	var targetLavaLevel = -35.0;

	public override function _ready() {
		super._ready();

		initLavaLevel();
	}

	public function setTargetLavaLevel(level: Float) {
		targetLavaLevel = level;
	}

	public function initLavaLevel() {
		setTargetLavaLevel(initialLavalLevel);
		setCurrentLavaLevel(initialLavalLevel);
	}

	public override function _process(delta: Float) {
		super._process(delta);

		if(currentLavaLevel != targetLavaLevel) {
			setCurrentLavaLevel(Godot.move_toward(currentLavaLevel, targetLavaLevel, delta * 4.0));
		}
	}

	function setCurrentLavaLevel(level: Float) {
		currentLavaLevel = level;

		position.y = level;

		final meshInstance = get_parent().get_node("LevelWalls").as(MeshInstance3D);
		final shaderMaterial = meshInstance.get_surface_override_material(0).as(ShaderMaterial);
		shaderMaterial.set_shader_parameter("lava_level", level);
	}
}
