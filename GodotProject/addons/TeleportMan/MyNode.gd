extends Node3D
class_name MyNode

func _init() -> void:
	pass

func _ready() -> void:
	Log.trace.call("in ready...", {
		"fileName": "src/game/MyNode.hx",
		"lineNumber": 5,
		"className": "game.MyNode",
		"methodName": "_ready"
	})
