class_name Interactable
extends Area2D

signal player_entered(player: Node2D)
signal player_exited(player: Node2D)
signal interacted(player: Node2D)

@export var prompt_label: String = "Press E to talk"

var _player_inside: Node2D = null


func _ready() -> void:
	collision_layer = PhysicsLayers.INTERACTABLE
	collision_mask = PhysicsLayers.PLAYER
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = body
	player_entered.emit(body)


func _on_body_exited(body: Node2D) -> void:
	if body != _player_inside:
		return
	_player_inside = null
	player_exited.emit(body)


func can_interact() -> bool:
	return _player_inside != null and GameManager.status == "playing" and not GameManager.dialogue_open


func interact(player: Node2D) -> void:
	if not can_interact():
		return
	interacted.emit(player)
