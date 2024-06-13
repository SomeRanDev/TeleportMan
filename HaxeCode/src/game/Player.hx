package game;

import godot.*;

import game.Input.GameInput;

class Player extends CharacterBody3D {
	var camera: Camera3D;
	var velocityDir: Node3D;

	var cachedJumpInput = false;

	var maxHorizontalAerialSpeed = 15.0;

	var xzSpeed: Float = 0.0;
	var gravity: Float;
	var mouseRotation: Vector3;
	var rotationInput: Float;
	var tiltInput: Float;
	var lastPosition: Vector3;

	var storedPosition: Vector3;
	var storedMouseRotation: Vector3;
	var storedCameraForward: Vector3;

	static final MAX_HORIZONTAL_SPEED = 15.0;

	public override function _ready() {
		gravity = 20;
		camera = cast get_node("CameraController/Camera3D");
		velocityDir = cast get_node("CameraController/Camera3D/VelocityDir");

		GameInput.init();

		global_position = cast(get_scene_node("PlayerStart"), Node3D).global_position;
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

	function get_scene_node(path: String): Node {
		return get_tree().get_current_scene().get_node(path);
	}

	function get_persistent_node(path: String): Node {
		return get_scene_node("PersistentContent/" + path);
	}

	public override function _process(delta: Float) {
		GameInput.update();

		if(GameInput.isLeftActionJustPressed()) {
			final teleportToCamera: Node3D = cast get_persistent_node("TeleportToViewport/TeleportToController/TeleportTo");
			teleportToCamera.set_global_transform(camera.get_global_transform());

			storedPosition = get_global_position();
			storedMouseRotation = mouseRotation;
			storedCameraForward = -camera.get_global_transform().basis.z;

			// final sst = new ScreenshotTake();
			// sst.set_position(new Vector3(0, 0, -0.8));
			// sst.set_rotation_degrees(new Vector3(90, 0, 0));
			// final material: StandardMaterial3D = cast ResourceLoader.load("res://VisualAssets/Materials/ScreenshotTakeMaterial.tres");
			// cast(material.albedo_texture, ViewportTexture).viewport_path = new NodePath("TeleportToViewport");
			// sst.set_surface_override_material(0, material);
			// camera.add_child(sst);

			// final sst: ScreenshotTake = cast camera.get_node("ScreenshotTake");
			// sst.reset();
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
				set_velocity(-velocityDir.get_global_transform().basis.z * speed);
				maxHorizontalAerialSpeed = Math.max(MAX_HORIZONTAL_SPEED, getHorizontalSpeedVector().length());
			}
		}

		if(GameInput.isJumpJustPressed()) {
			cachedJumpInput = true;
		}
	}

	function getHorizontalSpeedVector(): Vector2 {
		return new Vector2(velocity.x, velocity.z);
	}

	public override function _physics_process(delta: Float) {
		final velocity = get_velocity();

		if(!is_on_floor()) {
			velocity.y -= gravity * delta;
		}

		updateCamera(delta);

		if(cachedJumpInput && is_on_floor()) {
			velocity.y = 7.0;
			maxHorizontalAerialSpeed = Math.max(MAX_HORIZONTAL_SPEED, getHorizontalSpeedVector().length());
		}

		final inputDir = new Vector2(GameInput.getMoveXAxis(delta), GameInput.getMoveYAxis(delta)).normalized();
		final direction = inputDir.rotated(-mouseRotation.y);

		{
			final tracker: Node3D = cast get_persistent_node("SpeedArrow/SpeedTrackerBase");
			final scaler: Node3D = cast get_persistent_node("SpeedArrow/SpeedTrackerBase/SpeedTrackerScaler");
			final speedArrowViewport: Sprite2D = cast get_persistent_node("SpeedArrowViewport");
			

			final velocityForward = get_velocity().normalized();
			final speed = get_velocity().length();

			cast(speedArrowViewport.get_material(), ShaderMaterial).set_shader_parameter("opacity", (speed / 8.0).clamp(0.0, 1.0));
			scaler.set_scale(new Vector3(1.0, 1.0, (speed - 3.0) / MAX_HORIZONTAL_SPEED) * 0.5);
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
		if(!is_on_floor()) {
			
			if(!direction.is_zero_approx()) {
				final xzSpeed = getHorizontalSpeedVector();
				var xzLength = xzSpeed.length();
				final xzAngle = xzSpeed.angle();
				final inputDirection = direction.angle();

				final speedVsDirection = Math.abs(Godot.angle_difference(xzAngle, inputDirection));

				if(speedVsDirection > Math.PI * 0.5) {
					velocity.x += direction.x * moveSpeed * 4.0;
					velocity.z += direction.y * moveSpeed * 4.0;

					var changed = false;
					if(xzLength > maxHorizontalAerialSpeed) {
						xzLength = maxHorizontalAerialSpeed;
						changed = true;
					} else if(xzLength < maxHorizontalAerialSpeed && xzLength > MAX_HORIZONTAL_SPEED) {
						maxHorizontalAerialSpeed = xzLength;
					}
					if(changed) {
						velocity.x = Math.cos(xzAngle) * xzLength;
						velocity.z = Math.sin(xzAngle) * xzLength;
					}
				} else {
					final _xzAngle = Godot.rotate_toward(xzAngle, inputDirection, moveSpeed * 0.2);
					velocity.x = Math.cos(_xzAngle) * xzLength;
					velocity.z = Math.sin(_xzAngle) * xzLength;
				}
			}
		} else if(!direction.is_zero_approx()) {
			//velocity.x = direction.x * moveSpeed;
			//velocity.z = direction.y * moveSpeed;

			final xzSpeed = getHorizontalSpeedVector();
			var xzLength = xzSpeed.length();

			if(xzLength < 4.9) {
				velocity.x = direction.x * 5.0;
				velocity.z = direction.y * 5.0;
			} else {

				var xzAngle = xzSpeed.angle();

				var inputDirection = direction.angle();
				final speedVsDirection = Math.abs(Godot.angle_difference(xzAngle, inputDirection));

				if(speedVsDirection < (Math.PI * 0.03)) {
					xzLength = Godot.move_toward(xzLength, MAX_HORIZONTAL_SPEED, moveSpeed);
					velocity.x = Math.cos(inputDirection) * xzLength;
					velocity.z = Math.sin(inputDirection) * xzLength;
				} else if(speedVsDirection < (Math.PI * 0.333)) {
					//if(xzLength < 15.0) {
						// xzLength -= moveSpeed * 10.0;
						// if(xzLength < 0) xzLength = 0;
					//}

					xzLength = Godot.move_toward(xzLength, 0, moveSpeed * 10.0);
					xzAngle = inputDirection;//Godot.rotate_toward(xzAngle, inputDirection, delta * 3.0);
					velocity.x = Math.cos(xzAngle) * xzLength;
					velocity.z = Math.sin(xzAngle) * xzLength;
				} else if(speedVsDirection < (Math.PI * 0.8)) {
					//if(xzLength < 15.0) {
						xzLength -= moveSpeed * 10.0;
						if(xzLength < 0) xzLength = 0;
					//}
					xzLength = Godot.move_toward(xzLength, 0, moveSpeed * 10.0);
					xzAngle = inputDirection;//Godot.rotate_toward(xzAngle, inputDirection, delta * 3.0);
					velocity.x = Math.cos(xzAngle) * xzLength;
					velocity.z = Math.sin(xzAngle) * xzLength;
				} else {
					// velocity.x = Godot.move_toward(velocity.x, 0.0, moveSpeed * 10.0);
					// velocity.z = Godot.move_toward(velocity.z, 0.0, moveSpeed * 10.0);

					// if(xzLength < 15.0) {
					// 	xzLength += moveSpeed;
					// }
					xzLength = Godot.move_toward(xzLength, 0.0, moveSpeed * 15.0);
					velocity.x = Math.cos(xzAngle) * xzLength;
					velocity.z = Math.sin(xzAngle) * xzLength;
				}
			
			}
		} else {
			// velocity.x = Godot.move_toward(velocity.x, 0.0, moveSpeed * 5.0);
			// velocity.z = Godot.move_toward(velocity.z, 0.0, moveSpeed * 5.0);

			final xzSpeed = getHorizontalSpeedVector();
			var xzLength = xzSpeed.length();
			var xzAngle = xzSpeed.angle();
			xzLength = Godot.move_toward(xzLength, 0.0, moveSpeed * 10.0);
			velocity.x = Math.cos(xzAngle) * xzLength;
			velocity.z = Math.sin(xzAngle) * xzLength;
		}

		cast(get_persistent_node("SpeedLabel"), Label).text = Std.string(Math.floor(velocity.length() * 10.0));

		set_velocity(velocity);
		move_and_slide();

		cachedJumpInput = false;
	}

	function updateCamera(delta: Float) {
		mouseRotation.x += tiltInput * delta;
		mouseRotation.x = mouseRotation.x.clamp(Math.PI * -0.4, Math.PI * 0.4);
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
