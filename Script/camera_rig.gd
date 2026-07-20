extends Node3D

## CameraRig (Node3D) -- separate from Player, lives at the scene root
## alongside Player, Suspects, etc.
##
## CameraRig (Node3D)          <- this script
## └── Camera3D                <- mark this "Access as Unique Name" (right
##                                 click it in the Scene tree -> Access as
##                                 Unique Name) so Player can reference it
##                                 via %Camera3D without a direct node path.
##
## Setup for the Camera3D child:
## - Projection: Orthographic (Inspector -> Camera3D -> Projection)
## - Size: start around 10-14, tune to taste
## - Local Position: something like (0, 10, 10)
## - Local Rotation X: around -35 to -45 degrees (looks down at an angle)
## The exact position/rotation combo just needs to look isometric-ish and
## point back at local origin -- eyeball it in the editor, or select the
## Camera3D and use View -> "Preview" to check the framing live.

signal rotation_step_changed(step: int)

@export var target_path: NodePath          # assign your Player node here
@export var rotation_step_deg: float = 90.0
@export var rotation_speed: float = 8.0     # higher = snappier turn

@onready var _target: Node3D = get_node(target_path)

var _target_yaw: float = 0.0
var rotation_steps: int = 0                 # 0..3, which 90deg facing we're on

@onready var _camera: Camera3D = %Camera3D

func _ready() -> void:
	rotation.y = _target_yaw
	# Add to a group in code so Player can reliably find this camera via
	# get_tree().get_first_node_in_group("main_camera") without depending
	# on manual "Access as Unique Name" setup on the Player side.
	_camera.add_to_group("main_camera")
	add_to_group("main_camera_rig")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_MIDDLE:
		_target_yaw += deg_to_rad(rotation_step_deg)
		rotation_steps = (rotation_steps + 1) % 4
		rotation_step_changed.emit(rotation_steps)

func _process(delta: float) -> void:
	if _target:
		# Follow position only -- rotation is handled separately below.
		global_position = _target.global_position

	rotation.y = lerp_angle(rotation.y, _target_yaw, rotation_speed * delta)
