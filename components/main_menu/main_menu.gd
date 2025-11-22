extends Control

const MENU_MUSIC = preload("res://assets/music/1 - Astro Reverie.mp3")

func _ready():
	$VBoxContainer/PlayButton.pressed.connect(_on_play_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)
	$VBoxContainer/SettingsButton.pressed.connect(_on_setting_pressed)
	AudioManager.play_music(MENU_MUSIC)
	
func _on_play_pressed():
	GameManager.change_scene_with_fade("res://components/main_menu/tutorial.tscn")

func _on_quit_pressed():
	get_tree().quit()
func _on_setting_pressed():
	GameManager.change_scene_with_fade("res://components/main_menu/settings.tscn")
	
