extends Node
## Autoload (as SFX.tscn, not the bare .gd). Automatically plays a click
## sound on every Button/TextureButton in the game, across every scene --
## no manual per-button wiring needed.

@export var click_sound: AudioStream

@onready var click_player: AudioStreamPlayer = AudioStreamPlayer.new()

func _ready() -> void:
	add_child(click_player)
	click_player.stream = click_sound
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		if not node.pressed.is_connected(_play_click):
			node.pressed.connect(_play_click)

func _play_click() -> void:
	click_player.stop()
	click_player.play()
