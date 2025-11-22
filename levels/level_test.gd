extends Node3D

@onready var player: CharacterBody3D = $Cube
@onready var ui: CanvasLayer = $UI

func _ready():
	player.player_won_level.connect(_on_player_won_level)

func _on_player_won_level():
	ui.show_message("Level Complete!", "Press Space to continue", ui.ScreenType.WIN)
