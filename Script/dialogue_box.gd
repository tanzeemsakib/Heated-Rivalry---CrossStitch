extends Control

## Attach to a DialogueBox Control, hidden by default. Expected structure:
##
## DialogueBox (Control)
## ├── PortraitRect (TextureRect)
## ├── SpeakerLabel (Label)
## ├── DialogueTextLabel (Label)
## └── AdvanceButton (Button)     -- stretch this to cover the WHOLE panel,
##                                    make it visually invisible (flat/empty
##                                    StyleBox, no text) so clicking ANYWHERE
##                                    on the box advances the conversation.

@onready var portrait_rect: TextureRect = $PortraitRect
@onready var speaker_label: Label = $SpeakerLabel
@onready var text_label: Label = $DialogueTextLabel
@onready var advance_button: Button = $AdvanceButton

var _current: DialogueData = null
var _index: int = -1

func _ready() -> void:
	visible = false
	GameManager.dialogue_requested.connect(_on_dialogue_requested)
	advance_button.pressed.connect(_advance)

func _on_dialogue_requested(data: DialogueData) -> void:
	_current = data
	_index = -1
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_advance()

func _advance() -> void:
	_index += 1

	if _current == null or _index >= _current.lines.size():
		_end_dialogue()
		return

	var line: DialogueLine = _current.lines[_index]
	if line.speaker == "npc":
		speaker_label.text = _current.npc_name
		portrait_rect.texture = _current.npc_portrait
	else:
		speaker_label.text = "You"
		portrait_rect.texture = _current.player_portrait

	text_label.text = line.text

func _end_dialogue() -> void:
	visible = false
	_current = null
	_index = -1
	GameManager.dialogue_finished.emit()
