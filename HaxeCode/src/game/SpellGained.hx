package game;

import godot.*;

class SpellGained extends Node2D {
	var animationTime = 0.0;

	var spellGained: Label;
	var moreInfo: Label;

	var spellGainedX: Float;
	var moreInfoX: Float;

	public override function _ready() {
		spellGained = cast get_node("SpellGainedLabel");
		moreInfo = cast get_node("SpellGainedLabel/MoreInfoLabel");

		spellGainedX = spellGained.size.x / -2.0;
		moreInfoX = (spellGained.size.x - moreInfo.size.x) / 2.0;

		visible = false;
	}

	public override function _process(delta: Float) {
		if(visible) {
			animationTime += delta * 0.4;
			refreshAnimation();
			if(animationTime > 1.0) {
				visible = false;
			}
		}
	}

	function setSpellName(name: String) {
		moreInfo.text = "Got the \"" + name + "\"!";
		moreInfoX = (spellGained.size.x - moreInfo.size.x) / 2.0;
	}

	public function start(name: String) {
		setSpellName(name);
		spellGained.position.x = spellGainedX;
		moreInfo.position.x = moreInfoX;

		moreInfo.modulate.a = 0.0;

		animationTime = 0.0;
		refreshAnimation();

		visible = true;
	}

	function cubicOut(r: Float) {
		r = 1.0 - r;
		return 1.0 - (r * r * r);
	}

	function refreshAnimation() {
		if(animationTime < 0.3) {
			setAnimationPart1(cubicOut(animationTime / 0.3));
		} else if(animationTime < 0.6) {
			final r = cubicOut((animationTime - 0.3) / (0.6 -  0.3));
			moreInfo.position.y = Godot.lerp(80.0, 120.0, r);
			moreInfo.modulate.a = r;
			setAnimationPart1(1.0);
		} else if(animationTime > 0.9) {
			final r = (animationTime - 0.9) / 0.1;
			final r = r * r * r;
			spellGained.position.x = Godot.lerp(spellGainedX, 1000.0, r);
			moreInfo.position.x = Godot.lerp(moreInfoX, -3000.0, r);
		}
	}

	function setAnimationPart1(r: Float) {
		final r = r * r * r;
		this.scale = Vector2.ONE * r;
		this.rotation_degrees = (1.0 - r) * 720.0;
	}
}
