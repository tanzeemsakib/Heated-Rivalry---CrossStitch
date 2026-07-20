extends StaticBody3D

## Attach to your dialogue NPC node. Same billboard sprite pattern as
## suspects, but a separate script/group since this NPC just triggers a
## conversation, not the interview/mark-ally-or-dummy flow.
##
## NPC (StaticBody3D)               <- this script
## ├── CollisionShape3D
## └── AnimatedSprite3D             <- Billboard: Y-Billboard, "default"
##                                      idle animation, same as suspects
##
## Assign a DialogueData resource in the Inspector.

@export var dialogue: DialogueData
@export var idle_animation_name: String = "default"
@export var highlight_color: Color = Color(1.3, 1.3, 1.0)
@export var highlight_scale: float = 1.08

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D

var _base_scale: Vector3
var _hover_tween: Tween

func _ready() -> void:
	add_to_group("npc")
	_play_idle()
	if sprite:
		_base_scale = sprite.scale

func _play_idle() -> void:
	if sprite == null:
		return
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(idle_animation_name):
		sprite.play(idle_animation_name)

func interact() -> void:
	if dialogue == null:
		push_warning("NPC '%s' has no DialogueData assigned." % name)
		return
	GameManager.open_dialogue(dialogue)
	
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
