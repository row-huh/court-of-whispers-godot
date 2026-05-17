extends Node

## Connects Interactable areas to the player when they enter/exit range.

@onready var _player: CharacterBody2D = get_parent()


func _ready() -> void:
	await get_tree().process_frame
	for npc in get_tree().get_nodes_in_group("npc_agents"):
		var area: Interactable = npc.get_node_or_null("InteractArea")
		if area == null:
			continue
		area.player_entered.connect(_on_enter.bind(area))
		area.player_exited.connect(_on_exit.bind(area))


func _on_enter(player: Node2D, area: Interactable) -> void:
	if player != _player:
		return
	_player.register_interactable(area)


func _on_exit(player: Node2D, area: Interactable) -> void:
	if player != _player:
		return
	_player.unregister_interactable(area)
