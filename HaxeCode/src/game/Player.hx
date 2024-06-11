package game;

import godot.*;

import game.Input.GameInput;

class Player extends CharacterBody3D {
	var camera: Camera3D;

	var gravity: Float;
	var mouseRotation: Vector3;
	var rotationInput: Float;
	var tiltInput: Float;
	var lastPosition: Vector3;

	public override function _ready() {
		camera = cast get_node("CameraController/Camera3D");
		GameInput.init();
	}

	public override function _unhandled_input(event: InputEvent) {
		switch(event.get_class()) {
			case "InputEventKey": {
				final keyEvent: InputEventKey = cast event;
				if(keyEvent.get_keycode() == KEY_ESCAPE) {
					GameInput.setMouseCaptured(false);
				}
			}
			case "InputEventMouseMotion" if(GameInput.getIsMouseCaptured()): {
				final mouseMotionEvent: InputEventMouseMotion = cast event;
				rotationInput += -mouseMotionEvent.get_relative().x * 0.1;
				tiltInput += -mouseMotionEvent.get_relative().y * 0.1;
			}
			case "InputEventMouseButton" if(!GameInput.getIsMouseCaptured()) : {
				final buttonEvent: InputEventMouseButton = cast event;
				if(buttonEvent.is_pressed()) {
					if(buttonEvent.get_button_index() == MOUSE_BUTTON_LEFT) {
						GameInput.setMouseCaptured(true);
					}
				}
			}
		}
	}

	public override function _process(delta: Float) {
		GameInput.update();
	}

	public override function _physics_process(delta: Float) {
		final velocity = get_velocity();

		if(!is_on_floor()) {
			velocity.y -= gravity * delta;
		}

		updateCamera(delta);

		if(GameInput.isJumpJustPressed() && is_on_floor()) {
			velocity.y = 7.0;
		}

		final inputDir = new Vector2(GameInput.getMoveXAxis(delta), GameInput.getMoveYAxis(delta)).normalized();
		final direction = inputDir.rotated(-mouseRotation.y);

		final SPEED = 5.0;
		final moveSpeed = Input.is_key_pressed(KEY_SHIFT) ? (SPEED * 5.0) : SPEED;
		if(!direction.is_zero_approx()) {
			velocity.x = direction.x * moveSpeed;
			velocity.z = direction.y * moveSpeed;
		} else {
			velocity.x = Godot.move_toward(velocity.x, 0.0, moveSpeed);
			velocity.z = Godot.move_toward(velocity.z, 0.0, moveSpeed);
		}

		set_velocity(velocity);
		move_and_slide();
	}

	function updateCamera(delta: Float) {
		mouseRotation.x += tiltInput * delta;
		mouseRotation.x = mouseRotation.x.clamp(-Math.PI / 2.0, Math.PI / 2.0);
		mouseRotation.y += rotationInput * delta;

		final transform = camera.get_transform();
		transform.basis = untyped __gdscript__("Basis.from_euler({0})", mouseRotation);
		camera.set_transform(transform);

		final rotation = camera.get_rotation();
		rotation.z = 0.0;
		camera.set_rotation(rotation);

		rotationInput = 0.0;
		tiltInput = 0.0;
	}
}
