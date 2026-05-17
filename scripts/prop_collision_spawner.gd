extends Node2D

## Adds simple collision to large object-layer sprites (trees, houses) so player/NPCs cannot walk through them.

@export var min_size: float = 20.0
@export var map_root_path: NodePath
@export var name_keywords: Array[String] = ["Tree", "House", "Rock", "Fence", "Wall", "Building"]


func _ready() -> void:
	call_deferred("_spawn_collisions")


func _spawn_collisions() -> void:
	var root: Node = self
	if map_root_path != NodePath():
		root = get_node_or_null(map_root_path)
	if root == null:
		return
	_add_for_node(root)


func _add_for_node(node: Node) -> void:
	for child in node.get_children():
		if child is Sprite2D:
			_maybe_add_body(child as Sprite2D)
		if child.get_child_count() > 0:
			_add_for_node(child)


func _maybe_add_body(sprite: Sprite2D) -> void:
	var tex := sprite.texture
	if tex == null:
		return
	var size := tex.get_size() * sprite.scale
	if size.x < min_size and size.y < min_size:
		return
	var node_name := str(sprite.name)
	var matches := false
	for kw in name_keywords:
		if kw.to_lower() in node_name.to_lower():
			matches = true
			break
	if not matches:
		return
	if sprite.get_parent().get_node_or_null("PropCollision") != null:
		return

	var body := StaticBody2D.new()
	body.name = "PropCollision"
	body.collision_layer = PhysicsLayers.WORLD
	body.collision_mask = 0
	body.position = sprite.position

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(maxf(size.x * 0.5, 8.0), maxf(size.y * 0.35, 8.0))
	shape.shape = rect
	shape.position = Vector2(0, size.y * 0.15)

	body.add_child(shape)
	sprite.get_parent().add_child(body)
