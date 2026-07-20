extends Control

var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _base_position: Vector2

func _ready() -> void:
	_base_position = position

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_offset = get_global_mouse_position() - global_position
		else:
			_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		global_position = get_global_mouse_position() - _drag_offset

func reset_position() -> void:
	position = _base_position
	_dragging = false
