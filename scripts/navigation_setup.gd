extends NavigationRegion2D

@export var region_rect: Rect2 = Rect2(-80, -80, 400, 400)


func _ready() -> void:
	var poly := NavigationPolygon.new()
	var outline := PackedVector2Array([
		region_rect.position,
		Vector2(region_rect.end.x, region_rect.position.y),
		region_rect.end,
		Vector2(region_rect.position.x, region_rect.end.y),
	])
	poly.add_outline(outline)
	poly.make_polygons_from_outlines()
	navigation_polygon = poly
