extends Control

@export var opening_image_1: Texture2D
@export var opening_image_2: Texture2D

@onready var image_rect: TextureRect = $ImageRect
@onready var advance_button: Button = $AdvanceButton

var _index: int = 0

func _ready() -> void:
	image_rect.texture = opening_image_1
	advance_button.pressed.connect(_advance)

func _advance() -> void:
	_index += 1
	if _index == 1:
		image_rect.texture = opening_image_2
	else:
		get_tree().change_scene_to_file("res://Scenes/main.tscn")
