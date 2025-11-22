extends CanvasLayer

@onready var resume_btn: Button = $Control/ColorRect/VBoxContainer/ResumeButton
@onready var quit_btn: Button = $Control/ColorRect/VBoxContainer/QuitButton
@onready var menu_button: Button = $Control/ColorRect/VBoxContainer/MenuButton



func _ready() -> void:
	# Podłączamy sygnały
	resume_btn.pressed.connect(_on_resume_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	
	# Ukrywamy menu na starcie
	visible = false

func _input(event: InputEvent) -> void:
	# Sprawdzamy klawisz (np. ESC lub P)
	if event.is_action_pressed("ui_cancel"): # Domyślnie ESC
		toggle_pause()

func toggle_pause() -> void:
	# Przełączamy widoczność menu
	visible = !visible
	
	# ZATRZYMYWANIE GRY:
	# get_tree().paused zamraża wszystko, co ma Process Mode ustawione na 'Inherit' (domyślne)
	get_tree().paused = visible

func _on_resume_pressed() -> void:
	
	toggle_pause()

func _on_quit_pressed() -> void:
	# Zanim wyjdziemy, MUSIMY odblokować grę!
	# Inaczej Main Menu też będzie zamrożone.
	get_tree().paused = false
	
	# Zmiana sceny (użyj swojego GameManager lub change_scene)
	get_tree().quit()

func _on_menu_pressed():
	get_tree().paused = false 
	GameManager.change_scene_with_fade("res://components/main_menu/main_menu.tscn")
