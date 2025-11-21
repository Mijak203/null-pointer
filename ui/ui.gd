extends CanvasLayer

# --- NODES ---
@onready var label: Label = $Label
@onready var color_rect: ColorRect = $ColorRect

# --- STATE ---
enum ScreenType { 
	NONE,
	DEATH,
	WIN
}

var current_screen_type = ScreenType.NONE

# --- CORE FUNCTION ---

# Displays a message screen (e.g., Win/Lose) with a fade-in animation
func show_message(title: String, subtitle: String, type: ScreenType):
	label.text = title
	current_screen_type = type
	
	# Define the target color based on the message type
	var target_font_color = Color.WHITE
	match type:
		ScreenType.WIN:
			target_font_color = Color("#60FF80")
		ScreenType.DEATH:
			target_font_color = Color("#FF6060")
	
	var target_shadow_color = Color(0, 0, 0, 0.745) 
	visible = true
	
	# Instantly set the final target colors
	label.label_settings.font_color = target_font_color
	label.label_settings.shadow_color = target_shadow_color

	# Use 'modulate' to hide everything (white with 0 alpha)
	label.modulate = Color(1, 1, 1, 0) 
	color_rect.modulate = Color(0, 0, 0, 0)

	# Create the fade-in animation
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(color_rect, "modulate:a", 0.7, 0.5)
	tween.tween_property(label, "modulate", Color(1, 1, 1, 1), 0.5) 
	
	await tween.finished
	
	await get_tree().create_timer(0.5).timeout
	label.text = subtitle

# --- INPUT HANDLING ---

func _process(delta):
	if not visible:
		return

	# Check for input based on which screen is shown
	match current_screen_type:
		ScreenType.DEATH:
			if Input.is_action_just_pressed("ui_restart"):
				GameManager.reload_level()
		
		ScreenType.WIN:
			if Input.is_action_just_pressed("ui_accept"):
				visible = false
				current_screen_type = ScreenType.NONE
				GameManager.load_next_level()
