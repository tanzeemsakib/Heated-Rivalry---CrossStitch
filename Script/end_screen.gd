extends Control
## Attach to an EndScreen Control, hidden by default. Shows the win/lose
## illustration immediately alongside the dialogue box (your existing
## DialogueBox system handles the narrator lines independently). The
## restart button stays hidden until the dialogue finishes.
##
## Expected structure:
##
## EndScreen (Control)
## ├── EndingImageRect (TextureRect)
## └── RestartButton (Button)
@export var win_ending_image: Texture2D
@export var lose_ending_image: Texture2D
@export var narrator_name: String = "Board Secretary"
@export var narrator_portrait: Texture2D
@export var win_lines: Array[String] = [
	"You caught both dummies and kept your real allies.",
	"The vote goes ahead. The CEO is out.",
]
@export var lose_lines: Array[String] = [
	"You got %d out of 5 right.",
	"The vote is compromised — the CEO stays.",
]
@onready var ending_image_rect: TextureRect = $EndingImageRect
@onready var restart_button: Button = $RestartButton

func _ready() -> void:
	visible = false
	restart_button.visible = false
	GameManager.game_ended.connect(_on_game_ended)
	GameManager.dialogue_finished.connect(_on_dialogue_finished)
	restart_button.pressed.connect(_on_restart_pressed)

func _on_game_ended(correct_count: int, all_correct: bool) -> void:
	var lines: Array[String] = win_lines.duplicate() if all_correct else lose_lines.duplicate()
	if not all_correct:
		lines[0] = lines[0] % correct_count
	ending_image_rect.texture = win_ending_image if all_correct else lose_ending_image

	visible = true
	restart_button.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var dialogue := DialogueData.new()
	dialogue.npc_name = narrator_name
	dialogue.npc_portrait = narrator_portrait
	var dialogue_lines: Array[DialogueLine] = []
	for line_text in lines:
		var line := DialogueLine.new()
		line.speaker = "npc"
		line.text = line_text
		dialogue_lines.append(line)
	dialogue.lines = dialogue_lines

	GameManager.dialogue_requested.emit(dialogue)

func _on_dialogue_finished() -> void:
	restart_button.visible = true

func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
