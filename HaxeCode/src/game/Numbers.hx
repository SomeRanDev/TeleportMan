package game;

import godot.Godot;
import godot.Vector3;

extern inline function clamp(self: Float, min: Float, max: Float): Float {
	return if(self < min) min;
	else if(self > max) max;
	else self;
}

extern inline function lerp_angle_vec3(myself: Vector3, other: Vector3, ratio: Float): Vector3 {
	final x = Godot.lerp_angle(myself.x, other.x, ratio);
	final y = Godot.lerp_angle(myself.y, other.y, ratio);
	final z = Godot.lerp_angle(myself.z, other.z, ratio);
	return new Vector3(x, y, z);
}
