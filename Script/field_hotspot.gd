extends Control
## Attach to any field Control (Label or TextureRect) inside ClaimColumn or
## MemoColumn. Detects a clean click (press+release with minimal movement,
## so it doesn't fire during a card drag) and reports itself.
##
## IMPORTANT: this node's Mouse Filter must be set to "Pass" in the
## Inspector, not the default "Ignore" -- otherwise it won't receive input
## at all, since Labels/TextureRects ignore mouse events by default.
signal field_clicked(hotspot: Control)
@export var field_type: String = ""   # "name", "badge", "years", "photo", or "password"
@export var card_side: String = ""    # "claim" or "memo"
const CLICK_MOVE_THRESHOLD: float = 6.0
var _press_pos: Vector2
var _base_font_color: Color

func _ready() -> void:
	add_to_group("field_hotspots")
	if get_class() == "Label":
		_base_font_color = get_theme_color("font_color")

func highlight() -> void:
	if get_class() == "Label":
		add_theme_color_override("font_color", Color(0.85, 0.65, 0.1))
	else:
		modulate = Color(1.3, 1.1, 0.6)

func unhighlight() -> void:
	if get_class() == "Label":
		add_theme_color_override("font_color", _base_font_color)
	else:
		modulate = Color.WHITE

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_pos = event.position
		else:
			if event.position.distance_to(_press_pos) < CLICK_MOVE_THRESHOLD:
				field_clicked.emit(self)
