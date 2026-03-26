extends ColorRect

@export var duration: float = 0.3

var time_left: float = duration
var dir: String = "fwd" # or rev

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.transition.connect(transition)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not time_left > 0:
		return
	
	time_left -= delta
	var mat = material
	
	if dir == "rev":
		var val: float = time_left / duration
		if mat is ShaderMaterial:
			mat.set_shader_parameter("circle_size", val)
		else:
			print("NO MATERIAL")
	
	if dir == "fwd":
		var val: float = abs((time_left / duration) - 1)
		if mat is ShaderMaterial:
			mat.set_shader_parameter("circle_size", val)
		else:
			print("NO MATERIAL")

func transition(direction: String):
	print("Triggered transition " + str(direction))
	if direction == "fwd":
		play_fwd()
	elif direction == "rev":
		play_rev()

func play_fwd():
	time_left = duration
	dir = "fwd"

func play_rev():
	time_left = duration
	dir = "rev"
