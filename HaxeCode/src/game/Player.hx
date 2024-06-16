package game;

import godot.*;

import game.Input.GameInput;
import game.LiveActionPlayer.LiveActionPlayerLeft;
import game.LiveActionPlayer.LiveActionPlayerRight;
import game.AutomoveNode3d;

using game.NodeHelpers;
using game.MacroHelpers;

class Player extends CharacterBody3D {
	@:export var playIntroAnimation = false;

	var camera: Camera3D;
	var cameraController: Node3D;
	var velocityDir: Node3D;

	var cachedJumpInput = 0.0;
	var timeOffGround = 0.0;

	var maxHorizontalAerialSpeed = 15.0;

	var xzSpeed: Float = 0.0;
	var gravity: Float;
	var mouseRotation: Vector3;
	var rotationInput: Float;
	var tiltInput: Float;
	var lastPosition: Vector3;

	var storedTeleport: Int = 0;
	var storedPosition: Vector3;
	var storedMouseRotation: Vector3;
	var storedCameraForward: Vector3;

	var isFallingIntoNextLevel: Bool = false;
	var targetFallSpot: Vector3;
	var initialFallSpot: Vector3;
	var hitGroundShake: Float = 0.0;

	var respawnPosition: Vector3;

	var isPerishing: Bool = false;
	var perishAnimationTimer: Float = 0.0;
	var transitionShader: ShaderMaterial;

	var transitionInTimer: Float = 0.0;

	var cameraShake: Float = 0.0;

	var hasGoodJump = true;
	var hasTeleport = false;

	var currentLeftAnimation: String;
	var currentRightAnimation: String;

	var isIntro = true;

	var spellCount = 0;
	var spellNames = [];

	var storedVelocity: Vector3;

	static final MAX_HORIZONTAL_SPEED = 15.0;
	static final INFINITE_JUMPS = false;
	static final FAKE_DASH = false;

	public function getCamera(): Camera3D {
		return camera;
	}

	public function setTargetFallingSpot(location: Vector3) {
		isFallingIntoNextLevel = true;
		targetFallSpot = location;
		initialFallSpot = new Vector3(-9999, global_position.y, 0);
		setRespawnPosition(location);
		clearTeleport();
	}

	public function setRespawnPosition(location: Vector3) {
		respawnPosition = location;
	}

	public function start(spawnLocation: Vector3) {
		global_position = spawnLocation;
		setRespawnPosition(spawnLocation);

		transitionShader.set_shader_parameter("animationRatio", 1.0);
		transitionShader.set_shader_parameter("animationMode", 1.0);
		transitionInTimer = 1.0;

		
	}

	var left: LiveActionPlayerLeft;
	var right: LiveActionPlayerRight;

	public override function _ready() {
		gravity = 20;
		camera = cast get_node("CameraController/Camera3D");
		cameraController = cast get_node("CameraController");
		velocityDir = cast get_node("CameraController/Camera3D/VelocityDir");

		final transitionObject = this.get_persistent_node("Transition").as(ColorRect);
		transitionShader = transitionObject.get_material().as(ShaderMaterial);

		left = camera.get_node("Left").as(LiveActionPlayerLeft);
		if(playIntroAnimation) left.setAnimation(left.leftInit);

		right = camera.get_node("Right").as(LiveActionPlayerRight);
		if(playIntroAnimation) right.setAnimation(right.rightInit);

		isIntro = playIntroAnimation;

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

	function updateCameraShake() {
		if(cameraShake > 0.0) {
			//final cameraController = get_node("CameraController").as(Node3D);
			camera.position = new Vector3(
					Math.sin(Time.get_ticks_msec() * 0.05) * 0.333,
					Math.cos(Time.get_ticks_msec() * 0.09) * 0.645,
					0.0
				) * cameraShake;
		}
	}

	function resetCameraPosition() {
		camera.position = Vector3.ZERO;
	}

	function clearTeleport() {
		final sst: ScreenshotTake = cast camera.get_node("ScreenshotTake");
		sst.onUnalive();
		storedTeleport = 0;
	}

	public override function _process(delta: Float) {
		GameInput.update();

		if(isPerishing) {
			velocity = Vector3.ZERO;
			global_position.y -= delta * 0.8;

			perishAnimationTimer += delta * 0.5;
			cameraShake = perishAnimationTimer * 1.0;
			transitionShader.set_shader_parameter("animationRatio", Math.min(1.0, perishAnimationTimer * perishAnimationTimer));

			if(perishAnimationTimer >= 1.0) {
				isPerishing = false;
				perishAnimationTimer = 0.0;
				global_position = respawnPosition;
				transitionShader.set_shader_parameter("animationRatio", 1.0);
				transitionShader.set_shader_parameter("animationMode", 1.0);
				transitionInTimer = 1.0;
				cameraShake = 0.0;
				resetCameraPosition();

				clearTeleport();

				// on respawn onRespawn
			}

			updateCameraShake();
			updateSpeedTracker(delta);
			return;
		}

		if(transitionInTimer > 0.0) {
			transitionInTimer -= delta * 1.0;
			if(transitionInTimer < 0.0) transitionInTimer = 0.0;
			transitionShader.set_shader_parameter("animationRatio", transitionInTimer*transitionInTimer*transitionInTimer);
		}

		if(hitGroundShake > 0.0) {
			hitGroundShake -= delta * 3.0;
			if(hitGroundShake < 0.0) {
				hitGroundShake = 0.0;
				resetCameraPosition();
			}
			cameraShake = hitGroundShake;
		}

		updateCameraShake();

		if(canTeleport()) {
			if(hasTeleport && storedTeleport == 0 && GameInput.isLeftActionJustPressed()) {
				final teleportToCamera: Node3D = cast this.get_persistent_node("TeleportToViewport/TeleportToController/TeleportTo");
				teleportToCamera.set_global_transform(camera.get_global_transform());
	
				storedTeleport = 1;
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
	
				//right.setAnimation(right.teleportStart);
	
				final sst: ScreenshotTake = cast camera.get_node("ScreenshotTake");
				sst.reset();
			} else if(storedTeleport == 1) {
				final teleportToCamera: Node3D = cast this.get_persistent_node("TeleportToViewport/TeleportToController/TeleportTo");
				teleportToCamera.set_global_transform(camera.get_global_transform());
	
				storedPosition = get_global_position();
				storedMouseRotation = mouseRotation;
				storedCameraForward = -camera.get_global_transform().basis.z;
			} else if(hasTeleport && storedTeleport == 3 && GameInput.isLeftActionJustPressed()) {
				storedVelocity = velocity;
				storedTeleport = 4;
				final sst: ScreenshotTake = cast camera.get_node("ScreenshotTake");
				sst.enter();
			}
		}

		if(is_on_floor()) {
			timeOffGround = 0.0;
		} else {
			timeOffGround += delta;
		}

		if(cachedJumpInput > 0.0) {
			cachedJumpInput -= delta;
		} else if(GameInput.isJumpJustPressed()) {
			cachedJumpInput = 0.2;
		}
	}

	public function stopRecording() {
		storedTeleport = 2;
	}

	public function finishTeleportStart() {
		storedTeleport = 3;
	}

	public function finishTeleport() {
		final cameraForwardVector = -camera.get_global_transform().basis.z;

		var trueVelocity = velocity;
		if(trueVelocity.length() < storedVelocity.length()) {
			trueVelocity = storedVelocity;
		}

		final velocityForward = trueVelocity.normalized();
		final speed = trueVelocity.length();

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

		storedTeleport = 0;
		final sst: ScreenshotTake = cast camera.get_node("ScreenshotTake");
		sst.visible = false;

		if(speed > 0.0) {
			set_velocity(-velocityDir.get_global_transform().basis.z * speed);
			maxHorizontalAerialSpeed = Math.max(MAX_HORIZONTAL_SPEED, getHorizontalSpeedVector().length());
		}
	}

	function getHorizontalSpeedVector(): Vector2 {
		return new Vector2(velocity.x, velocity.z);
	}

	function canMove() {
		if(isIntro) {
			if(right.hasAnimation()) {
				return false;
			} else {
				isIntro = false;
			}
		}
		return (!isFallingIntoNextLevel && initialFallSpot.x > -9998) || hitGroundShake > 0.0;
	}

	function canTeleport() {
		return !isFallingIntoNextLevel;
	}

	function updateSpeedTracker(delta: Float) {
		final tracker = this.get_persistent_node("SpeedArrow/SpeedTrackerBase").as(Node3D);
		final scaler = this.get_persistent_node("SpeedArrow/SpeedTrackerBase/SpeedTrackerScaler").as(Node3D);
		final speedArrowViewport = this.get_persistent_node("SpeedArrowViewport").as(Sprite2D);

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

		this.get_persistent_node("SpeedLabel").as(Label).text = "(" + Std.string(Math.floor(velocity.length() * 10.0)) + " pixels per second)";
	}

	public override function _physics_process(delta: Float) {
		if(isPerishing) {
			updateCamera(delta);
			return;
		}

		final velocity = get_velocity();

		if(!is_on_floor() && velocity.y > -60.0) {
			velocity.y -= gravity * delta;
		}

		updateCamera(delta);

		if(cachedJumpInput > 0.0 && (INFINITE_JUMPS || timeOffGround < 0.2)) {
			final jumpSpeed = hasGoodJump ? 7.0 : 3.0;
			velocity.y = Math.max(jumpSpeed, velocity.y + jumpSpeed);
			cachedJumpInput = 0.0;
			maxHorizontalAerialSpeed = Math.max(MAX_HORIZONTAL_SPEED, getHorizontalSpeedVector().length());
		}

		final inputDir = if(canMove()) {
			new Vector2(GameInput.getMoveXAxis(delta), GameInput.getMoveYAxis(delta)).normalized();
		} else {
			new Vector2(0, 0);
		}
		final direction = inputDir.rotated(-mouseRotation.y);

		final SPEED = 5.0;
		var moveSpeed = delta * (FAKE_DASH && Input.is_key_pressed(KEY_SHIFT) ? (SPEED * 5.0) : SPEED);
		if(!is_on_floor()) {
			
			if(!direction.is_zero_approx()) {
				final xzSpeed = getHorizontalSpeedVector();
				var xzLength = xzSpeed.length();
				final xzAngle = xzSpeed.angle();
				final inputDirection = direction.angle();

				final speedVsDirection = Math.abs(Godot.angle_difference(xzAngle, inputDirection));

				if(xzLength < 3.0) {
					velocity.x += direction.x * moveSpeed * 10.0;
					velocity.z += direction.y * moveSpeed * 10.0;
				} else if(speedVsDirection > Math.PI * 0.5) {
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
					final _xzAngle = Godot.rotate_toward(xzAngle, inputDirection, moveSpeed * 0.4);
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

				final tooFast = xzLength > (MAX_HORIZONTAL_SPEED + 0.5);

				var xzAngle = xzSpeed.angle();

				var inputDirection = direction.angle();
				final speedVsDirection = Math.abs(Godot.angle_difference(xzAngle, inputDirection));

				if(speedVsDirection < (Math.PI * 0.03)) {
					if(!tooFast) {
						xzLength = Godot.move_toward(xzLength, MAX_HORIZONTAL_SPEED, moveSpeed);
					}
					velocity.x = Math.cos(inputDirection) * xzLength;
					velocity.z = Math.sin(inputDirection) * xzLength;
				} else if(speedVsDirection < (Math.PI * 0.333)) {
					//if(xzLength < 15.0) {
						// xzLength -= moveSpeed * 10.0;
						// if(xzLength < 0) xzLength = 0;
					//}

					xzLength = Godot.move_toward(xzLength, 0, moveSpeed * (tooFast ? 2.0 : 10.0));
					if(tooFast) {
						xzAngle = Godot.rotate_toward(xzAngle, inputDirection, delta * 0.3);
					} else {
						xzAngle = inputDirection;
					}
					//Godot.rotate_toward(xzAngle, inputDirection, delta * 3.0);
					velocity.x = Math.cos(xzAngle) * xzLength;
					velocity.z = Math.sin(xzAngle) * xzLength;
				} else if(speedVsDirection < (Math.PI * 0.75)) {
					//if(xzLength < 15.0) {
						// xzLength -= moveSpeed * 10.0;
						// if(xzLength < 0) xzLength = 0;
					//}
					xzLength = Godot.move_toward(xzLength, 0, moveSpeed * (tooFast ? 3.0 : 10.0));
					xzAngle = Godot.rotate_toward(xzAngle, inputDirection, delta * (tooFast ? 1.0 : 6.0));
					if(tooFast) {
						// just let it break at this point...
						
					} else {
						//xzAngle = inputDirection;
					}
					velocity.x = Math.cos(xzAngle) * xzLength;
					velocity.z = Math.sin(xzAngle) * xzLength;
				} else {
					// velocity.x = Godot.move_toward(velocity.x, 0.0, moveSpeed * 10.0);
					// velocity.z = Godot.move_toward(velocity.z, 0.0, moveSpeed * 10.0);

					// if(xzLength < 15.0) {
					// 	xzLength += moveSpeed;
					// }
					xzLength = Godot.move_toward(xzLength, 0.0, moveSpeed * (tooFast ? 5.0 : 15.0));
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
			final tooFast = xzLength > (MAX_HORIZONTAL_SPEED + 0.5);
			xzLength = Godot.move_toward(xzLength, 0.0, moveSpeed * (tooFast ? 5.0 : 10.0));
			velocity.x = Math.cos(xzAngle) * xzLength;
			velocity.z = Math.sin(xzAngle) * xzLength;
		}

		updateSpeedTracker(delta);

		if(isFallingIntoNextLevel) {
			final ratio = (global_position.y - initialFallSpot.y) / (targetFallSpot.y - initialFallSpot.y);
			if(ratio > 0.5) {
				if(initialFallSpot.x < -9998) {
					initialFallSpot.x = global_position.x;
					initialFallSpot.z = global_position.z;
				}
				final r = (ratio - 0.5) / 0.5;
				final x = Godot.lerp(initialFallSpot.x, targetFallSpot.x, r);
				final z = Godot.lerp(initialFallSpot.z, targetFallSpot.z, r);
				global_position.x = x;
				global_position.z = z;
			}
		}

		set_velocity(velocity);
		move_and_slide();

		if(isFallingIntoNextLevel && is_on_floor()) {
			// ON LEVEL START...
			hitGroundShake = 1.0;
			isFallingIntoNextLevel = false;
		}
	}

	function updateCamera(delta: Float) {
		mouseRotation.x += tiltInput * delta;
		mouseRotation.x = mouseRotation.x.clamp(Math.PI * -0.47, Math.PI * 0.47);
		mouseRotation.y += rotationInput * delta;

		updateCameraRotation();

		rotationInput = 0.0;
		tiltInput = 0.0;
	}

	function updateCameraRotation() {
		final transform = cameraController.get_transform();
		transform.basis = untyped __gdscript__("Basis.from_euler({0})", mouseRotation);
		cameraController.set_transform(transform);

		final rotation = cameraController.get_rotation();
		rotation.z = 0.0;
		cameraController.set_rotation(rotation);
	}

	public function perishByLava() {
		// If currently teleporting...
		if(storedTeleport == 4) {
			return;
		}

		isPerishing = true;
		perishAnimationTimer = 0.0;

		transitionShader.set_shader_parameter("animationMode", 0.0);
		transitionShader.set_shader_parameter("animationRatio", 0.0);
		transitionShader.set_shader_parameter("transitionInType",
			((transitionShader.get_shader_parameter("transitionInType") : Int) + Godot.randi_range(1, 2)) % 3
		);
	}

	public function forceGroundVelocity(velocity2d: Vector2) {
		velocity.x = velocity2d.x;
		velocity.z = velocity2d.y;
	}

	public function obtainGoodJump() {
		hasGoodJump = true;
	}

	public function obtainTeleport() {
		hasTeleport = true;
	}

	public function addSpell(spellName: String) {
		spellCount++;
		spellNames.push(spellName);

		final spellsText = spellCount == 1 ? "Spell" : "Spells";
		static final foundTexts = [
			"Found", "Learned", "Gained", "Obtained", "Mastered", "Used",
			"Taken", "Learnt", "Consumed", "Stolen", "Eaten", "Tasted",
			"Tickled", "Licked", "Slurped", "Burped", "Digested"
		];

		final found = if(spellCount < foundTexts.length) {
			foundTexts[spellCount];
		} else {
			"Are Now Mine";
		}

		this.get_persistent_node("SpellCount").as(Label).text = spellCount + " " + spellsText + " " + found;

		if(spellName == "Teleport") {
			right.setAnimation(right.getTeleport);
		} else {
			left.setAnimation(left.eat);
		}
	}

	function updateAnimations() {
	}

	public function removeMonkeyHead() {
		final monkeyHead = this.get_scene_node("MonkeyHead").as(AutomoveNode3d);
		monkeyHead.speed = 2.0;
	}

	public function summonCrap() {
		
	}
}
