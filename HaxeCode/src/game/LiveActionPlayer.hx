package game;

import godot.*;

using StringTools;

class LiveActionPlayerAnimation {
	public var length: Int;
	public var path: String;

	public function new(path: String, length: Int) {
		this.path = path;
		this.length = length;
	}

	public function setRatio(player: LiveActionPlayer, ratio: Float) {
		final frame: Int = Math.floor(length * ratio) + 1;
		final image = cast ResourceLoader.load(
			"res://VisualAssets/LiveAction/" + path + "/Frame" + Std.string(frame).lpad("0", 3) + ".png"
		);
		player.texture = image;
	}
}

class LiveActionPlayer extends Sprite2D {
	var screenshotTaker: ScreenshotTake;
	var screenshot: LiveActionPlayerAnimation;

	var ani: Float = 0.0;

	public override function _ready() {
		screenshot = new LiveActionPlayerAnimation("Screenshot", 508);

		screenshotTaker = cast get_parent().get_node("ScreenshotTake");
	}

	public override function _process(delta: Float) {
		ani += delta * 0.1;
		if(ani > 1.0) {
			ani = 1.0;
		}
		screenshot.setRatio(this, ani * 0.2);
		screenshotTaker.setRatio(ani);
	}
}
