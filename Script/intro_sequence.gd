extends Node

## Attach to any node in your Main scene (e.g. the Main node itself).
## Assign an "intro" DialogueData resource with your character's 2 opening
## lines. On scene load, plays that dialogue through the DialogueBox; once
## it finishes, starts the meeting countdown.

@export var intro_dialogue: DialogueData

func _ready() -> void:
	if intro_dialogue == null:
		push_warning("IntroSequence has no intro_dialogue assigned -- starting timer immediately instead.")
		GameManager.start_timer()
		return

	# One-shot: only this first dialogue should trigger the timer start,
	# not any later conversations with other NPCs during play.
	GameManager.dialogue_finished.connect(_on_intro_finished, CONNECT_ONE_SHOT)

	# Deferred so this fires AFTER every node in the scene (including
	# DialogueBox) has finished its own _ready() and connected to the
	# dialogue_requested signal. Without this, if IntroSequence's _ready
	# runs before DialogueBox's, the signal fires with nobody listening.
	call_deferred("_start_intro")

func _start_intro() -> void:
	GameManager.open_dialogue(intro_dialogue)

func _on_intro_finished() -> void:
	GameManager.start_timer()
