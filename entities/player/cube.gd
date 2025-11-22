extends CharacterBody3D

func play_win_animation() -> void:
	var mat = mesh.get_active_material(0) as ShaderMaterial
	
	if mat:
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(mat, "shader_parameter/progress", 1.0, 1.5)
		
		var tween_lift = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween_lift.tween_property(mesh, "position:y", mesh.position.y + 2.0, 1.5)
		
		await tween.finished
		mesh.visible = false

func _ready():
	mesh.visible = true

	var mat = mesh.get_active_material(0)
	
	if mat is ShaderMaterial:
		mat.set_shader_parameter("progress", 0.0)
		mat.set_shader_parameter("dissolve_amount", 0.0)
		
	elif mat is StandardMaterial3D:
		var color = mat.albedo_color
		color.a = 1.0
		mat.albedo_color = color

# --- NODES ---
@onready var pivot: Node3D = $Pivot
@onready var mesh: MeshInstance3D = $Pivot/MeshInstance3D
@onready var gap_detector: RayCast3D = $GapDetector
@onready var camera_rig: Node3D = get_parent().get_node("CameraRig")

# --- STATE & PARAMETERS ---
enum State { STANDING, LYING_X, LYING_Z, FALLING }
var current_state: State = State.STANDING

var speed: float = 5.0
var unit_size: float = 1.0
var height_standing: float = 2.0
var height_lying: float = 1.0

# --- SIGNALS ---
signal gap_detected_ahead(gap_position: Vector3)
signal player_won_level
signal teleport
signal step_on_plate
# --- FLAGS ---
var rolling: bool = false
var is_level_won = false

# --- PUBLIC & UTILITY FUNCTIONS ---

func snap_to_grid_axis(direction: Vector3) -> Vector3:
	var flat_direction = Vector3(direction.x, 0, direction.z).normalized()
	
	var abs_x = abs(flat_direction.x)
	var abs_z = abs(flat_direction.z)
	
	const TOLERANCE = 0.05
	
	if abs_x > abs_z + TOLERANCE:
		if flat_direction.x > 0:
			return Vector3.RIGHT  # (1, 0, 0)
		else:
			return Vector3.LEFT   # (-1, 0, 0)
	elif abs_z > abs_x + TOLERANCE:
		if flat_direction.z > 0:
			return Vector3.BACK   # (0, 0, 1)
		else:
			return Vector3.FORWARD # (0, 0, -1)
	else:
		if flat_direction.z > 0:
			return Vector3.BACK
		else:
			return Vector3.FORWARD

# --- PHYSICS PROCESS (INPUT) ---

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_restart"):
		GameManager.reload_level()
				
	if rolling or current_state == State.FALLING:
		return
		
	if not camera_rig:
		pass

	var camera_basis = camera_rig.global_transform.basis
	
	var raw_forward = -camera_basis.z
	var raw_right = camera_basis.x
	
	raw_forward.y = 0
	raw_right.y = 0
	raw_forward = raw_forward.normalized()
	raw_right = raw_right.normalized()
	
	var target_direction = Vector3.ZERO
	
	if Input.is_action_just_pressed("go_forward"):
		target_direction = raw_forward
	elif Input.is_action_just_pressed("go_backward"):
		target_direction = -raw_forward
	elif Input.is_action_just_pressed("go_right"):
		target_direction = raw_right
	elif Input.is_action_just_pressed("go_left"):
		target_direction = -raw_right
	
	if target_direction != Vector3.ZERO:
		var final_roll_direction = snap_to_grid_axis(target_direction)
		
		if final_roll_direction != Vector3.ZERO:
			roll(final_roll_direction)

# --- GAME STATE: FALLING (LOSE) ---

func start_fall() -> void:
	if is_level_won or current_state == State.FALLING:
			return
	
	current_state = State.FALLING
	set_physics_process(false)
	
	if camera_rig.has_method("stop_following_and_look_down"):
		camera_rig.stop_following_and_look_down()
	
	var move_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	move_tween.set_parallel(true) 
	
	var fall_target_y: float = global_position.y - 2.0
	var fall_duration: float = 2.5
	
	move_tween.tween_property(self, "global_position:y", fall_target_y, fall_duration)
	
	#var random_axis = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	#var random_angle = randf_range(PI / 4, PI / 2)
	#move_tween.tween_property(mesh, "rotation", mesh.rotation + random_axis * random_angle, fall_duration)
	
	var fade_tween = create_tween()
	fade_tween.tween_interval(0.5)
	
	var mat = mesh.get_active_material(0)
	if mat is ShaderMaterial:
		fade_tween.tween_property(mat, "shader_parameter/progress", 1.0, 1.0)
	elif mat is StandardMaterial3D:
		fade_tween.tween_property(mat, "albedo_color:a", 0.0, 1.0)
	
	await fade_tween.finished
	
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		ui.show_message("You Fell!", "Press R to restart", ui.ScreenType.DEATH)

# --- GROUND & GAP CHECKS ---

# Checks if all support points for the current state are on the ground
func is_ground_stable(check_pos: Vector3, state_to_check: State) -> bool:
	var space = get_world_3d().direct_space_state
	var offsets: Array[Vector3] = []
	
	match state_to_check:
		State.STANDING:
			offsets.append(Vector3.ZERO)
		State.LYING_X:
			offsets.append(Vector3(height_standing / 2.0, 0, 0))
			offsets.append(Vector3(-height_standing / 2.0, 0, 0))
		State.LYING_Z:
			offsets.append(Vector3(0, 0, height_standing / 2.0))
			offsets.append(Vector3(0, 0, -height_standing / 2.0))
		_:
			return true
	
	for offset in offsets:
		var ray_start = check_pos + offset + Vector3.UP * 0.1
		var ray_end = check_pos + offset + Vector3.DOWN * 2
	
		var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end, collision_mask, [self])
		var result = space.intersect_ray(query)
	
		if result.is_empty():
			return false

	return true

# Checks if the block is balanced on an edge (only one half supported)
func is_half_stable(check_pos: Vector3, state_to_check: State) -> Dictionary:
	var space = get_world_3d().direct_space_state
	var offsets: Array[Vector3] = []
	var axis_dir = Vector3.ZERO

	match state_to_check:
		State.STANDING:
			return { "is_half": false, "fall_dir": Vector3.ZERO }

		State.LYING_X:
			offsets = [
				Vector3(unit_size / 2.0, 0, 0),
				Vector3(-unit_size / 2.0, 0, 0)
			]
			axis_dir = Vector3.RIGHT

		State.LYING_Z:
			offsets = [
				Vector3(0, 0, unit_size / -2.0),
				Vector3(0, 0, -unit_size / -2.0)
			]
			axis_dir = Vector3.FORWARD

		_:
			return { "is_half": false, "fall_dir": Vector3.ZERO }

	var supports: Array[bool] = []

	for offset in offsets:
		var ray_start = check_pos + offset + Vector3.UP * 0.1
		var ray_end = check_pos + offset + Vector3.DOWN * 2
		var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end, collision_mask, [self])
		var result = space.intersect_ray(query)
		supports.append(!result.is_empty())

	if supports[0] and supports[1]:
		return { "is_half": false, "fall_dir": Vector3.ZERO } # Fully stable
	elif not supports[0] and not supports[1]:
		return { "is_half": false, "fall_dir": Vector3.ZERO } # No ground (handled by is_ground_stable)
	else:
		# Only one side has ground
		var fall_dir = (-axis_dir if supports[0] else axis_dir)
		return { "is_half": true, "fall_dir": fall_dir }

# Scans nearby tiles for gaps and emits a signal for the camera to look at
func is_gap_ahead(check_pos: Vector3, state_to_check: State):
	var space = get_world_3d().direct_space_state
	var block_contact_points: Array[Vector3] = []
	
	match state_to_check:
		State.STANDING:
			block_contact_points.append(Vector3.ZERO)
		State.LYING_X:
			block_contact_points.append(Vector3(height_standing / 2.0, 0, 0))
			block_contact_points.append(Vector3(-height_standing / 2.0, 0, 0))
		State.LYING_Z:
			block_contact_points.append(Vector3(0, 0, height_standing / 2.0))
			block_contact_points.append(Vector3(0, 0, -height_standing / 2.0))
		_:
			return

	var tile_check_offsets: Array[Vector3] = [
		Vector3(unit_size, 0, 0), Vector3(-unit_size, 0, 0), 
		Vector3(0, 0, unit_size), Vector3(0, 0, -unit_size),
		Vector3(unit_size, 0, unit_size), Vector3(unit_size, 0, -unit_size), 
		Vector3(-unit_size, 0, unit_size), Vector3(-unit_size, 0, -unit_size)
	]

	for tile_offset in tile_check_offsets:
		var tile_center = check_pos + tile_offset

		for contact_point in block_contact_points:
			var ray_start = tile_center + contact_point + Vector3.UP * 0.1
			var ray_end = tile_center + contact_point + Vector3.DOWN * 2
		
			var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end, collision_mask, [self])
			var result = space.intersect_ray(query)
		
			if result.is_empty():
				var gap_coord = tile_center + Vector3.UP * 0.5 
				gap_detected_ahead.emit(gap_coord)
				
				return 

func soft_gravity(check_pos: Vector3, state_to_check: State) -> Dictionary:
	var space = get_world_3d().direct_space_state
	var offsets: Array[Vector3] = []
	var axis_dir = Vector3.ZERO

	match state_to_check:
		State.STANDING:
			return { "is_half": false, "fall_dir": Vector3.ZERO }

		State.LYING_X:
			offsets = [
				Vector3(unit_size / 2.0, 0, 0),
				Vector3(-unit_size / 2.0, 0, 0)
			]
			axis_dir = Vector3.RIGHT

		State.LYING_Z:
			offsets = [
				Vector3(0, 0, unit_size / -2.0),
				Vector3(0, 0, -unit_size / -2.0)
			]
			axis_dir = Vector3.FORWARD

		_:
			return { "is_half": false, "fall_dir": Vector3.ZERO }

	var supports: Array[bool] = []

	for offset in offsets:
		var ray_start = check_pos + offset + Vector3.UP * 0.1
		var ray_end = check_pos + offset + Vector3.DOWN * 0.8
		var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end, collision_mask, [self])
		var result = space.intersect_ray(query)
		supports.append(!result.is_empty())

	if supports[0] and supports[1]:
		return { "is_half": false, "fall_dir": Vector3.ZERO } # Fully stable
	elif not supports[0] and not supports[1]:
		return { "is_half": false, "fall_dir": Vector3.ZERO } # No ground (handled by is_ground_stable)
	else:
		# Only one side has ground
		var fall_dir = (-axis_dir if supports[0] else axis_dir)
		return { "is_half": true, "fall_dir": fall_dir }

# --- HELPER FUNCTIONS FOR ROLL LOGIC ---

# Handles toppling down a step (Soft Gravity Logic)
func _handle_step_down() -> void:
	var half_state2 = soft_gravity(global_position, current_state)

	if half_state2.is_half:
		var fall_dir: Vector3 = half_state2.fall_dir
		var fall_axis = fall_dir.cross(Vector3.DOWN).normalized()
		var pivot_offset = Vector3.ZERO

		# Local pivot adjustment
		pivot.position += pivot_offset
		mesh.position -= pivot_offset

		# Animate topple
		var tweenFall = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tweenFall.tween_property(pivot, "transform", pivot.transform.rotated_local(fall_axis, PI / 2), 1 / speed)
		await tweenFall.finished

		# Update X/Z position (move to next tile center)
		position += fall_dir * (unit_size / 2.0)

		# Check ground height for landing
		var space = get_world_3d().direct_space_state
		var ray_query = PhysicsRayQueryParameters3D.create(
			global_position + Vector3.UP * 2.0, 
			global_position + Vector3.DOWN * 10.0, 
			collision_mask, [self]
		)
		var result = space.intersect_ray(ray_query)
		
		# Snap Y to ground or drop 1 unit if hole
		if result:
			position.y = result.position.y
		else:
			position.y -= 1.0

		# Reset Mesh/Pivot to STANDING
		var b2 = mesh.global_transform.basis
		pivot.transform = Transform3D.IDENTITY
		pivot.position = Vector3.ZERO
		current_state = State.STANDING
		mesh.position = Vector3(0, height_standing / 2.0, 0)
		mesh.global_transform.basis = b2

# Handles standard falling if floating above ground
func _apply_gravity() -> void:
	var space = get_world_3d().direct_space_state
	var start = global_position + Vector3.UP * (unit_size * 2)
	var end = global_position + Vector3.DOWN * unit_size
	
	var query = PhysicsRayQueryParameters3D.create(start, end, collision_mask, [self])
	var result = space.intersect_ray(query)
	
	if result:
		var ground_y = result.position.y
		if (global_position.y - ground_y) > 0.05:
			var target = Vector3(global_position.x, ground_y, global_position.z)
			var t = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			t.tween_property(self, "global_position", target, 0.3)
			await t.finished

# Returns true if level is won
func _check_win() -> bool:
	var space = get_world_3d().direct_space_state
	var start = global_position + Vector3.UP * 2.0
	var end = global_position + Vector3.DOWN * unit_size
	var goal_mask = 4
	
	var query = PhysicsRayQueryParameters3D.create(start, end, goal_mask, [self])
	query.collide_with_areas = true
	
	if space.intersect_ray(query) and current_state == State.STANDING:
		is_level_won = true
		set_physics_process(false)
		await play_win_animation()
		player_won_level.emit()
		return true
	return false

# Returns true if player died
func _check_loss() -> bool:
	var half_state = is_half_stable(global_position, current_state)
	
	if half_state.is_half:
		start_fall()
		return true
	elif not is_ground_stable(global_position, current_state):
		start_fall()
		return true
	
	return false

# --- ROLLING LOGIC (THE CORE GAME) ---

func roll(dir: Vector3) -> void:
	if rolling: return

	# 1. Calculate roll parameters
	var pivot_offset_dist := 0.0
	var travel_distance := 0.0
	var new_state := current_state
	var new_height := 0.0

	match current_state:
		State.STANDING:
			pivot_offset_dist = unit_size / 2.0; travel_distance = unit_size * 1.5; new_height = height_lying
			new_state = State.LYING_X if dir.x != 0 else State.LYING_Z
		State.LYING_X:
			if dir.x != 0:
				pivot_offset_dist = unit_size; travel_distance = unit_size * 1.5; new_state = State.STANDING; new_height = height_standing
			else:
				pivot_offset_dist = unit_size / 2.0; travel_distance = unit_size; new_state = State.LYING_X; new_height = height_lying
		State.LYING_Z:
			if dir.z != 0:
				pivot_offset_dist = unit_size; travel_distance = unit_size * 1.5; new_state = State.STANDING; new_height = height_standing
			else:
				pivot_offset_dist = unit_size / 2.0; travel_distance = unit_size; new_state = State.LYING_Z; new_height = height_lying

	# 2. Wall Collision Check
	var space = get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(mesh.global_position, mesh.global_position + dir * travel_distance, collision_mask, [self])
	if space.intersect_ray(ray): return

	# 3. Animate Roll
	rolling = true
	pivot.translate(dir * pivot_offset_dist)
	mesh.global_translate(-dir * pivot_offset_dist)

	var axis = dir.cross(Vector3.DOWN)
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(pivot, "transform", pivot.transform.rotated_local(axis, PI / 2), 1 / speed)
	await tween.finished

	# 4. Update Position & State
	position += dir * travel_distance
	var b = mesh.global_transform.basis
	pivot.transform = Transform3D.IDENTITY
	mesh.position = Vector3(0, new_height / 2.0, 0)
	mesh.global_transform.basis = b
	current_state = new_state
	
	is_gap_ahead(global_position, current_state)

	# --- POST-ROLL PHYSICS & LOGIC ---
	
	# 5. Check if we need to step down to a lower level
	await _handle_step_down()
	
	# 6. Apply standard gravity (in case we are floating)
	await _apply_gravity()
	check_for_portal()
	check_for_plate()
	# 7. Check Win/Lose conditions
	if await _check_win(): return
	if _check_loss(): return
	
	rolling = false




func check_for_portal():
	var space = get_world_3d().direct_space_state
	var fall_ray_start = global_position + Vector3.UP * (unit_size * 2) 
	var fall_ray_end = global_position + Vector3.DOWN * unit_size 
	var teleport_collision_mask: int = 8
	var teleport_query = PhysicsRayQueryParameters3D.create(
		fall_ray_start,
		fall_ray_end,
		teleport_collision_mask, 
		[self]
	)
	teleport_query.collide_with_areas = true

	var teleport_check = space.intersect_ray(teleport_query)
	#print("Win Check:", win_check)
	if teleport_check and current_state == State.STANDING:
		teleport.emit(teleport_check.collider.name)


func check_for_plate():
	
	var space = get_world_3d().direct_space_state
	var fall_ray_start = global_position + Vector3.UP * (unit_size * 2) 
	var fall_ray_end = global_position + Vector3.DOWN * unit_size 
	var plate_collision_mask: int = 32
	var plate_query = PhysicsRayQueryParameters3D.create(
		fall_ray_start,
		fall_ray_end,
		plate_collision_mask, 
		[self]
	)
	plate_query.collide_with_areas = true

	var plate_check = space.intersect_ray(plate_query)
	#print("Win Check:", win_check)
	if plate_check and current_state == State.STANDING:
		print("cos")
		step_on_plate.emit()
	
