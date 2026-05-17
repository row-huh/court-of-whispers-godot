extends Control

@export var joystick_radius: float = 48.0

@onready var knob: Control = $JoystickZone/JoystickBase/JoystickKnob
@onready var base: Control = $JoystickZone/JoystickBase

var _dragging := false
var _touch_index := -1
var _vector := Vector2.ZERO


func _ready() -> void:
	base.gui_input.connect(_on_base_input)


func _process(_delta: float) -> void:
	if _vector.length_squared() > 0.01:
		Input.action_press("move_left", _vector.x < -0.35)
		Input.action_press("move_right", _vector.x > 0.35)
		Input.action_press("move_up", _vector.y < -0.35)
		Input.action_press("move_down", _vector.y > 0.35)
	else:
		_release_moves()


func _on_base_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_touch_index = t.index
			_dragging = true
			_update_knob(t.position)
		elif t.index == _touch_index:
			_reset()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_knob(event.position)


func _update_knob(local_pos: Vector2) -> void:
	var center := base.size * 0.5
	var offset := local_pos - center
	if offset.length() > joystick_radius:
		offset = offset.normalized() * joystick_radius
	knob.position = center + offset - knob.size * 0.5
	_vector = offset / joystick_radius


func _reset() -> void:
	_dragging = false
	_touch_index = -1
	_vector = Vector2.ZERO
	knob.position = base.size * 0.5 - knob.size * 0.5
	_release_moves()


func _release_moves() -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("move_up")
	Input.action_release("move_down")
