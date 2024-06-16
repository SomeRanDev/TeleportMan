package game;

import godot.*;

import game.Player;

using game.MacroHelpers;
using game.NodeHelpers;

class Spell extends Area3D {
	@:export var onPickup: String;
	@:export var spellName: String;

	var spell: Node3D;
	var glow: Node3D;

	public override function _ready() {
		spell = this.get_node_3d("Spell");
		glow = this.get_node_3d("SpellGlow");

		this.connect("body_entered", new Callable(this, "on_body_entered"));
	}

	public override function _process(delta: Float) {
		final time = Time.get_ticks_msec();
		spell.position = new Vector3(0, 1.5 + Math.sin(time * 0.003) * 0.5, 0);
		spell.rotation.y += delta * 3.0;

		final s = 0.5 + (Math.cos(time * 0.001333) * 0.1);
		glow.scale = new Vector3(s, 0.5, s);
		glow.rotation.y += delta * -1.5;
	}

	public function on_body_entered(body: Node3D) {
		if(body.name == "Player") {
			final player = body.as(Player);

			if(onPickup.length > 0) {
				final e = new Expression();
				final inputs = new PackedStringArray();
				inputs.push_back("player");
				e.parse(onPickup, inputs);
				e.execute(cast [player], this);
			}

			player.addSpell(spellName);
			this.get_persistent_node("SpellGained").as(SpellGained).start(spellName);

			// play player animation + sound
			position.y = 999.0;
			queue_free();
		}
	}
}
