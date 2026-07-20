extends StaticBody3D
## Attach to each Suspect node. Recommended structure for a 2.5D
## (Paper Mario style) suspect:
##
## Suspect1 (StaticBody3D)          <- this script goes here
## ├── CollisionShape3D             <- size it to roughly match the sprite
## └── AnimatedSprite3D             <- name it exactly "AnimatedSprite3D"
##
## Put this node in the "suspect" group (done automatically below).
## Assign a SuspectData resource in the inspector.

@export var data: SuspectData
@export var idle_animation_name: String = "default"
@export var highlight_color: Color = Color(1.3, 1.3, 1.0)  # warm bright tint
@export var highlight_scale: float = 1.08

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D

var _base_scale: Vector3
var _hover_tween: Tween

func _ready() -> void:
	add_to_group("suspect")
	_play_idle()
	if sprite:
		_base_scale = sprite.scale

func _play_idle() -> void:
	if sprite == null:
		return
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(idle_animation_name):
		sprite.play(idle_animation_name)
	else:
		push_warning("Suspect '%s' missing animation: %s" % [name, idle_animation_name])

func interact() -> void:
	GameManager.open_interview(self)

func set_highlighted(is_hovered: bool) -> void:
	if sprite == null:
		return
	if _hover_tween:
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.set_parallel(true)
	var target_modulate := highlight_color if is_hovered else Color.WHITE
	var target_scale := _base_scale * highlight_scale if is_hovered else _base_scale
	_hover_tween.tween_property(sprite, "modulate", target_modulate, 0.12)
	_hover_tween.tween_property(sprite, "scale", target_scale, 0.12)
