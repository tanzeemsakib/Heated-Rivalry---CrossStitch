extends Control
## Attach to your InterviewPanel Control node. Expected child nodes (adjust
## names to match your scene, then fix the @onready paths below):
##
## InterviewPanel (Control)
## ├── NameLabel (Label)                    -- claimed name (may be a lie)
## ├── ReasonLabel (Label)                  -- their stated reason, flavor only
## ├── ClaimColumn (VBoxContainer, draggable_card.gd)
## │   ├── ClaimNameLabel (Label, field_hotspot.gd: claim/name)
## │   ├── ClaimBadgeLabel (Label, field_hotspot.gd: claim/badge)
## │   ├── ClaimYearsLabel (Label, field_hotspot.gd: claim/years)
## │   └── ClaimPortraitRect (TextureRect, field_hotspot.gd: claim/photo)
## ├── MemoColumn (VBoxContainer, draggable_card.gd)
## │   ├── MemoNameLabel (Label, field_hotspot.gd: memo/name)
## │   ├── MemoBadgeLabel (Label, field_hotspot.gd: memo/badge)
## │   ├── MemoYearsLabel (Label, field_hotspot.gd: memo/years)
## │   └── MemoPortraitRect (TextureRect, field_hotspot.gd: memo/photo)
## ├── MarkAllyButton (Button)
## ├── MarkDummyButton (Button)
## ├── CloseButton (Button)
## ├── CorrelationStampLabel (Label)        -- shows match/mismatch result
## └── ReactionBubbleLabel (Label)          -- suspect's denial line on mismatch
##
## Also expects a sibling ColorRect named InterviewDim (under UI, alongside
## InterviewPanel) used as a full-screen dim backdrop while the panel is open.
##
## Field-checking flow: click a field on one card, then the corresponding
## field (same field_type, opposite card_side) on the other card. A valid
## pair triggers a correlation stamp. On mismatch, a reaction bubble also
## appears near the suspect's claimed portrait with a denial line pulled
## from SuspectData, specific to which field was mismatched. Mismatched-type
## pairs or re-clicking the same side just reset the selection.
##
## Escape key also closes the panel (see _unhandled_input below).
##
## Memo lookup is keyed by badge_id, not name -- a claimed badge_id with no
## matching memo entry at all is itself a tell (fabricated/stolen badge).
@export var memo: MemoData
@export var phone_player_portrait: Texture2D
@onready var name_label: Label = $NameLabel
@onready var reason_label: Label = $ReasonLabel
@onready var claim_column: Control = $ClaimColumn
@onready var claim_name_label: Label = $ClaimColumn/ClaimNameLabel
@onready var claim_badge_label: Label = $ClaimColumn/ClaimBadgeLabel
@onready var claim_years_label: Label = $ClaimColumn/ClaimYearsLabel
@onready var claim_portrait_rect: TextureRect = $ClaimColumn/ClaimPortraitRect
@onready var memo_column: Control = $MemoColumn
@onready var memo_name_label: Label = $MemoColumn/MemoNameLabel
@onready var memo_badge_label: Label = $MemoColumn/MemoBadgeLabel
@onready var memo_years_label: Label = $MemoColumn/MemoYearsLabel
@onready var memo_portrait_rect: TextureRect = $MemoColumn/MemoPortraitRect
@onready var mark_ally_button: Button = $MarkAllyButton
@onready var mark_dummy_button: Button = $MarkDummyButton
@onready var close_button: Button = $CloseButton
@onready var dim_backdrop: ColorRect = $"../InterviewDim"
@onready var correlation_stamp_label: Label = $CorrelationStampLabel
@onready var reaction_bubble_label: Label = $ReactionBubbleLabel
@onready var claim_password_label: Label = $ClaimPasswordSheet/ClaimPasswordLabel
@onready var memo_password_label: Label = $MemoPasswordSheet/MemoPasswordLabel
@onready var claim_parking_label: Label = $ClaimParkingSheet/ClaimParkingLabel
@onready var memo_parking_label: Label = $MemoPasswordSheet/MemoParkingLabel
@onready var phone_button: Button = $Phone/PhoneButton
var _current_suspect: Node = null
var _base_position: Vector2
var _selected_hotspot: Control = null

func _ready() -> void:
	visible = false
	dim_backdrop.visible = false
	pivot_offset = size / 2.0
	_base_position = position
	GameManager.interview_requested.connect(_on_interview_requested)
	mark_ally_button.pressed.connect(func(): _mark("ally"))
	mark_dummy_button.pressed.connect(func(): _mark("dummy"))
	close_button.pressed.connect(_close_panel)
	for hotspot in get_tree().get_nodes_in_group("field_hotspots"):
		hotspot.field_clicked.connect(_on_field_clicked)
	_populate_memo_lists()
	phone_button.pressed.connect(_on_phone_pressed)

func _play_open_juice() -> void:
	# Punches the panel in like a paper being slapped onto the desk --
	# starts small, rotated, and offset, then settles into place.
	scale = Vector2(0.85, 0.85)
	rotation_degrees = -6.0
	position = _base_position + Vector2(0, 40)
	modulate.a = 0.0

	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "rotation_degrees", -1.5, 0.18).set_trans(Tween.TRANS_BACK)
	t.tween_property(self, "position", _base_position, 0.18).set_trans(Tween.TRANS_BACK)
	t.tween_property(self, "modulate:a", 1.0, 0.12)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close_panel()

func _close_panel() -> void:
	# Backs out without recording a decision -- you can click this suspect
	# again later and still mark them.
	visible = false
	dim_backdrop.visible = false
	_clear_selection()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _clear_selection() -> void:
	if _selected_hotspot != null:
		_selected_hotspot.unhighlight()
	_selected_hotspot = null

func _on_field_clicked(hotspot: Control) -> void:
	if _selected_hotspot == null:
		_selected_hotspot = hotspot
		hotspot.highlight()
		return
	if hotspot == _selected_hotspot:
		return
	if hotspot.card_side == _selected_hotspot.card_side:
		# Re-selecting on the same side -- swap selection instead of comparing.
		_selected_hotspot.unhighlight()
		_selected_hotspot = hotspot
		hotspot.highlight()
		return
	if hotspot.field_type != _selected_hotspot.field_type:
		# Mismatched field types can't be compared -- reset.
		_clear_selection()
		return
	_run_correlation_check(_selected_hotspot, hotspot)
	_clear_selection()

func _run_correlation_check(claim_hotspot: Control, memo_hotspot: Control) -> void:
	if _current_suspect == null:
		return
	var data: SuspectData = _current_suspect.data
	if data == null or memo == null:
		return
	var field_type: String = claim_hotspot.field_type
	var truth: Dictionary = memo.true_facts.get(data.suspect_name, {})
	var matched: bool = false
	match field_type:
		"name":
			matched = memo.true_facts.has(data.suspect_name)
		"badge":
			matched = data.badge_id == truth.get("badge_id", "")
		"years":
			matched = data.years_at_company == int(truth.get("years", -999999))
		"photo":
			matched = data.portrait == truth.get("portrait", null)
		"password":
			matched = data.pc_password == truth.get("password", "")
		"parking":
			matched = data.parking_permit == truth.get("parking_permit", "")
	var stamp_pos: Vector2 = (claim_hotspot.global_position + memo_hotspot.global_position) / 2.0
	_show_correlation_stamp(matched, stamp_pos)
	if not matched:
		_show_reaction_bubble(field_type, data)

func _show_correlation_stamp(matched: bool, stamp_global_pos: Vector2) -> void:
	correlation_stamp_label.text = "CORRELATION CONFIRMED" if matched else "NO CORRELATION"
	correlation_stamp_label.modulate = Color(0.2, 0.7, 0.2, 1.0) if matched else Color(0.8, 0.15, 0.15, 1.0)
	correlation_stamp_label.global_position = stamp_global_pos - correlation_stamp_label.size / 2.0
	correlation_stamp_label.scale = Vector2(1.5, 1.5)
	correlation_stamp_label.rotation_degrees = randf_range(-8.0, 8.0)
	correlation_stamp_label.visible = true

	var t := create_tween()
	t.tween_property(correlation_stamp_label, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(0.9)
	t.tween_property(correlation_stamp_label, "modulate:a", 0.0, 0.3)
	t.tween_callback(func(): correlation_stamp_label.visible = false)

func _show_reaction_bubble(field_type: String, data: SuspectData) -> void:
	var line: String = ""
	match field_type:
		"name":
			line = data.denial_line_name
		"badge":
			line = data.denial_line_badge
		"years":
			line = data.denial_line_years
		"photo":
			line = data.denial_line_photo
		"password":
			line = data.denial_line_password
		"parking":
			line = data.denial_line_parking

	var dialogue_line := DialogueLine.new()
	dialogue_line.speaker = "npc"
	dialogue_line.text = line

	var dialogue_data := DialogueData.new()
	dialogue_data.npc_name = data.suspect_name
	dialogue_data.npc_portrait = data.portrait
	dialogue_data.lines = [dialogue_line]

	GameManager.dialogue_requested.emit(dialogue_data)

	var t := create_tween()
	t.tween_property(reaction_bubble_label, "modulate:a", 1.0, 0.15)
	t.parallel().tween_property(reaction_bubble_label, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(2.2)
	t.tween_property(reaction_bubble_label, "modulate:a", 0.0, 0.3)
	t.tween_callback(func(): reaction_bubble_label.visible = false)

func _on_interview_requested(suspect_node: Node) -> void:
	_current_suspect = suspect_node
	phone_button.disabled = GameManager.phone_called.get(suspect_node, false)
	var data: SuspectData = suspect_node.data
	claim_column.reset_position()
	memo_column.reset_position()
	_clear_selection()
	if data == null:
		# No SuspectData resource assigned yet on this suspect's Inspector
		# "Data" field -- shows placeholder text instead of crashing so you
		# can still test movement/clicking/UI popup before writing content.
		name_label.text = "(no data assigned)"
		reason_label.text = "Assign a SuspectData resource in the Inspector."
		claim_name_label.text = "Name: --"
		claim_badge_label.text = "Badge: --"
		claim_years_label.text = "Years: --"
		claim_portrait_rect.texture = null
		claim_password_label.text = "Password: --"
		claim_parking_label.text = "--"
		memo_name_label.text = "Name: --"
		memo_badge_label.text = "Badge: --"
		memo_years_label.text = "Years: --"
		memo_portrait_rect.texture = null
		visible = true
		dim_backdrop.visible = true
		_play_open_juice()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	name_label.text = data.suspect_name
	reason_label.text = "\"%s\"" % data.stated_reason
	# Left column: what this person is claiming right now
	claim_name_label.text = "Name: %s" % data.suspect_name
	claim_badge_label.text = "Badge: %s" % data.badge_id
	claim_years_label.text = "Years: %d" % data.years_at_company
	claim_portrait_rect.texture = data.portrait
	claim_password_label.text = "Password: %s" % data.pc_password
	claim_parking_label.text = data.parking_permit
	# Right column: what the leaked memo says the REAL person holding this
	# badge_id should have. If the memo has no entry for this claimed badge
	# at all, that's itself a huge tell -- a fabricated or stolen badge.
	if memo != null and memo.true_facts.has(data.suspect_name):
		var truth: Dictionary = memo.true_facts[data.suspect_name]
		memo_name_label.text = "Name: %s" % data.suspect_name
		memo_badge_label.text = "Badge: %s" % str(truth.get("badge_id", "?"))
		memo_years_label.text = "Years: %s" % str(truth.get("years", "?"))
		memo_portrait_rect.texture = truth.get("portrait", null)
	else:
		memo_name_label.text = "Name: NO RECORD"
		memo_badge_label.text = "Badge: NO RECORD"
		memo_years_label.text = "Years: NO RECORD"
		memo_portrait_rect.texture = null
	visible = true
	dim_backdrop.visible = true
	_play_open_juice()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _mark(decision: String) -> void:
	if _current_suspect == null:
		return
	GameManager.mark_decision(_current_suspect, decision)
	visible = false
	dim_backdrop.visible = false
	_clear_selection()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _populate_memo_lists() -> void:
	if memo == null:
		memo_password_label.text = "No records available."
		memo_parking_label.text = "No records available."
		return
	var pw_lines: Array = []
	var pk_lines: Array = []
	for suspect_name in memo.true_facts.keys():
		var truth: Dictionary = memo.true_facts[suspect_name]
		pw_lines.append("%s: %s" % [suspect_name, str(truth.get("password", "?"))])
		pk_lines.append("%s: %s" % [suspect_name, str(truth.get("parking_permit", "?"))])
	pw_lines.sort()
	pk_lines.sort()
	memo_password_label.text = "\n".join(pw_lines)
	memo_parking_label.text = "\n".join(pk_lines)
	
func _on_phone_pressed() -> void:
	if _current_suspect == null:
		return
	if GameManager.phone_called.get(_current_suspect, false):
		return
	var data: SuspectData = _current_suspect.data
	if data == null:
		return
	GameManager.phone_called[_current_suspect] = true
	phone_button.disabled = true
	_start_phone_call(data)

func _start_phone_call(data: SuspectData) -> void:
	var lines: Array[DialogueLine] = []

	var ask := DialogueLine.new()
	ask.speaker = "player"
	ask.text = "Hi, did %s leave for the office today?" % data.suspect_name
	lines.append(ask)

	var outcome := randi() % 3
	match outcome:
		0:
			var no_answer := DialogueLine.new()
			no_answer.speaker = "npc"
			no_answer.text = "..."
			lines.append(no_answer)
			var give_up := DialogueLine.new()
			give_up.speaker = "player"
			give_up.text = "(No answer. Must have missed the call.)"
			lines.append(give_up)
		1:
			var unsure := DialogueLine.new()
			unsure.speaker = "npc"
			unsure.text = "I'm honestly not sure -- I didn't see him leave."
			lines.append(unsure)
			var thanks1 := DialogueLine.new()
			thanks1.speaker = "player"
			thanks1.text = "Okay, thank you."
			lines.append(thanks1)
		2:
			var answer := DialogueLine.new()
			answer.speaker = "npc"
			answer.text = "Yes, he left for the office this morning." if not data.is_dummy else "No, he's been home all day."
			lines.append(answer)
			var thanks2 := DialogueLine.new()
			thanks2.speaker = "player"
			thanks2.text = "Thank you, bye."
			lines.append(thanks2)

	var dialogue_data := DialogueData.new()
	dialogue_data.npc_name = "%s's Relative" % data.suspect_name
	dialogue_data.npc_portrait = null
	dialogue_data.player_portrait = phone_player_portrait
	dialogue_data.lines = lines
	GameManager.dialogue_requested.emit(dialogue_data)

	if outcome == 2 and data.is_dummy:
		GameManager.dialogue_finished.connect(func():
			_show_phone_denial(data)
		, CONNECT_ONE_SHOT)

func _show_phone_denial(data: SuspectData) -> void:
	var line := DialogueLine.new()
	line.speaker = "npc"
	line.text = data.denial_line_phone

	var denial_data := DialogueData.new()
	denial_data.npc_name = data.suspect_name
	denial_data.npc_portrait = data.portrait
	denial_data.lines = [line]
	GameManager.dialogue_requested.emit(denial_data)
