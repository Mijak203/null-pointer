extends Node

# A list of all level scenes
var levels = [
	#"res://levels/level_test.tscn",
	#"res://levels/level_1.tscn",
	#"res://levels/level_1.tscn",
	"res://components/main_menu/end.tscn"
]

# Stores which level is currently loaded
var current_level_index = 0
var is_camera_enabled = false

# Warstwa UI do przejść
var transition_layer: CanvasLayer
var color_rect: ColorRect

func _ready():
	# 1. Tworzymy warstwę UI w kodzie, żeby była zawsze na wierzchu
	transition_layer = CanvasLayer.new()
	transition_layer.layer = 100 # Bardzo wysoka warstwa, nad wszystkim innym
	add_child(transition_layer)
	
	# 2. Tworzymy czarny prostokąt
	color_rect = ColorRect.new()
	color_rect.color = Color.BLACK
	color_rect.modulate.a = 0.0 # Na początku przezroczysty
	
	# Ustawiamy go na cały ekran
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Wyłączamy przechwytywanie myszki, żeby nie blokował gry gdy jest przezroczysty
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	
	transition_layer.add_child(color_rect)

# --- FUNKCJA GŁÓWNA DO ZMIANY SCEN ---
func change_scene_with_fade(path: String):
	# 1. FADE OUT (Ściemnianie)
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, 0.8) # 0.5 sekundy do czerni
	await tween.finished
	
	# 2. ZMIANA SCENY (pod osłoną nocy)
	get_tree().change_scene_to_file(path)
	
	# 3. FADE IN (Rozjaśnianie)
	var tween_in = create_tween()
	tween_in.tween_property(color_rect, "modulate:a", 0.0, 0.8) # 0.5 sekundy do gry

# Loads the next level in the 'levels' array
func load_next_level():
	current_level_index += 1
	
	if current_level_index >= levels.size():
		print("YOU WON!")
		change_scene_with_fade("res://components/main_menu/main_menu.tscn")
		current_level_index = 0
	else:
		var next_scene_path = levels[current_level_index]
		change_scene_with_fade(next_scene_path)

# Called by the UI (e.g. 'R' key) to restart
func reload_level():
	var current_scene_path = levels[current_level_index]
	change_scene_with_fade(current_scene_path)
