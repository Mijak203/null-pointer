extends CanvasLayer

@onready var resume_btn: Button = $Control/ColorRect/VBoxContainer/ResumeButton
@onready var quit_btn: Button = $Control/ColorRect/VBoxContainer/QuitButton
@onready var menu_button: Button = $Control/ColorRect/VBoxContainer/MenuButton

@onready var control: Control = $Control


func _ready() -> void:
	resume_btn.pressed.connect(_on_resume_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	
	control.visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	control.visible = !control.visible
	
	get_tree().paused = control.visible

func _on_resume_pressed() -> void:
	
	toggle_pause()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	
	get_tree().quit()

func _on_menu_pressed():
	get_tree().paused = false 
	GameManager.change_scene_with_fade("res://components/main_menu/main_menu.tscn")
