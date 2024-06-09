@tool
extends EditorPlugin

const AUTOLOAD_NAME = "HxAutoLoad"

func _enter_tree():
	add_custom_type("MyNode", "Node3D", preload("MyNode.gd"), preload("res://icon.svg"))

func _exit_tree():
	remove_custom_type("MyNode")
