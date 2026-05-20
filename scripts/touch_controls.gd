extends Control

@export var joystick_radius: float = 64.0

@onready var knob: Control = $JoystickZone/JoystickBase/JoystickKnob
@onready var base: Control = $JoystickZone/JoystickBase

var _dragging := false
var _touch_index := -1
var _vector := Vector2.ZERO


func _ready() -> void:
	# Ensure individual base and knob elements do not filter out inputs
	base.mouse_filter = MOUSE_FILTER_IGNORE
	knob.mouse_filter = MOUSE_FILTER_IGNORE

	# Style Joystick Base (Circular, semi-transparent dark, gold border)
	var base_style := StyleBoxFlat.new()
	base_style.bg_color = Color(0.12, 0.09, 0.08, 0.35)
	base_style.border_width_left = 2
	base_style.border_width_top = 2
	base_style.border_width_right = 2
	base_style.border_width_bottom = 2
	base_style.border_color = Color(0.83, 0.65, 0.28, 0.5)
	base_style.corner_radius_top_left = int(base.size.x * 0.5)
	base_style.corner_radius_top_right = int(base.size.x * 0.5)
	base_style.corner_radius_bottom_right = int(base.size.x * 0.5)
	base_style.corner_radius_bottom_left = int(base.size.x * 0.5)
	base_style.anti_aliasing = true
	base.add_theme_stylebox_override("panel", base_style)

	# Style Joystick Knob (Circular, solid gold with parchment highlight)
	var knob_style := StyleBoxFlat.new()
	knob_style.bg_color = Color(0.83, 0.65, 0.28, 0.8)
	knob_style.border_width_left = 1
	knob_style.border_width_top = 1
	knob_style.border_width_right = 1
	knob_style.border_width_bottom = 1
	knob_style.border_color = Color(0.91, 0.84, 0.72, 0.9)
	knob_style.corner_radius_top_left = int(knob.size.x * 0.5)
	knob_style.corner_radius_top_right = int(knob.size.x * 0.5)
	knob_style.corner_radius_bottom_right = int(knob.size.x * 0.5)
	knob_style.corner_radius_bottom_left = int(knob.size.x * 0.5)
	knob_style.anti_aliasing = true
	knob.add_theme_stylebox_override("panel", knob_style)



func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return

	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			var base_rect := Rect2(base.global_position, base.size)
			if base_rect.has_point(t.position):
				_touch_index = t.index
				_dragging = true
				_update_knob_from_global(t.position)
		elif t.index == _touch_index:
			_reset()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _touch_index:
			_update_knob_from_global(d.position)
	
	# Mouse emulation for easy desktop testing
	elif event is InputEventMouseButton:
		var m := event as InputEventMouseButton
		if m.button_index == MOUSE_BUTTON_LEFT:
			if m.pressed:
				var base_rect := Rect2(base.global_position, base.size)
				if base_rect.has_point(m.position):
					_touch_index = -2 # Special index representing the desktop mouse drag
					_dragging = true
					_update_knob_from_global(m.position)
			elif _touch_index == -2:
				_reset()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _touch_index == -2 and _dragging:
			_update_knob_from_global(mm.position)



func _process(_delta: float) -> void:
	if _vector.length_squared() > 0.01:
		_handle_action("move_left", "ui_left", _vector.x < -0.35)
		_handle_action("move_right", "ui_right", _vector.x > 0.35)
		_handle_action("move_up", "ui_up", _vector.y < -0.35)
		_handle_action("move_down", "ui_down", _vector.y > 0.35)
	else:
		_release_moves()


func _handle_action(move_act: String, ui_act: String, active: bool) -> void:
	if active:
		Input.action_press(move_act)
		Input.action_press(ui_act)
	else:
		Input.action_release(move_act)
		Input.action_release(ui_act)



func _update_knob_from_global(global_pos: Vector2) -> void:
	var base_center := base.global_position + base.size * 0.5
	var offset := global_pos - base_center
	if offset.length() > joystick_radius:
		offset = offset.normalized() * joystick_radius
	knob.position = base.size * 0.5 + offset - knob.size * 0.5
	_vector = offset / joystick_radius


func _reset() -> void:
	_dragging = false
	_touch_index = -1
	_vector = Vector2.ZERO
	knob.position = base.size * 0.5 - knob.size * 0.5
	_release_moves()


func _release_moves() -> void:
	Input.action_release("move_left")
	Input.action_release("ui_left")
	Input.action_release("move_right")
	Input.action_release("ui_right")
	Input.action_release("move_up")
	Input.action_release("ui_up")
	Input.action_release("move_down")
	Input.action_release("ui_down")
