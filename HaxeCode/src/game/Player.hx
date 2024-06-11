package game;

import godot.*;

import game.Input.GameInput;

class Player extends CharacterBody3D {
	var camera: Camera3D;
	var velocityDir: Node3D;

	var cachedJumpInput = false;

	var xzSpeed: Float = 0.0;
	var gravity: Float;
	var mouseRotation: Vector3;
	var rotationInput: Float;
	var tiltInput: Float;
	var lastPosition: Vector3;

	var storedPosition: Vector3;
	var storedMouseRotation: Vector3;
	var storedCameraForward: Vector3;

	public override function _ready() {
		gravity = 20;
		camera = cast get_node("CameraController/Camera3D");
		velocityDir = cast get_node("CameraController/Camera3D/VelocityDir");

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

		if(GameInput.isLeftActionJustPressed()) {
			final teleportToCamera: Node3D = cast get_tree().get_current_scene().get_node("TeleportToViewport/TeleportToController/TeleportTo");
			teleportToCamera.set_global_transform(camera.get_global_transform());

			storedPosition = get_global_position();
			storedMouseRotation = mouseRotation;
			storedCameraForward = -camera.get_global_transform().basis.z;
		} else if(GameInput.isRightActionJustPressed()) {
			final cameraForwardVector = -camera.get_global_transform().basis.z;
			final velocityForward = get_velocity().normalized();
			final speed = get_velocity().length();

			if(speed > 0.0) {
				if(velocityForward.is_equal_approx(Vector3.UP)) {
					velocityDir.set_global_rotation_degrees(new Vector3(90, 0, 0));
				} else if(velocityForward.is_equal_approx(Vector3.DOWN)) {
					velocityDir.set_global_rotation_degrees(new Vector3(-90, 0, 0));
				} else {
					velocityDir.look_at(velocityDir.get_global_transform().origin + velocityForward, Vector3.UP);
				}
			}

			// final speed = get_velocity().length();
			// final offset = new Quaternion(, cameraForwardVector);

			set_global_position(storedPosition);
			mouseRotation = storedMouseRotation;
			updateCameraRotation();

			if(speed > 0.0) {
				trace(-velocityDir.get_global_transform().basis.z * speed);
				set_velocity(-velocityDir.get_global_transform().basis.z * speed);
			}
		}

		if(GameInput.isJumpJustPressed()) {
			cachedJumpInput = true;
		}
	}

	public override function _physics_process(delta: Float) {
		final velocity = get_velocity();

		if(!is_on_floor()) {
			velocity.y -= gravity * delta;
		}

		updateCamera(delta);

		if(cachedJumpInput && is_on_floor()) {
			velocity.y = 7.0;
		}

		final inputDir = new Vector2(GameInput.getMoveXAxis(delta), GameInput.getMoveYAxis(delta)).normalized();
		final direction = inputDir.rotated(-mouseRotation.y);

		{
			final tracker: Node3D = cast get_tree().get_current_scene().get_node("SpeedArrow/SpeedTrackerBase");
			final scaler: Node3D = cast get_tree().get_current_scene().get_node("SpeedArrow/SpeedTrackerBase/SpeedTrackerScaler");

			final velocityForward = get_velocity().normalized();
			final speed = get_velocity().length();


			scaler.set_scale(new Vector3(1.0, 1.0, speed / 15.0));
			scaler.set_visible(speed > 0.0001);

			if(speed > 0.0) {
				if(velocityForward.is_equal_approx(Vector3.UP)) {
					velocityDir.set_global_rotation_degrees(new Vector3(90, 0, 0));
				} else if(velocityForward.is_equal_approx(Vector3.DOWN)) {
					velocityDir.set_global_rotation_degrees(new Vector3(-90, 0, 0));
				} else {
					velocityDir.look_at(velocityDir.get_global_transform().origin + velocityForward, Vector3.UP);
				}
			}

			tracker.set_global_rotation(tracker.get_global_rotation().lerp_angle_vec3(velocityDir.get_rotation(), 10.0 * delta));
		}

		final SPEED = 5.0;
		var moveSpeed = delta * (Input.is_key_pressed(KEY_SHIFT) ? (SPEED * 5.0) : SPEED);
		if(!direction.is_zero_approx()) {
			//velocity.x = direction.x * moveSpeed;
			//velocity.z = direction.y * moveSpeed;

			final xzSpeed = new Vector2(velocity.x, velocity.z);
			var xzLength = xzSpeed.length();
			if(xzLength < 2.0) {
				moveSpeed *= 3.0;
			}

			if(xzLength < moveSpeed) {
				velocity.x += direction.x * moveSpeed;
				velocity.z += direction.y * moveSpeed;
			} else {

				var xzAngle = xzSpeed.angle();

				var inputDirection = direction.angle();
				final speedVsDirection = Math.abs(Godot.angle_difference(xzAngle, inputDirection));

				if(speedVsDirection < (Math.PI * 0.03)) {
					if(xzLength < 15.0) {
						xzLength += moveSpeed;
					}
					velocity.x = Math.cos(inputDirection) * xzLength;
					velocity.z = Math.sin(inputDirection) * xzLength;
				} else if(speedVsDirection < (Math.PI * 0.333)) {
					if(xzLength < 15.0) {
						xzLength -= moveSpeed * 3.0;
						if(xzLength < 0) xzLength = 0;
					}

					xzAngle = Godot.rotate_toward(xzAngle, inputDirection, delta * 3.0);
					velocity.x = Math.cos(xzAngle) * xzLength;
					velocity.z = Math.sin(xzAngle) * xzLength;
				} else if(speedVsDirection < (Math.PI * 0.8)) {
					if(xzLength < 15.0) {
						xzLength -= moveSpeed * 8.0;
						if(xzLength < 0) xzLength = 0;
					}
					xzAngle = Godot.rotate_toward(xzAngle, inputDirection, delta * 3.0);
					velocity.x = Math.cos(xzAngle) * xzLength;
					velocity.z = Math.sin(xzAngle) * xzLength;
				} else {
					velocity.x = Godot.move_toward(velocity.x, 0.0, moveSpeed * 10.0);
					velocity.z = Godot.move_toward(velocity.z, 0.0, moveSpeed * 10.0);
				}
			
			}
		} else {
			velocity.x = Godot.move_toward(velocity.x, 0.0, moveSpeed);
			velocity.z = Godot.move_toward(velocity.z, 0.0, moveSpeed);
		}

		set_velocity(velocity);
		move_and_slide();

		cachedJumpInput = false;
	}

	function updateCamera(delta: Float) {
		mouseRotation.x += tiltInput * delta;
		mouseRotation.x = mouseRotation.x.clamp(-Math.PI / 2.0, Math.PI / 2.0);
		mouseRotation.y += rotationInput * delta;

		updateCameraRotation();

		rotationInput = 0.0;
		tiltInput = 0.0;
	}

	function updateCameraRotation() {
		final transform = camera.get_transform();
		transform.basis = untyped __gdscript__("Basis.from_euler({0})", mouseRotation);
		camera.set_transform(transform);

		final rotation = camera.get_rotation();
		rotation.z = 0.0;
		camera.set_rotation(rotation);
	}
}
