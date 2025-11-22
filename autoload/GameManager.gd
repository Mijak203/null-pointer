extends Node

# A list of all level scenes
var levels = [
	"res://levels/level_1.tscn",
	"res://levels/level_4.tscn",
	"res://levels/level_3.tscn",
	"res://levels/level_5.tscn",
	"res://levels/level_2.tscn",
	"res://levels/level_6.tscn",
	"res://components/main_menu/end.tscn"
]

# Stores which level is currently loaded
var current_level_index = 0
var is_camera_enabled = false

var transition_layer: CanvasLayer
var color_rect: ColorRect

func _ready():
	transition_layer = CanvasLayer.new()
	transition_layer.layer = 100
	add_child(transition_layer)
	
	color_rect = ColorRect.new()
	color_rect.color = Color.BLACK
	color_rect.modulate.a = 0.0
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	transition_layer.add_child(color_rect)
	
	await get_tree().process_frame
	
	if get_tree().current_scene:
		var active_scene_path = get_tree().current_scene.scene_file_path
		
		var index = levels.find(active_scene_path)
		
		if index != -1:
			current_level_index = index
			print("You start from level nr: ", index, " (", active_scene_path, ")")

func change_scene_with_fade(path: String):
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, 0.8)
	await tween.finished
	
	get_tree().change_scene_to_file(path)
	
	var tween_in = create_tween()
	tween_in.tween_property(color_rect, "modulate:a", 0.0, 0.8)

func load_next_level():
	current_level_index += 1
	
	if current_level_index >= levels.size():
		print("YOU WON!")
		change_scene_with_fade("res://components/main_menu/main_menu.tscn")
		current_level_index = 0
	else:
		var next_scene_path = levels[current_level_index]
		change_scene_with_fade(next_scene_path)

func reload_level():
	var current_scene_path = levels[current_level_index]
	print(current_scene_path)
	change_scene_with_fade(current_scene_path)
