package game;

import game.Input.GameInput;
import godot.*;

using game.MacroHelpers;
using game.NodeHelpers;

class Title extends Node2D {
	var time: Float;
	var background: Sprite2D;
	var texture1: CompressedTexture2D;
	var texture2: CompressedTexture2D;

	var fadeOut: ColorRect;
	var fadeOutTimer = 0.0;

	public override function _ready() {
		GameInput.init();

		final resume = get_node("StartGame").as(Button);
		resume.connect("pressed", new Callable(this, "onStartGamePressed"));

		background = cast get_node("Background");

		texture1 = cast ResourceLoader.load("res://VisualAssets/TexturesAndSprites/Title1.png");
		texture2 = cast ResourceLoader.load("res://VisualAssets/TexturesAndSprites/Title2.png");
		
		fadeOut = cast get_node("FadeOut");
	}

	function onStartGamePressed() {
		if(fadeOutTimer == 0.0) {
			fadeOutTimer = 0.01;
			get_node("StartGame").queue_free();
		}
	}

	public override function _process(delta: Float) {
		if(fadeOutTimer > 0.0) {
			fadeOutTimer += delta * 3.0;
			fadeOut.color.a = fadeOutTimer;
			if(fadeOutTimer >= 1.0) {
				Input.set_mouse_mode(MOUSE_MODE_CAPTURED);
				get_tree().change_scene_to_file("res://Levels/PersistentContent.tscn");
			}
			return;
		}

		time += delta * 4.0;
		if(time >= 1.0) {
			background.texture = background.texture == texture1 ? texture2 : texture1;
			time = 0.0;
		}
	}
}