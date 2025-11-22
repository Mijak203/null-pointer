extends Control

@onready var option_button_window_mode: OptionButton = $VBoxContainer/HBoxContainer/OptionButton
@onready var option_button_resolution: OptionButton = $VBoxContainer/HBoxContainer2/OptionButton
@onready var check_button: CheckButton = $VBoxContainer/HBoxContainer3/CheckButton

const WINDOW_MODE_ARRAY : Array[String] = [
	"Full-Screen (Exclusive)",
	"Window Mode",
	"Borderless Window"
]

const RESOLUTION_DICTIONARY: Dictionary = {
	"1152 x 648" : Vector2i(1152,648),
	"1280 x 720" : Vector2i(1280,720),
	"1366 x 768" : Vector2i(1366,768),
	"1600 x 900" : Vector2i(1600,900),
	"1920 x 1080" : Vector2i(1920,1080),
	"2560 x 1440" : Vector2i(2560,1440)
}

func _ready() -> void:
	add_window_mode_items()
	add_resolution_items()
	$VBoxContainer/Button.pressed.connect(_on_back_pressed)
	# Łączymy sygnały
	option_button_window_mode.item_selected.connect(_on_window_mode_selected)
	option_button_resolution.item_selected.connect(_on_resolution_selected)
	check_button.toggled.connect(_on_camera_enable)
	# OPCJONALNIE: Ustawienie przycisków na start, by pokazywały aktualny stan
	# (Możesz to usunąć, jeśli wolisz domyślne wartości 0)
	_update_ui_from_current_window_state()
	if check_button.toggled.is_connected(_on_camera_enable):
		print("Połączenie JEST aktywne.")
	else:
		print("BŁĄD: Połączenie nieudane!")
func add_window_mode_items() -> void:
	option_button_window_mode.clear()
	for window_mode in WINDOW_MODE_ARRAY:
		option_button_window_mode.add_item(window_mode)

func add_resolution_items() -> void:
	option_button_resolution.clear()
	for res_text in RESOLUTION_DICTIONARY:
		option_button_resolution.add_item(res_text)

func _on_window_mode_selected(index: int) -> void:
	# 1. Zapamiętujemy, na którym ekranie jest obecnie okno
	var current_screen = DisplayServer.window_get_current_screen()
	
	match index:
		0: # Full-Screen (Exclusive)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		1: # Window Mode (Zwykłe okno)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		2: # Borderless Window (Okno bez ramek)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		3: # Borderless Full-Screen (Okno na cały ekran bez ramek)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	
	# 2. Wymuszamy powrót na ten sam ekran (naprawa błędu przeskakiwania monitora)
	DisplayServer.window_set_current_screen(current_screen)

	# 3. Jeśli wróciliśmy do trybu okienkowego (indeks 1 lub 2), centrujemy okno
	if index == 1 or index == 2:
		# Czekamy klatkę, aż system przetworzy zmianę trybu, zanim wycentrujemy
		await get_tree().process_frame
		center_window()

func _on_resolution_selected(index: int) -> void:
	var selected_text = option_button_resolution.get_item_text(index)
	var target_size = RESOLUTION_DICTIONARY[selected_text]
	
	# Zmiana rozmiaru okna
	DisplayServer.window_set_size(target_size)
	
	# Jeśli jesteśmy w trybie okienkowym, wyśrodkuj okno po zmianie rozmiaru
	var mode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_WINDOWED:
		center_window()

# --- FUNKCJE POMOCNICZE ---

func center_window() -> void:
	# Pobieramy ID obecnego ekranu
	var screen_id = DisplayServer.window_get_current_screen()
	
	# Pobieramy pozycję (lewy górny róg) ekranu - ważne dla drugiego monitora!
	var screen_pos = DisplayServer.screen_get_position(screen_id)
	# Pobieramy rozmiar ekranu
	var screen_size = DisplayServer.screen_get_size(screen_id)
	# Pobieramy aktualny rozmiar naszego okna gry
	var window_size = DisplayServer.window_get_size()
	
	# Obliczamy środek: (StartEkranu) + (PołowaEkranu) - (PołowaOkna)
	var target_pos = screen_pos + (screen_size / 2) - (window_size / 2)
	
	# Ustawiamy pozycję
	DisplayServer.window_set_position(target_pos)

func _update_ui_from_current_window_state() -> void:
	# Ta funkcja ustawia OptionButtony tak, żeby pasowały do tego co jest przy starcie gry
	var current_mode = DisplayServer.window_get_mode()
	var is_borderless = DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS)
	
	# Proste mapowanie (możesz dostosować):
	if current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		option_button_window_mode.selected = 0
	elif current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		option_button_window_mode.selected = 3
	elif current_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		if is_borderless:
			option_button_window_mode.selected = 2
		else:
			option_button_window_mode.selected = 1



func _on_back_pressed():
	GameManager.change_scene_with_fade("res://components/main_menu/main_menu.tscn")
	

func _on_camera_enable(toggled_on: bool):
	print("Teraz działa! Nowy stan przycisku: ", toggled_on)
	
	GameManager.is_camera_enabled = toggled_on

	print("GameManager.is_camera_enabled = ", GameManager.is_camera_enabled)
