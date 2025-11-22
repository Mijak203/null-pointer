extends Node3D

@onready var player: CharacterBody3D = $Cube
@onready var ui: CanvasLayer = $UI

const LEVEL_MUSIC = preload("res://assets/music/2 - Galactic Odyssey.mp3")

func _ready():
	player.player_won_level.connect(_on_player_won_level)
	AudioManager.play_music(LEVEL_MUSIC)

func _on_player_won_level():
	ui.show_message("Poziom ukończony!", "Naciśnij spację aby kontynuować...", ui.ScreenType.WIN)
