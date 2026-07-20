extends Node3D

@export var wall_south: Node3D
@export var wall_east: Node3D
@export var wall_north: Node3D
@export var wall_west: Node3D

var _walls: Array[Node3D]

func _ready() -> void:
	# Order matters: index must match CameraRig.rotation_steps (0..3)
	_walls = [wall_south, wall_east, wall_north, wall_west]
	call_deferred("_connect_to_rig")

func _connect_to_rig() -> void:
	var rig := get_tree().get_first_node_in_group("main_camera_rig")
	if rig:
		rig.rotation_step_changed.connect(_on_rotation_step_changed)
		_on_rotation_step_changed(rig.rotation_steps)
	else:
		push_warning("walls.gd: no node in group 'main_camera_rig' found")

func _on_rotation_step_changed(step: int) -> void:
	for i in _walls.size():
		if _walls[i]:
			_walls[i].visible = (i != step)
