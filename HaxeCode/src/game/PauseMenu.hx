package game;

import godot.*;

using game.MacroHelpers;
using game.NodeHelpers;

class PauseMenu extends ColorRect {
	public override function _ready() {
		final resume = get_node("Resume").as(Button);
		resume.connect("pressed", new Callable(this, "onResumePressed"));

		final restart = get_node("Restart").as(Button);
		restart.connect("pressed", new Callable(this, "onRestartPressed"));

		final slider = get_node("Slider").as(HSlider);
		slider.set_value(50.0);
		slider.connect("value_changed", new Callable(this, "onMouseSensitivityChanged"));
	}

	function onResumePressed() {
		Input.set_mouse_mode(MOUSE_MODE_CAPTURED);
		visible = false;
	}

	function onRestartPressed() {
		Input.set_mouse_mode(MOUSE_MODE_CAPTURED);
		visible = false;

		final player = this.get_persistent_node("Player").as(Player);
		player.perishByLava();
	}

	function onMouseSensitivityChanged(value: Float) {
		final player = this.get_persistent_node("Player").as(Player);
		player.setMouseSensitivity(value);

		final sliderValueLabel = get_node("Slider/ValueLabel").as(Label);
		sliderValueLabel.text = value + "%";
	}
}
