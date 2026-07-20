extends Node
## Set this as an Autoload (Project Settings > Autoload) named "GameManager".
signal interview_requested(suspect: Node)
signal time_up
signal game_ended(correct_count: int, total_dummies_correct: bool)
signal dialogue_requested(dialogue: DialogueData)
signal dialogue_finished
@export var meeting_countdown_seconds: float = 240.0  # 4 minutes
var time_left: float = 0.0
var is_running: bool = false
# suspect_node -> "ally" or "dummy" or "" (undecided)
var decisions: Dictionary = {}
var phone_called: Dictionary = {}  # suspect_node -> true once called
func _ready() -> void:
	time_left = meeting_countdown_seconds
	# NOTE: no longer auto-starting here -- intro_sequence.gd calls
	# GameManager.start_timer() once the opening dialogue finishes.
func start_timer() -> void:
	is_running = true
func _process(delta: float) -> void:
	if not is_running:
		return
	time_left -= delta
	if time_left <= 0:
		time_left = 0
		is_running = false
		emit_signal("time_up")
		resolve_meeting()
func open_interview(suspect_node: Node) -> void:
	emit_signal("interview_requested", suspect_node)
	
func open_dialogue(dialogue: DialogueData) -> void:
	emit_signal("dialogue_requested", dialogue)	
func mark_decision(suspect_node: Node, decision: String) -> void:
	# decision should be "ally" or "dummy"
	decisions[suspect_node] = decision
var _is_resolved: bool = false
func resolve_meeting() -> void:
	if _is_resolved:
		return
	_is_resolved = true
	is_running = false
	var all_suspects := get_tree().get_nodes_in_group("suspect")
	var total := all_suspects.size()
	var correct := 0
	for suspect_node in all_suspects:
		var data: SuspectData = suspect_node.data
		var decision: String = decisions.get(suspect_node, "")
		var guessed_dummy: bool = decision == "dummy"
		if guessed_dummy == data.is_dummy:
			correct += 1
	var all_correct: bool = correct == total
	emit_signal("game_ended", correct, all_correct)
func reset() -> void:
	time_left = meeting_countdown_seconds
	decisions.clear()
	phone_called.clear()
	_is_resolved = false
	start_timer()
