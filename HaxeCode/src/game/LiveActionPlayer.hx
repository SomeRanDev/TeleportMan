package game;

import godot.*;

using StringTools;

class LiveActionPlayerAnimation {
	public var length: Int;
	public var path: String;
	public var rate: Float = 1.0;
	public var loop: Bool = false;

	public function new(path: String, length: Int) {
		this.path = path;
		this.length = length;
	}

	public function setRatio(player: Sprite2D, frame: Float) {
		var frame: Int = Math.floor(frame) + 1;//Math.floor(length * ratio) + 1;
		if(frame > length) frame = length;
		final image = cast ResourceLoader.load(
			"res://VisualAssets/LiveAction/" + path + "/Frame_" + frame + ".png"
		);
		player.texture = image;
	}
}

class LiveActionPlayerLeft extends Sprite2D {
	public var leftInit: LiveActionPlayerAnimation;
	public var leftRun: LiveActionPlayerAnimation;
	public var eat: LiveActionPlayerAnimation;

	var currentAnimation: LiveActionPlayerAnimation;

	var ani: Float = 0.0;

	public override function _ready() {
		leftInit = new LiveActionPlayerAnimation("LeftInit", 51);
		leftRun = new LiveActionPlayerAnimation("LeftRun", 36);
		//leftRun.loop = true;
		eat = new LiveActionPlayerAnimation("Eat", 32);
		eat.rate = 1.5;
		visible = false;
	}

	public override function _process(delta: Float) {
		if(currentAnimation != null) {
			ani += delta * 35.0 * currentAnimation.rate;
			if(ani > currentAnimation.length) {
				ani = currentAnimation.length;
			}

			currentAnimation.setRatio(this, ani);

			if(ani >= currentAnimation.length) {
				if(currentAnimation.loop) {
					ani = 0;
				} else {
					currentAnimation = null;
					visible = false;
				}
			}
		}
	}

	public function setAnimation(animation: LiveActionPlayerAnimation) {
		currentAnimation = animation;
		currentAnimation.setRatio(this, 0.0);
		ani = 0.0;
		visible = true;
	}

	public function hasAnimation() {
		return currentAnimation != null;
	}
}

class LiveActionPlayerRight extends Sprite2D {
	var screenshotTaker: ScreenshotTake;

	public var rightInit: LiveActionPlayerAnimation;
	public var rightRun: LiveActionPlayerAnimation;
	public var getTeleport: LiveActionPlayerAnimation;
	public var teleportStart: LiveActionPlayerAnimation;
	public var teleportEnd: LiveActionPlayerAnimation;

	var currentAnimation: LiveActionPlayerAnimation;

	var ani: Float = 0.0;

	public override function _ready() {
		rightInit = new LiveActionPlayerAnimation("RightInit", 319);
		rightRun = new LiveActionPlayerAnimation("RightRun", 36);
		getTeleport = new LiveActionPlayerAnimation("GetTeleport", 43);
		teleportStart = new LiveActionPlayerAnimation("TeleportStart", 139);
		teleportStart.rate = 3.0;
		teleportEnd = new LiveActionPlayerAnimation("TeleportEnd", 18);

		screenshotTaker = cast get_parent().get_node("ScreenshotTake");

		visible = false;
	}

	public override function _process(delta: Float) {
		if(currentAnimation != null) {
			ani += delta * 35.0 * currentAnimation.rate;
			if(ani > currentAnimation.length) {
				ani = currentAnimation.length;
			}

			currentAnimation.setRatio(this, ani);

			if(ani >= currentAnimation.length) {
				if(currentAnimation.loop) {
					ani = 0;
				} else {
					currentAnimation = null;
					visible = false;
				}
			}
		}

		// ani += delta * 0.1;
		// if(ani > 1.0) {
		// 	ani = 1.0;
		// }
		// screenshot.setRatio(this, ani * 0.2);
		// screenshotTaker.setRatio(ani);
	}

	public function setAnimation(animation: LiveActionPlayerAnimation) {
		currentAnimation = animation;
		currentAnimation.setRatio(this, 0.0);
		ani = 0.0;
		visible = true;
	}

	public function hasAnimation() {
		return currentAnimation != null;
	}
}
