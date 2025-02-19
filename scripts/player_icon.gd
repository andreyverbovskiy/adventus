extends CharacterBody2D

var target_position: Vector2
var speed = 500  # Adjust speed to your liking
var is_moving = false

func _ready():
	target_position = global_position

func _physics_process(delta):
	if is_moving:
		var direction = (target_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()

		# Stop moving if close enough to target
		if global_position.distance_to(target_position) < 5:
			is_moving = false
			velocity = Vector2.ZERO
			move_and_slide()

func move_to(new_position: Vector2):
	target_position = new_position
	is_moving = true
