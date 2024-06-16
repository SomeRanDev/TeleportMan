package game;

import godot.*;

using StringTools;

import game.Player;

using game.MacroHelpers;
using game.NodeHelpers;

class ScreenshotTake extends MeshInstance3D {
	var mode = 0;

	var time: Float = 0;
	var frame: Int = 0;

	final length = 36;

	public override function _ready() {
		visible = false;
	}

	public override function _process(delta: Float) {
		if(mode == 1) {
			if(frame < 0) {
				frame = 0;
				return;
			}
			visible = true;
			time += delta * 100.0;
			while(time >= 2.0) {
				incrementFrame();
				time -= 1.0;
			}
			if(time >= 1.0) {
				time = 0.0;
				incrementFrame();
				mesh = cast ResourceLoader.load(
					'res://VisualAssets/Meshes/ScreenSaveAnimation/ScreenSave${Std.string(frame).lpad("0", 3)}.obj'
				);
			}
			if(frame >= 36) {
				time = 0;
				frame = 0;
				mode = 2;
			}
		} else if(mode == 2) {
			time += delta * 5.0;
			if(time >= 1.0) {
				time = 1.0;
			}

			position = Godot.lerp(new Vector3(0, 0, -0.84), new Vector3(5.31, -2.905, -1.0), time);

			if(time >= 1.0) {
				this.get_persistent_node("Player").as(Player).finishTeleportStart();
				mode = 0;
			}
		} else if(mode == 3) {
			time += delta * 5.0;
			if(time >= 1.0) {
				time = 1.0;
			}

			position = Godot.lerp(new Vector3(5.31, -2.905, -1.0), new Vector3(0, 0, 3.3), time);

			if(time >= 1.0) {
				this.get_persistent_node("Player").as(Player).finishTeleport();
				visible = false;
				mode = 0;
			}
		}
	}

	public function setRatio(ratio: Float) {
		final frame = Math.floor(length * ratio) + 1;
		mesh = cast ResourceLoader.load(
			'res://VisualAssets/Meshes/ScreenSaveAnimation/ScreenSave${Std.string(frame).lpad("0", 3)}.obj'
		);
	}

	function incrementFrame() {
		if(frame < 36) {
			frame++;
			if(frame == 2) {
				visible = true;
			}
			if(frame == 16) {
				this.get_persistent_node("Player").as(Player).stopRecording();
			}
			return false;
		}
		return true;
	}

	public function reset() {
		time = 0;
		frame = 0;
		mode = 1;
		visible = false;
		position = new Vector3(0, 0, -0.84);
		mesh = cast ResourceLoader.load(
			'res://VisualAssets/Meshes/ScreenSaveAnimation/ScreenSave001.obj'
		);
	}

	public function enter() {
		time = 0;
		frame = 0;
		mode = 3;
		visible = true;
		position = new Vector3(0, 0, -0.84);
	}

	public function onUnalive() {
		time = 0;
		frame = 0;
		mode = 0;
		visible = false;
		position = new Vector3(0, 0, -0.84);
	}
}
