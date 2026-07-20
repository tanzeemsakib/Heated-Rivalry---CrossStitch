extends Control

@export var line_color: Color = Color(0.9, 0.85, 0.75, 0.9)  # light cream, mostly opaque
@export var dash_length: float = 8.0
@export var line_width: float = 2.0

func _draw() -> void:
	draw_dashed_line(
		Vector2(0, 0),
		Vector2(0, size.y),
		line_color,
		line_width,
		dash_length,
		true,   # aligned
		true    # antialiased
	)
