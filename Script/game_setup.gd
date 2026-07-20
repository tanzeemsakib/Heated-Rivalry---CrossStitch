extends Node
## Attach to a Node under Main. Runs once at game start: gives every
## suspect a runtime copy of their data, baselines their claimed fields to
## match the memo truth exactly, then randomly assigns exactly 2 dummies
## and mutates exactly one claimed field per dummy. Nothing here touches
## the .tres files on disk.

@export var memo: MemoData
@export var decoy_portraits: Array[Texture2D] = []
const MUTATABLE_FIELDS := ["name", "badge", "years", "photo", "password", "parking"]

func _ready() -> void:
	call_deferred("_setup_suspects")

func _setup_suspects() -> void:
	GameManager.reset()
	if memo == null:
		push_error("GameSetup: no MemoData assigned.")
		return

	var suspects := get_tree().get_nodes_in_group("suspect")
	if suspects.size() < 2:
		push_warning("GameSetup: need at least 2 suspects to assign dummies.")
		return

	var baseline_names: Dictionary = {}  # suspect_node -> original suspect_name

	for suspect_node in suspects:
		var data: SuspectData = suspect_node.data
		if data == null:
			continue
		data = data.duplicate()
		suspect_node.data = data
		baseline_names[suspect_node] = data.suspect_name

	for suspect_node in suspects:
		var data: SuspectData = suspect_node.data
		if data == null:
			continue
		var truth: Dictionary = memo.true_facts.get(baseline_names[suspect_node], {})
		if truth.is_empty():
			continue
		data.badge_id = str(truth.get("badge_id", data.badge_id))
		data.years_at_company = int(truth.get("years", data.years_at_company))
		data.pc_password = str(truth.get("password", data.pc_password))
		data.parking_permit = str(truth.get("parking_permit", data.parking_permit))
		data.is_dummy = false

	var pool := suspects.duplicate()
	pool.shuffle()
	var dummies: Array = pool.slice(0, 2)

	for suspect_node in dummies:
		var data: SuspectData = suspect_node.data
		if data == null:
			continue
		data.is_dummy = true
		var field: String = MUTATABLE_FIELDS[randi() % MUTATABLE_FIELDS.size()]
		match field:
			"name":
				data.suspect_name = _mutate_name(data.suspect_name)
			"badge":
				data.badge_id = _mutate_chars(data.badge_id)
			"years":
				data.years_at_company = _mutate_years(data.years_at_company)
			"password":
				data.pc_password = _mutate_chars(data.pc_password)
			"parking":
				data.parking_permit = _mutate_chars(data.parking_permit)
			"photo":
				_mutate_memo_photo(baseline_names[suspect_node])

func _mutate_name(original: String) -> String:
	if original.length() < 2:
		return original + "x"
	var idx := randi() % (original.length() - 1)
	var a := original[idx]
	var b := original[idx + 1]
	return original.substr(0, idx) + b + a + original.substr(idx + 2)

func _mutate_chars(original: String) -> String:
	if original.length() == 0:
		return original
	var idx := randi() % original.length()
	var ch := original[idx]
	var new_ch: String
	if ch.is_valid_int():
		var d := int(ch)
		new_ch = str((d + 1 + randi() % 8) % 10)
	else:
		var letters := "abcdefghijklmnopqrstuvwxyz"
		var lower := ch.to_lower()
		var pool := letters.replace(lower, "")
		new_ch = pool[randi() % pool.length()]
		if ch == ch.to_upper() and ch != ch.to_lower():
			new_ch = new_ch.to_upper()
	return original.substr(0, idx) + new_ch + original.substr(idx + 1)

func _mutate_years(original: int) -> int:
	var delta := 1 + randi() % 5
	if randi() % 2 == 0:
		delta = -delta
	var result := original + delta
	if result < 0:
		result = original + abs(delta)
	return result

func _mutate_memo_photo(suspect_name: String) -> void:
	if decoy_portraits.is_empty():
		return
	if not memo.true_facts.has(suspect_name):
		return
	memo.true_facts[suspect_name]["portrait"] = decoy_portraits[randi() % decoy_portraits.size()]
