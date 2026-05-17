extends Control

@onready var panel: PanelContainer = %DialoguePanel
@onready var title_label: Label = %AgentTitle
@onready var history: RichTextLabel = %History
@onready var input: LineEdit = %MessageInput
@onready var send_btn: Button = %SendButton
@onready var close_btn: Button = %CloseButton
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	add_to_group("dialogue_controller")
	visible = false
	panel.visible = false
	send_btn.pressed.connect(_on_send)
	close_btn.pressed.connect(_on_close)
	input.text_submitted.connect(_on_text_submitted)
	GameManager.dialogue_requested.connect(_on_dialogue_open)
	GameManager.dialogue_closed.connect(_on_dialogue_closed)
	GameManager.state_changed.connect(_refresh)


func _on_dialogue_open(agent_id: String) -> void:
	visible = true
	panel.visible = true
	var meta: Dictionary = GameManager.agents_meta.get(agent_id, {})
	title_label.text = "%s %s — %s" % [
		meta.get("emoji", ""),
		meta.get("name", agent_id),
		meta.get("title", ""),
	]
	_refresh()
	input.grab_focus()
	await get_tree().process_frame
	if GameManager.conversations[agent_id].is_empty() and not GameManager.use_http_ai:
		var opener := StubDialogue.pick_opener(agent_id)
		GameManager.append_assistant_message(agent_id, opener, {})
		_refresh()
	elif GameManager.conversations[agent_id].is_empty() and GameManager.use_http_ai:
		status_label.text += " · AI linked"
		_refresh()


func _on_dialogue_closed() -> void:
	visible = false
	panel.visible = false


func _on_close() -> void:
	GameManager.close_dialogue()


func _on_text_submitted(_text: String) -> void:
	_on_send()


func _on_send() -> void:
	if not GameManager.can_send_message():
		return
	var text := input.text.strip_edges()
	if text.is_empty():
		return
	input.text = ""
	input.grab_focus()

	GameManager.append_user_message(text)

	if GameManager.use_http_ai:
		var http := get_node_or_null("/root/HttpAgentClient")
		if http and http.has_method("request_agent"):
			GameManager.request_pending = true
			_refresh()
			http.request_agent(GameManager.active_agent, text)
			return

	var delta := StubDialogue.generate_delta(GameManager.active_agent, text, GameManager)
	GameManager.apply_delta(GameManager.active_agent, delta)


func on_agent_response(delta: Dictionary) -> void:
	GameManager.request_pending = false
	GameManager.apply_delta(GameManager.active_agent, delta)


func on_agent_error(message: String) -> void:
	GameManager.request_pending = false
	GameManager.append_assistant_message(
		GameManager.active_agent,
		message if not message.is_empty() else "The voices fall silent. Try again.",
		{}
	)
	_refresh()


func _refresh() -> void:
	if not panel.visible:
		return
	var agent_id := GameManager.active_agent
	status_label.text = "Day %d · %d turns left" % [GameManager.day, GameManager.turns_left]
	if GameManager.request_pending:
		status_label.text += " · thinking..."
	send_btn.disabled = not GameManager.can_send_message()
	input.editable = GameManager.can_send_message()

	var bb := ""
	for msg in GameManager.conversations[agent_id]:
		var role: String = msg.get("role", "")
		var content: String = msg.get("content", "")
		if role == "user":
			bb += "[color=#f1ca62]You:[/color] %s\n\n" % content
		else:
			bb += "[color=#c8b4e8]%s:[/color] %s\n\n" % [
				GameManager.get_agent_name(agent_id),
				content,
			]
			var meta: Dictionary = msg.get("meta", {})
			if meta.get("trust_delta") != null:
				bb += "[font_size=12][i]Trust %+.0f[/i][/font_size]\n" % float(meta["trust_delta"])
			if meta.get("fear_delta") != null:
				bb += "[font_size=12][i]Fear %+.0f[/i][/font_size]\n" % float(meta["fear_delta"])
	history.text = bb

	if GameManager.status != "playing":
		_on_close()
