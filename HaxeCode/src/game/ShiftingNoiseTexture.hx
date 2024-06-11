package game;

import godot.*;

class ShiftingNoiseTexture extends MeshInstance3D {
	@:export var speed: Vector3;

	var noiseTexture: NoiseTexture2D;
	var noise: FastNoiseLite;
	var offset: Vector3;

	public override function _ready() {
		final mat: StandardMaterial3D = cast get_surface_override_material(0);
		noiseTexture = cast mat.albedo_texture;
		noise = cast noiseTexture.get_noise();

		offset = new Vector3(0, 0, 0);
	}

	public override function _process(delta: Float) {
		offset += speed * delta;
		noise.set_offset(offset);
	}
}
