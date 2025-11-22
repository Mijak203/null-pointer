extends Control

@onready var ui: CanvasLayer = $UI

func _ready() -> void:
	ui.show_message("Dziękujemy za wybróbowanie naszej gry!", "Naciśnij spację aby kontynuować...", ui.ScreenType.WIN)
