extends Resource
class_name DialogueLine

## One line in a conversation. speaker must be exactly "npc" or "player" --
## used by dialogue_box.gd to pick the right portrait and name label.

@export var speaker: String = "npc"  # "npc" or "player"
@export_multiline var text: String = ""
