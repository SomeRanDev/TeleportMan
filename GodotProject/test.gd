extends Sprite2D

var frameIndex: int = 0;
var time: float = 0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("bla");

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	#var changed = false;
	#time += delta * 180;
	#while time >= 1.0:
		#time -= 1.0;
		#if time < 0.0:
			#time = 0.0;
		#if frameIndex < 363:
			#changed = true;
			#frameIndex += 1;
#
	#if changed:
		#self.texture = load(
			#"res://VisualAssets/LiveAction/Intro1/Frame%03d.png" % frameIndex
		#)
