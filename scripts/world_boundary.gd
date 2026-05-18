extends Node2D

## Spawns four invisible StaticBody2D walls around the entire tilemap so
## the player (and NPCs) cannot walk off the edge of the map.
##
## Attach this node as a child of the same Node2D that contains the tilemap
## instance, then set [tilemap_path] to point at the TileMapLayer (or the
## root of the TMX scene) you want to bound.

@export var tilemap_path: NodePath

## Extra thickness of each boundary wall (pixels).  Larger values make it
## harder to squeeze through a corner but doesn't affect the visual result.
@export var wall_thickness: float = 64.0

func _ready() -> void:
	call_deferred("_build_boundaries")


func _build_boundaries() -> void:
	# Resolve the tilemap node -------------------------------------------------
	var map_node: Node = get_node_or_null(tilemap_path)
	if map_node == null:
		push_warning("WorldBoundary: tilemap_path not set or not found.")
		return

	# Find the first TileMapLayer inside the resolved node so we can call
	# get_used_rect().  Works whether the export scene has a bare TileMapLayer
	# at root or nested under a Node2D.
	var layer := _find_tile_map_layer(map_node)
	if layer == null:
		push_warning("WorldBoundary: no TileMapLayer found under %s." % map_node.name)
		return

	var used: Rect2i = layer.get_used_rect()
	if used.size == Vector2i.ZERO:
		push_warning("WorldBoundary: TileMapLayer has no tiles.")
		return

	var tile_size: Vector2 = Vector2(layer.tile_set.tile_size)

	# World-space position of the tilemap layer itself (accounts for the parent
	# scene offset set in game.tscn).
	var layer_origin: Vector2 = layer.global_position

	# Top-left corner of the bounding box in world space
	var world_min := layer_origin + Vector2(used.position) * tile_size
	# Bottom-right corner
	var world_max := layer_origin + Vector2(used.position + used.size) * tile_size

	var width  := world_max.x - world_min.x
	var height := world_max.y - world_min.y
	var cx     := (world_min.x + world_max.x) * 0.5
	var cy     := (world_min.y + world_max.y) * 0.5

	# Build the four walls -----------------------------------------------------
	# Each entry: [center_x, center_y, half_width, half_height]
	var walls := [
		# Top
		[cx,           world_min.y - wall_thickness * 0.5, width * 0.5 + wall_thickness, wall_thickness * 0.5],
		# Bottom
		[cx,           world_max.y + wall_thickness * 0.5, width * 0.5 + wall_thickness, wall_thickness * 0.5],
		# Left
		[world_min.x - wall_thickness * 0.5, cy, wall_thickness * 0.5, height * 0.5 + wall_thickness],
		# Right
		[world_max.x + wall_thickness * 0.5, cy, wall_thickness * 0.5, height * 0.5 + wall_thickness],
	]

	for w in walls:
		var body := StaticBody2D.new()
		body.collision_layer = PhysicsLayers.WORLD
		body.collision_mask  = 0
		# Position is global; set it via global_position after adding to tree
		add_child(body)
		body.global_position = Vector2(w[0], w[1])

		var shape := CollisionShape2D.new()
		var rect  := RectangleShape2D.new()
		rect.size = Vector2(w[2], w[3]) * 2.0   # RectangleShape2D uses half-extents internally but size= is full size in 4.x
		shape.shape = rect
		body.add_child(shape)

	print("WorldBoundary: built 4 walls around '%s' (used rect %s, tile_size %s)." \
		% [map_node.name, used, tile_size])


## Recursively finds the first TileMapLayer node in the subtree.
func _find_tile_map_layer(node: Node) -> TileMapLayer:
	if node is TileMapLayer:
		return node as TileMapLayer
	for child in node.get_children():
		var result := _find_tile_map_layer(child)
		if result != null:
			return result
	return null
