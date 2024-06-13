package game;

import godot.*;

using StringTools;

class ScreenshotTake extends MeshInstance3D {
	// var time: Float = 0;
	// var frame: Int = 0;

	final length = 36;

	public override function _ready() {
	}

	public override function _process(delta: Float) {
		// time += delta * 75.0;
		// while(time >= 2.0) {
		// 	incrementFrame();
		// 	time -= 1.0;
		// }
		// if(time >= 1.0) {
		// 	time = 0.0;
		// 	incrementFrame();
		// 	mesh = cast ResourceLoader.load(
		// 		'res://VisualAssets/Meshes/ScreenSaveAnimation/ScreenSave${Std.string(frame).lpad("0", 3)}.obj'
		// 	);
		// }
	}

	public function setRatio(ratio: Float) {
		final frame = Math.floor(length * ratio) + 1;
		mesh = cast ResourceLoader.load(
			'res://VisualAssets/Meshes/ScreenSaveAnimation/ScreenSave${Std.string(frame).lpad("0", 3)}.obj'
		);
	}

	// function incrementFrame() {
	// 	if(frame < 36) {
	// 		frame++;
	// 	}
	// }

	// public function reset() {
	// 	time = 0;
	// 	frame = 0;
	// }
}
