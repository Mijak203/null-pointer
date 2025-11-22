extends Control

var slides = [
	{
		"text": "Witaj w świecie Null Zero! Jesteś zagubionym klockiem w cyfrowej otchłani.",
		"image": preload("res://assets/dexter.png")
	},
	{
		"text": "Twoim celem jest wpadnięcie do kwadratowej dziury. To Twój portal do domu.",
		"image": preload("res://assets/dexter.png") 
	},
	{
		"text": "STEROWANIE:\nUżywaj strzałek lub WASD, aby turlać klocek.",
		"image": preload("res://assets/dexter.png") 
	},
	{
		"text": "Uważaj na krawędzie! Jeden fałszywy ruch i spadasz w nicość.",
		"image": preload("res://assets/dexter.png") 
	},
	{
		"text": "Powodzenia! Niech fizyka będzie z Tobą.",
		"image": preload("res://assets/dexter.png") 
	}
]

var current_index = 0

@onready var content_container: Control = $VBoxContainer/Content
@onready var image_rect: TextureRect = $VBoxContainer/Content/Image
@onready var text_label: Label = $VBoxContainer/Content/Text
@onready var prev_btn: Button = $VBoxContainer/Content/PrevButton
@onready var next_btn: Button = $VBoxContainer/Content/NextButton
@onready var page_label: Label = $VBoxContainer/Navigation/PageIndicator
@onready var skip_btn: Button = $VBoxContainer/Navigation/SkipButton

func _ready():
	prev_btn.pressed.connect(_on_prev)
	next_btn.pressed.connect(_on_next)
	skip_btn.pressed.connect(_start_game)
	
	update_ui_state()

func change_slide_animated(direction: int):
	prev_btn.disabled = true
	next_btn.disabled = true
	
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(content_container, "modulate:a", 0.0, 0.2)
	
	await tween.finished
	
	current_index += direction
	update_ui_state()
	
	var tween_in = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_in.tween_property(content_container, "modulate:a", 1.0, 0.2)
	
	await tween_in.finished

func update_ui_state():
	var data = slides[current_index]
	
	text_label.text = data["text"]
	image_rect.texture = data["image"]
	
	page_label.text = str(current_index + 1) + " / " + str(slides.size())
	
	prev_btn.disabled = (current_index == 0)
	prev_btn.modulate.a = 0.5 if current_index == 0 else 1.0
	
	next_btn.disabled = false
	
	if current_index == slides.size() - 1:
		next_btn.text = "START!"
		next_btn.modulate = Color.GREEN
	else:
		next_btn.text = ">"
		next_btn.modulate = Color.WHITE

func _on_prev():
	if current_index > 0:
		change_slide_animated(-1)

func _on_next():
	if current_index < slides.size() - 1:
		change_slide_animated(1)
	else:
		_start_game()

func _start_game():
	GameManager.change_scene_with_fade("res://levels/level_test.tscn")
