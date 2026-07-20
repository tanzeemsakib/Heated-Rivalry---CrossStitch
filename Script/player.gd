extends CharacterBody3D
## Click-to-move setup with a fixed isometric-ish camera and a single
## always-billboarded front-view sprite (Billboard: Y-Billboard is ON).
##
## Player (CharacterBody3D)              <- this script
## ├── CollisionShape3D
## └── AnimatedSprite3D                  <- name it exactly "AnimatedSprite3D"
##
## Left click: clicking a suspect walks toward them (if out of range) and
## auto-interacts once within interact_distance. Clicking floor walks there
## and spawns a fading click marker. Mouse hover over a suspect calls
## set_highlighted(true/false) on them if they implement it.

@export var speed: float = 4.0
@export var click_ray_length: float = 50.0       # max raycast distance (was "interact_range")
@export var interact_distance: float = 2.5       # how close player must be to auto-interact
@export var arrival_distance: float = 0.3        # how close counts as "arrived" for plain movement
@export var idle_animation_name: String = "default"
@export var walk_animation_name: String = "moving"
@export var footstep_interval: float = 0.4
@onready var footstep_player: AudioStreamPlayer3D = $FootstepPlayer
var _footstep_timer: float = 0.0

var camera: Camera3D
@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D

var _move_target: Vector3 = Vector3.ZERO
var _has_target: bool = false
var _pending_interact_target: Node = null
var _hovered_suspect: Node = null

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_find_camera()

func _find_camera() -> void:
	camera = get_tree().get_first_node_in_group("main_camera")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click(event.position)
	elif event is InputEventMouseMotion:
		_handle_hover(event.position)

func _raycast_from_screen(screen_pos: Vector2) -> Dictionary:
	if camera == null:
		_find_camera()
	if camera == null:
		push_error("No camera found in group 'main_camera'. Check CameraRig setup.")
		return {}
	var space_state := get_world_3d().direct_space_state
	var from := camera.project_ray_origin(screen_pos)
	var to := from + camera.project_ray_normal(screen_pos) * click_ray_length
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collision_mask = 0b011  # layers 1 (floor) + 2 (suspects) only -- excludes layer 3 (walls)
	return space_state.intersect_ray(query)

func _handle_click(screen_pos: Vector2) -> void:
	var result := _raycast_from_screen(screen_pos)
	if result.is_empty():
		return

	if result.collider.is_in_group("suspect") or result.collider.is_in_group("npc"):
		var dist := global_position.distance_to(result.collider.global_position)
		if dist <= interact_distance:
			# Already close enough -- interact immediately, no walking needed.
			_pending_interact_target = null
			_has_target = false
			if result.collider.has_method("interact"):
				result.collider.interact()
		else:
			# Too far -- walk toward them, auto-interact once in range.
			_pending_interact_target = result.collider
			_move_target = result.collider.global_position
			_move_target.y = global_position.y
			_has_target = true
		return

	# Floor click: clear any pending interaction, walk there, show marker.
	_pending_interact_target = null
	_move_target = result.position
	_move_target.y = global_position.y
	_has_target = true
	_spawn_click_marker(result.position)

func _handle_hover(screen_pos: Vector2) -> void:
	var result := _raycast_from_screen(screen_pos)
	var new_hover: Node = null

	if not result.is_empty():
		if result.collider.is_in_group("suspect") or result.collider.is_in_group("npc"):
			new_hover = result.collider

	if new_hover != _hovered_suspect:
		if _hovered_suspect and is_instance_valid(_hovered_suspect) and _hovered_suspect.has_method("set_highlighted"):
			_hovered_suspect.set_highlighted(false)

		_hovered_suspect = new_hover

		if _hovered_suspect and _hovered_suspect.has_method("set_highlighted"):
			_hovered_suspect.set_highlighted(true)

func _spawn_click_marker(pos: Vector3) -> void:
	var marker := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.4
	mesh.bottom_radius = 0.4
	mesh.height = 0.02
	mesh.radial_segments = 24
	marker.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.9, 0.7, 0.3, 0.85)
	mat.no_depth_test = true  # draws on top of floor, avoids z-fighting
	marker.material_override = mat

	get_tree().current_scene.add_child(marker)
	marker.global_position = pos + Vector3(0, 0.02, 0)
	marker.scale = Vector3(0.4, 1.0, 0.4)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(marker, "scale", Vector3(1.8, 1.0, 1.8), 0.35)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.35)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(marker.queue_free)

func _physics_process(_delta: float) -> void:
	if not _has_target:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		_stop_walking()
		return

	# If we're walking toward a suspect to interact, trigger as soon as in range
	# -- don't require reaching arrival_distance, which may be tighter/awkward
	# against their collision shape.
	if _pending_interact_target != null and is_instance_valid(_pending_interact_target):
		var d := global_position.distance_to(_pending_interact_target.global_position)
		if d <= interact_distance:
			_trigger_pending_interact()
			return

	var to_target := _move_target - global_position
	to_target.y = 0
	if to_target.length() <= arrival_distance:
		_has_target = false
		_pending_interact_target = null
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		_stop_walking()
		return

	var direction := to_target.normalized()
	_play_walking()
	_footstep_timer += _delta
	if _footstep_timer >= footstep_interval:
		_footstep_timer = 0.0
		footstep_player.pitch_scale = randf_range(0.9, 1.1)
		footstep_player.play()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	move_and_slide()

func _trigger_pending_interact() -> void:
	var target := _pending_interact_target
	_pending_interact_target = null
	_has_target = false
	velocity.x = 0
	velocity.z = 0
	move_and_slide()
	_stop_walking()
	if target and is_instance_valid(target) and target.has_method("interact"):
		target.interact()

func _play_walking() -> void:
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(walk_animation_name):
		if sprite.animation != walk_animation_name or not sprite.is_playing():
			sprite.play(walk_animation_name)
	else:
		push_warning("Missing animation: " + walk_animation_name)

func _stop_walking() -> void:
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(idle_animation_name):
		if sprite.animation != idle_animation_name or not sprite.is_playing():
			sprite.play(idle_animation_name)
	else:
		push_warning("Missing animation: " + idle_animation_name)
