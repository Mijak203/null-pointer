extends Node3D

# --- EXPORTS ---
@export var target: Node3D
@export var position_smooth_speed: float = 5.0
@export var rotation_smooth_speed: float = 8.0

# --- STATE ---
var camera_angle_offset: float = 0.0
var is_manual_control_active: bool = false
var current_rotation_tween: Tween = null
var is_following: bool = true

# --- CONSTANTS ---
const MANUAL_ROTATION_SPEED: float = 2.0
const QUARTER_TURN_RADIANS = PI / 2.0

# --- UTILITY ---

# Snaps a radian angle to the nearest 90-degree (PI/2) increment
func snap_angle_to_90(angle: float) -> float:
	var snapped_angle = round(angle / QUARTER_TURN_RADIANS) * QUARTER_TURN_RADIANS
	return snapped_angle

func stop_following_and_look_down():
	is_following = false
	
	var spring_arm = get_node_or_null("SpringArm3D")
	if spring_arm:
		var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.set_parallel(true)
		
		tween.tween_property(spring_arm, "rotation_degrees:x", -50.0, 2.0)
		
		var target_length = spring_arm.spring_length + 5.0
		tween.tween_property(spring_arm, "spring_length", target_length, 2.0)

# --- INITIALIZATION ---

func _ready():
	if target:
		if target.has_signal("gap_detected_ahead"):
			# Listen for the player detecting a gap
			target.gap_detected_ahead.connect(on_player_gap_detected)
		else:
			pass
			#print("ERROR: Camera target (%s) has no 'gap_detected_ahead' signal!" % target.name)

# --- SIGNAL HANDLERS ---

# Called by the 'cube.gd' signal. Auto-rotates the camera to face the gap.
func on_player_gap_detected(gap_position: Vector3):
	if is_manual_control_active:
			return
	
	#print("Camera: Gap target received: ", gap_position)
	
	var direction_to_gap = (gap_position - target.global_position).normalized()
	var player_forward = -target.global_transform.basis.z.normalized()
	

	var target_angle_abs = player_forward.signed_angle_to(-direction_to_gap, Vector3.UP)
	
	var snapped_target_angle = snap_angle_to_90(target_angle_abs)

	var angle_difference = snapped_target_angle - camera_angle_offset
	
	var two_pi = 2.0 * PI
	angle_difference = fmod(angle_difference + PI, two_pi) - PI
	
	var new_offset = camera_angle_offset + angle_difference
	
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "camera_angle_offset", new_offset, 0.5)

# --- PROCESS ---

func _process(delta):
	if not target:
			return

	var rotation_to_add = 0.0
	
	if Input.is_action_just_pressed("camera_right"):
		rotation_to_add = -QUARTER_TURN_RADIANS # -90 degrees
	elif Input.is_action_just_pressed("camera_left"):
		rotation_to_add = QUARTER_TURN_RADIANS  # +90 degrees
	
	if rotation_to_add != 0.0:
		if current_rotation_tween and current_rotation_tween.is_valid():
			current_rotation_tween.kill()
		
		is_manual_control_active = true 
		
		var new_offset = camera_angle_offset + rotation_to_add
		
		var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		current_rotation_tween = tween
		
		tween.tween_property(self, "camera_angle_offset", new_offset, 0.3)
		tween.finished.connect(func(): is_manual_control_active = false)

	# Smooth Position Following
	#global_position = global_position.lerp(target.global_position, delta * position_smooth_speed)
	
	if is_following:
		global_position = global_position.lerp(target.global_position, delta * position_smooth_speed)
	
	# Smooth Rotation Following
	var target_basis = target.global_transform.basis
	var offset_basis = Basis().rotated(Vector3.UP, camera_angle_offset)
	var final_target_basis = target_basis * offset_basis
	
	global_transform.basis = global_transform.basis.slerp(final_target_basis, delta * rotation_smooth_speed)
