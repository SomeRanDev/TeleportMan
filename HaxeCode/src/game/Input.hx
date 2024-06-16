package game;

import godot.DisplayServer;
import godot.DisplayServer_WindowMode;
import godot.Input as GodotInput;
import godot.JoyAxis;
import godot.JoyButton;
import godot.Key;
import godot.MouseButton;

class InputAction {
	public var Keyboard: Null<Key>;
	public var Mouse: Null<MouseButton>;
	public var Controller: Null<JoyButton>;
	public var ControllerAxis: Null<JoyAxis>;

	var pressed: Bool = false;
	var time: Int = 0;

	public function new() {}

	public function update(currentTime: Int) {
		final newPressed = checkIsPressed();
		if(pressed != newPressed) {
			pressed = newPressed;
			time = currentTime;
		}
	}

	public function isPressed() return pressed;
	public function isJustPressed(currentTime: Int) return pressed && time == currentTime - 1;
	public function isJustReleased(currentTime: Int) return !pressed && time == currentTime;

	function checkIsPressed() {
		if(Keyboard != null) {
			if(GodotInput.is_key_pressed(Keyboard)) {
				GameInput.setInputKind(InputKind.Keyboard);
				return true;
			}
		}
		if(Mouse != null) {
			if(GodotInput.is_mouse_button_pressed(Mouse)) {
				GameInput.setInputKind(InputKind.Keyboard);
				return true;
			}
		}
		if(Controller != null) {
			GodotInput.get_connected_joypads().forSized(_.length, {
				if(GodotInput.is_joy_button_pressed(_, Controller)) {
					GameInput.setInputKind(InputKind.Controller);
					return true;
				}
			});
		}
		if(ControllerAxis != null) {
			GodotInput.get_connected_joypads().forSized(_.length, {
				if(GodotInput.get_joy_axis(_, ControllerAxis) > 0.5) {
					GameInput.setInputKind(InputKind.Controller);
					return true;
				}
			});
		}
		return false;
	}
}

class InputAxis {
	public var Positive: InputAction;
	public var Negative: InputAction;
	public var ControllerAxis: Null<JoyAxis>;

	public var DeadThreshold = 0.1;

	var AxisValue: Float = 0.0;

	public function new() {
		Positive = new InputAction();
		Negative = new InputAction();
	}

	public function update(currentTime: Int) {
		if(Positive != null) {
			Positive.update(currentTime);
		}
		if(Negative != null) {
			Negative.update(currentTime);
		}
	}

	public function getValue(deltaTime: Float): Float {
		if(ControllerAxis != null) {
			GodotInput.get_connected_joypads().forSized(_.length, {
				final axis = GodotInput.get_joy_axis(_, ControllerAxis);
				if(axis > DeadThreshold || axis < -DeadThreshold) {
					//AxisValue = FunnyMath.lerpf(AxisValue, axis, deltaTime * 5.0);
					//return AxisValue;
					return axis;
				} else {
					//AxisValue = 0.0;
				}
			});
		}
		if(Positive != null && Positive.isPressed()) {
			return 1.0;
		}
		if(Negative != null && Negative.isPressed()) {
			return -1.0;
		}
		return 0.0;
	}
}

enum abstract InputKind(Int) {
	var Keyboard = 0;
	var Mouse = 1;
	var Controller = 2;
}

/**
	Our custom singleton class for handling input.
**/
class GameInput extends godot.Object {
	static var inputKind = InputKind.Keyboard;

	static var time: Int;

	static var MenuOk: InputAction;
	static var MenuCancel: InputAction;
	static var MenuUp: InputAction;
	static var MenuDown: InputAction;
	static var MenuLeft: InputAction;
	static var MenuRight: InputAction;

	static var MoveX: InputAxis;
	static var MoveY: InputAxis;
	static var CameraX: InputAxis;
	static var CameraY: InputAxis;
	static var Jump: InputAction;
	static var LeftAction: InputAction;
	static var RightAction: InputAction;

	static var hasInit = false;

	/**
		Should be called ONCE at the start of the game.
	**/
	public static function init() {
		if(!hasInit) {
			GodotInput.set_use_accumulated_input(false);
			setMouseCaptured(false);

			initDefaultInputConfig();

			hasInit = true;
		}
	}

	/**
		Set up the default controls configuration.
	**/
	static function initDefaultInputConfig() {
		MenuOk = new InputAction();
		MenuOk.Keyboard = Key.KEY_ENTER;
		MenuOk.Controller = JOY_BUTTON_A;

		MenuCancel = new InputAction();
		MenuCancel.Keyboard = Key.KEY_ESCAPE;
		MenuCancel.Controller = JOY_BUTTON_B;

		MenuUp = new InputAction();
		MenuUp.Keyboard = Key.KEY_W;
		MenuUp.Controller = JOY_BUTTON_DPAD_UP;

		MenuDown = new InputAction();
		MenuDown.Keyboard = Key.KEY_S;
		MenuDown.Controller = JOY_BUTTON_DPAD_DOWN;

		MenuLeft = new InputAction();
		MenuLeft.Keyboard = Key.KEY_A;
		MenuLeft.Controller = JOY_BUTTON_DPAD_LEFT;

		MenuRight = new InputAction();
		MenuRight.Keyboard = Key.KEY_D;
		MenuRight.Controller = JOY_BUTTON_DPAD_RIGHT;

		MoveX = new InputAxis();
		MoveX.ControllerAxis = JOY_AXIS_LEFT_X;
		MoveX.Positive.Keyboard = Key.KEY_D;
		MoveX.Negative.Keyboard = Key.KEY_A;

		MoveY = new InputAxis();
		MoveY.ControllerAxis = JOY_AXIS_LEFT_Y;
		MoveY.Positive.Keyboard = Key.KEY_S;
		MoveY.Negative.Keyboard = Key.KEY_W;

		CameraX = new InputAxis();
		CameraX.ControllerAxis = JOY_AXIS_RIGHT_X;

		CameraY = new InputAxis();
		CameraY.ControllerAxis = JOY_AXIS_RIGHT_Y;

		Jump = new InputAction();
		Jump.Keyboard = Key.KEY_SPACE;
		Jump.Controller = JOY_BUTTON_A;

		LeftAction = new InputAction();
		LeftAction.Mouse = MouseButton.MOUSE_BUTTON_LEFT;
		LeftAction.Controller = JOY_BUTTON_RIGHT_SHOULDER;

		RightAction = new InputAction();
		RightAction.Mouse = MouseButton.MOUSE_BUTTON_RIGHT;
		RightAction.Controller = JOY_BUTTON_LEFT_SHOULDER;
	}

	/**
		Updates the type of input that's being used.
		Important for displaying the correct UI icons.
	**/
	public static function setInputKind(kind: InputKind) {
		if(inputKind != kind) {
			inputKind = kind;
			// TODO: refresh UI related to displaying input?
		}
	}

	/**
		Returns `true` if last received menu input used was a mouse button.
	**/
	public static function isUsingMouse() {
		return inputKind == InputKind.Mouse;
	}

	/**
		Returns `true` if last received input was from a controller.
	**/
	public static function isUsingController() {
		return inputKind == InputKind.Controller;
	}

	/**
		Checks and updates the state of the inputs.
	**/
	public static function update() {
		time++;
		[MoveX, MoveY, CameraX, CameraY].repeatExpr(_.update(time));
		[Jump, LeftAction, RightAction].repeatExpr(_.update(time));

		if(GodotInput.is_action_just_pressed("fullscreen_toggle")) {
			final mode: DisplayServer_WindowMode = if(DisplayServer.window_get_mode(0) == WINDOW_MODE_FULLSCREEN) {
				WINDOW_MODE_WINDOWED;
			} else {
				WINDOW_MODE_FULLSCREEN;
			}
			DisplayServer.window_set_mode(mode, 0);
		}
	}

	/**
		Updates menu-related inputs.
	**/
	public static function updateMenu() {
		time++;
		[MenuOk, MenuCancel, MenuUp, MenuDown, MenuLeft, MenuRight].repeatExpr(_.update(time));
	}

	/**
		Get `isMouseCaptured`.
	**/
	public static function getIsMouseCaptured() {
		return GodotInput.get_mouse_mode() == MOUSE_MODE_CAPTURED;
	}

	/**
		Sets whether the game has "captured" the mouse.
	**/
	public static function setMouseCaptured(captured: Bool) {
		GodotInput.set_mouse_mode(captured ? MOUSE_MODE_CAPTURED : MOUSE_MODE_VISIBLE);
	}

	// ---
	// * Game inputs
	public static function getMoveXAxis(deltaTime: Float) return MoveX.getValue(deltaTime);
	public static function getMoveYAxis(deltaTime: Float) return MoveY.getValue(deltaTime);
	public static function getCameraXAxis(deltaTime: Float) return CameraX.getValue(deltaTime);
	public static function getCameraYAxis(deltaTime: Float) return CameraY.getValue(deltaTime);
	public static function isJumpPressed() return Jump.isPressed();
	public static function isJumpJustPressed() return Jump.isJustPressed(time);
	public static function isLeftActionPressed() return LeftAction.isPressed();
	public static function isLeftActionJustPressed() {
		if(GodotInput.get_mouse_mode() != MOUSE_MODE_CAPTURED) {
			return false;
		}
		return LeftAction.isJustPressed(time);
	}
	public static function isRightActionJustPressed() {
		if(GodotInput.get_mouse_mode() != MOUSE_MODE_CAPTURED) {
			return false;
		}
		return RightAction.isJustPressed(time);
	}

	// ---
	// * Menu inputs
	public static function isMenuCancelJustPressed() return MenuCancel.isJustPressed(time);
	public static function isMenuOkJustPressed() return MenuOk.isJustPressed(time);

	public static function isScrollDown() return GodotInput.is_action_just_pressed("menu_wheel_down");
	public static function isScrollUp() return GodotInput.is_action_just_pressed("menu_wheel_up");

	public static function isLeftJustPressed() return MenuLeft.isJustPressed(time);
	public static function isRightJustPressed() return MenuRight.isJustPressed(time);
	public static function isUpJustPressed() return MenuUp.isJustPressed(time);
	public static function isDownJustPressed() return MenuDown.isJustPressed(time);

	public static function isLeftJustReleased() return MenuLeft.isJustReleased(time);
	public static function isRightJustReleased() return MenuRight.isJustReleased(time);
	public static function isUpJustReleased() return MenuUp.isJustReleased(time);
	public static function isDownJustReleased() return MenuDown.isJustReleased(time);

	public static function isLeftPressed() return MenuLeft.isPressed();
	public static function isRightPressed() return MenuRight.isPressed();
	public static function isUpPressed() return MenuUp.isPressed();
	public static function isDownPressed() return MenuDown.isPressed();
}
