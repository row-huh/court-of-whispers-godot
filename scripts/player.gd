extends CharacterBody2D

@export var speed: float = 200

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var last_direction: Vector2 = Vector2.DOWN

func _update_animation(direction: Vector2) -> void:
	var anim = ""

	# choose idle vs walking
	var prefix = "idle"
	if direction != Vector2.ZERO:
		prefix = "walking"

	# choose direction
	if last_direction.x > 0:
		anim = prefix + "_right"
	elif last_direction.x < 0:
		anim = prefix + "_left"
	elif last_direction.y < 0:
		anim = prefix + "_up"
	else:
		anim = prefix + "_down"

	if sprite.animation != anim:
		sprite.play(anim)


func _physics_process(_delta):
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# remove diagonal movement
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_left"):
		direction.y = 0
	elif Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down"):
		direction.x = 0
	else:
		direction = Vector2.ZERO

	direction = direction.normalized()
	velocity = direction * speed
	move_and_slide()

	# store last direction when moving
	if direction != Vector2.ZERO:
		last_direction = direction

	_update_animation(direction)
