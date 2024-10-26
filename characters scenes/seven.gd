extends Area2D

var initial_scale = Vector2(20, 20)  # Starting very small
var speed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimationPlayer.play("stand")

	$Sprite2D.scale = initial_scale
	position.x = 555
	position.y = 315
	var rng = RandomNumberGenerator.new()
	var speed = rng.randf_range(2,5)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func spriteLeave():
	position.x += speed
