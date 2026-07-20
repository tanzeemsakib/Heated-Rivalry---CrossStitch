extends Control

@export var closed_y: float = 648.0
@export var open_y: float = 468.0
@export var slide_speed: float = 10.0

var _target_y: float
@onready var timer_label: Label = $TimerLabel
@onready var suspect_list: VBoxContainer = $SuspectList
@onready var submit_button: Button = $SubmitButton

@onready var status_tab: Button = $"../StatusTab"

var _is_open: bool = false

func _ready() -> void:
	_target_y = closed_y
	position.y = closed_y
	GameManager.game_ended.connect(_on_game_ended)

func toggle() -> void:
	_is_open = not _is_open
	_target_y = open_y if _is_open else closed_y
	if _is_open:
		_refresh_suspect_list()

func _process(delta: float) -> void:
	position.y = lerp(position.y, _target_y, slide_speed * delta)
	if _is_open:
		_update_timer_label()

func _update_timer_label() -> void:
	var t: float = GameManager.time_left
	var minutes: int = int(t) / 60
	var seconds: int = int(t) % 60
	timer_label.text = "Time Left: %02d:%02d" % [minutes, seconds]

func _refresh_suspect_list() -> void:
	for child in suspect_list.get_children():
		child.queue_free()

	for suspect_node in get_tree().get_nodes_in_group("suspect"):
		var data: SuspectData = suspect_node.data
		var decision: String = GameManager.decisions.get(suspect_node, "")

		var status_text: String
		var status_color: Color
		match decision:
			"ally":
				status_text = "Ally"
				status_color = Color(0.2, 0.5, 0.2)
			"dummy":
				status_text = "Dummy"
				status_color = Color(0.7, 0.15, 0.15)
			_:
				status_text = "Unmarked"
				status_color = Color(0.4, 0.4, 0.4)

		var row := Label.new()
		row.text = "%s — %s" % [data.suspect_name, status_text]
		row.add_theme_color_override("font_color", status_color)
		suspect_list.add_child(row)

func _on_status_tab_pressed() -> void:
	toggle()
	
func _on_submit_button_pressed() -> void:
	GameManager.resolve_meeting()
	_is_open = false
	_target_y = closed_y
	position.y = closed_y
	
func _on_game_ended(_correct_count: int, _all_correct: bool) -> void:
	status_tab.visible = false
	_is_open = false
	_target_y = closed_y
	position.y = closed_y
