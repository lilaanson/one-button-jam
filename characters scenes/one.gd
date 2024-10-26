extends Area2D

var initial_scale = Vector2(20, 20)  # Starting very small
var speed: float
var react: int
var sound_effect : AudioStreamPlayer = AudioStreamPlayer.new()
var rejectArray = ["res://environment/mad.wav","res://environment/sad.wav","res://environment/noQuestion.wav","res://environment/noWay.wav","res://environment/offended.wav","res://environment/surprise.wav"]
var acceptArray = ["res://environment/cough.wav"]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(sound_effect)
	$AnimationPlayer.play("stand")

	$Sprite2D.scale = initial_scale
	position.x = 555
	position.y = 315
	var rng = RandomNumberGenerator.new()
	speed = rng.randf_range(1,5)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func spriteLeave():
	position.x += speed
	
func reaction(result): # female
	var rng = RandomNumberGenerator.new()
	react = rng.randf_range(1,3) # inc to 3 if reactions are too often
	if react == 1:
		if result == "right": # rejected
			var randomSound = rng.randf_range(0,rejectArray.size()-1)
			var current_sound = load (rejectArray[randomSound])
			sound_effect.stream = current_sound
			sound_effect.play()
		# else: # entered
			# var randomSound = rng.randf_range(1,acceptArray.size)
			# var current_sound = load (rejectArray[randomSound])
			# sound_effect.stream = current_sound
			# sound_effect.play()
		
			
		
	
	
