extends AnimatableBody3D

var base_pos: Vector3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	base_pos = global_position;


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	global_position = base_pos + Vector3(sin(Time.get_ticks_msec() * 0.001) * 5.0, 0, 0);
