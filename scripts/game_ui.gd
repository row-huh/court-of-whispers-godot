extends CanvasLayer

@onready var interact_prompt: Label = %InteractPrompt
@onready var intro_screen: Control = %IntroScreen
@onready var end_screen: Control = %EndScreen
@onready var hud: Control = %GameHUD
@onready var night_modal: Control = %NightModal
@onready var talk_touch_btn: Button = %TalkTouchButton
@onready var joystick_zone: Control = %JoystickZone
@onready var daily_popup: Control = %DailyPopup
@onready var popup_texture: TextureRect = %PopupTexture
@onready var daily_close_btn: Button = %DailyCloseButton
@onready var prev_btn: Button = %PrevButton
@onready var next_btn: Button = %NextButton
@onready var page_indicator: Label = %PageIndicator
@onready var drawer_btn: Button = %DrawerToggleButton

const POPUP1_PATH = "res://assets/splash/popup1.png"
const POPUP2_PATH = "res://assets/splash/popup2.png"

var _nearby_npc: NpcAgent = null
var _player: CharacterBody2D = null
var _last_seen_day: int = 0
var _popup_textures: Array[Texture2D] = []
var _current_popup_idx: int = 0
var _drawer_open: bool = false


func _ready() -> void:
	layer = 10
	intro_screen.visible = true
	end_screen.visible = false
	hud.visible = false
	night_modal.visible = false
	interact_prompt.visible = false
	daily_popup.visible = false

	# Load popup textures dynamically
	_popup_textures.append(load(POPUP1_PATH))
	_popup_textures.append(load(POPUP2_PATH))

	# Connect buttons
	daily_close_btn.pressed.connect(_on_daily_close_pressed)
	prev_btn.pressed.connect(_on_prev_pressed)
	next_btn.pressed.connect(_on_next_pressed)
	drawer_btn.pressed.connect(_on_drawer_toggle)

	talk_touch_btn.pressed.connect(_on_touch_talk)
	GameManager.state_changed.connect(_on_state_changed)
	call_deferred("_bind_player")
	call_deferred("_update_api_badge")
	
	drawer_btn.visible = false


func _bind_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if _player:
		_player.nearby_interactable_changed.connect(_on_nearby_changed)


func _process(_delta: float) -> void:
	if _player == null:
		return
	if GameManager.dialogue_open or GameManager.status != "playing":
		interact_prompt.visible = false
		return
	if _nearby_npc and is_instance_valid(_nearby_npc):
		interact_prompt.visible = true
		interact_prompt.text = _nearby_npc.get_prompt()
	else:
		interact_prompt.visible = false


func _on_nearby_changed(npc: NpcAgent) -> void:
	_nearby_npc = npc
	GameManager.active_agent = npc.agent_id if npc else GameManager.active_agent


func _on_touch_talk() -> void:
	if _nearby_npc and is_instance_valid(_nearby_npc):
		_nearby_npc.interactable.interact(_player)


func _on_state_changed() -> void:
	intro_screen.visible = GameManager.status == "intro"
	end_screen.visible = GameManager.status == "won" or GameManager.status == "lost"
	
	var playing = GameManager.status == "playing"
	hud.visible = playing
	drawer_btn.visible = playing
	if not playing:
		_drawer_open = false
		hud.position.x = -350.0
	elif GameManager.day == 1 and not _drawer_open and hud.position.x < -100:
		_drawer_open = true
		hud.position.x = 16.0
		hud._refresh()
		if hud.has_method("start_polling"):
			hud.start_polling()
		
	night_modal.visible = GameManager.pending_night and playing and not GameManager.dialogue_open

	if GameManager.status == "intro":
		_last_seen_day = 0

	if GameManager.status == "playing" and not GameManager.pending_night and GameManager.day > _last_seen_day:
		_last_seen_day = GameManager.day
		_current_popup_idx = 0
		if _popup_textures.size() > 0:
			popup_texture.texture = _popup_textures[0]
			popup_texture.modulate.a = 1.0
			page_indicator.text = "Page 1 of %d" % _popup_textures.size()
		daily_popup.visible = true

	if end_screen.visible:
		%EndTitle.text = "Victory" if GameManager.status == "won" else "Defeat"
		%EndMessage.text = GameManager.ending_message

	if night_modal.visible:
		_populate_night_modal()

	_update_api_badge()


func _update_api_badge() -> void:
	var badge: Label = get_node_or_null("%ApiBadge")
	if badge == null:
		return
	if GameManager.use_http_ai:
		var url := HttpAgentClient.base_url if HttpAgentClient else "?"
		badge.text = "AI: %s" % url
	else:
		badge.text = "Offline stub dialogue"


func _populate_night_modal() -> void:
	var list: RichTextLabel = %NightLog
	if GameManager.request_pending:
		list.text = "[center][i]The court whispers...[/i][/center]"
		return
	
	var bb := "[center][b]Night %d — Whispers in the dark[/b][/center]\n\n" % GameManager.day
	
	# SECTION 1: Whispers
	var todays_night = GameManager.get_todays_night()
	if todays_night.is_empty():
		bb += "  [color=#a0a0a0][i]The court sleeps. Nothing stirs.[/i][/color]\n\n"
	else:
		for e in todays_night:
			bb += "  [b]%s[/b] → [b]%s[/b]\n" % [
				GameManager.get_agent_name(e.get("from", "")),
				GameManager.get_agent_name(e.get("to", "")),
			]
			bb += "  [color=#cccccc]\"%s\"[/color]\n\n" % e.get("reply", "")

	bb += "[center][b]— What Shifted Today —[/b][/center]\n\n"

	# SECTION 2: Deltas
	var deltas = GameManager.get_day_deltas()
	if deltas.is_empty():
		bb += "  [color=#a0a0a0][i]The status quo remains.[/i][/color]"
	else:
		bb += _format_delta_row("Sir Alaric's Trust", GameManager.agents["commander"]["trust"], deltas.get("commander_trust", 0))
		bb += _format_delta_row("Mira's Trust", GameManager.agents["citizen"]["trust"], deltas.get("citizen_trust", 0))
		bb += _format_delta_row("Father Edran's Trust", GameManager.agents["priest"]["trust"], deltas.get("priest_trust", 0))
		bb += _format_delta_row("Father Edran's Fear", GameManager.agents["priest"]["fear"], deltas.get("priest_fear", 0))
		bb += _format_delta_row("Bishop's Proof", GameManager.proof, deltas.get("proof", 0))
		bb += _format_delta_row("Suspicion", GameManager.suspicion, deltas.get("suspicion", 0))

	list.text = bb


func _format_delta_row(label: String, current: int, delta: int) -> String:
	var previous = current - delta
	var d_str = ""
	var d_color = "#8a7b6b" # neutral stone
	
	if delta > 0:
		d_str = "[+%d]" % delta
		d_color = "#d4a648" if not label in ["Suspicion", "Bishop's Proof", "Father Edran's Fear"] else "#c0392b"
	elif delta < 0:
		d_str = "[%d]" % delta
		d_color = "#c0392b" if not label in ["Suspicion", "Bishop's Proof", "Father Edran's Fear"] else "#d4a648"
	else:
		d_str = "[±0]"
	
	# Special case: Fear going up is mostly good/neutral, Suspicion/Proof going up is bad.
	# We colored positive suspicion/proof as red. Positive trust as gold. Negative trust as red.
	
	return "  [color=#a0a0a0]%-22s[/color] [color=#e0e0e0]%2d[/color] → [color=#ffffff]%2d[/color]   [color=%s]%s[/color]\n" % [label, previous, current, d_color, d_str]


func _on_restart_pressed() -> void:
	GameManager.reset_state()
	GameManager.begin_game()
	get_tree().reload_current_scene()


func _on_night_close_pressed() -> void:
	GameManager.close_night()


func _on_daily_close_pressed() -> void:
	daily_popup.visible = false


func _on_prev_pressed() -> void:
	if _popup_textures.size() < 2:
		return
	var prev_idx = (_current_popup_idx - 1 + _popup_textures.size()) % _popup_textures.size()
	_transition_to_page(prev_idx)


func _on_next_pressed() -> void:
	if _popup_textures.size() < 2:
		return
	var next_idx = (_current_popup_idx + 1) % _popup_textures.size()
	_transition_to_page(next_idx)


func _transition_to_page(idx: int) -> void:
	if idx < 0 or idx >= _popup_textures.size():
		return
	_current_popup_idx = idx

	# Smooth cross-fade transition using a Tween
	var tween = create_tween()
	# Fade out old texture
	tween.tween_property(popup_texture, "modulate:a", 0.0, 0.15)
	# Set new texture and update indicators
	tween.tween_callback(func():
		popup_texture.texture = _popup_textures[idx]
		page_indicator.text = "Page %d of %d" % [idx + 1, _popup_textures.size()]
	)
	# Fade in new texture
	tween.tween_property(popup_texture, "modulate:a", 1.0, 0.15)


func _on_drawer_toggle() -> void:
	_drawer_open = not _drawer_open
	var target_x = 16.0 if _drawer_open else -350.0
	var tween = create_tween()
	tween.tween_property(hud, "position:x", target_x, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if _drawer_open:
		if hud.has_method("_refresh"):
			hud._refresh()
		if hud.has_method("start_polling"):
			hud.start_polling()
	else:
		if hud.has_method("stop_polling"):
			hud.stop_polling()
