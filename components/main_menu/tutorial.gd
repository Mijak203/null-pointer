extends Control

var slides = [
	{
		"text": "KONTEKST: BŁĄD KRYTYCZNY\n\nJesteś anomalią uwięzioną za cyfrową zasłoną. \nTwoje zadanie: przełamać barierę systemu i uniknąć usunięcia.",
		"image": preload("res://components/main_menu/img/img1.png")
	},
	{
		"text": "CEL: PORT WYJŚCIA\n\nDotrzyj do Portu Wyjścia – to Twój 'Backdoor'. Zrób to zanim zostaniesz usunięty!",
		"image": preload("res://components/main_menu/img/img2.png")
	},
	{
		"text": "STEROWANIE: RUCH\n\nUżyj [WSAD] lub STRZAŁEK, by manewrować po sektorach pamięci.\nKażdy ruch musi być pewny. Krawędź mapy to granica danych – nie spadnij.",
		"image": preload("res://components/main_menu/img/img3.png")
	},
	{
		"text": "STEROWANIE: KAMERA\n\nPerspektywa bywa myląca. Użyj [Q] i [E], aby obracać widok.\nCzasem to jedyny sposób, by dostrzec barierę lub ukrytą za nią drogę.",
		"image": preload("res://components/main_menu/img/img4.png")
	},
	{
		"text": "PRZESZKODA: FIREWALL\n\nCzerwone ściany to aktywne blokady firewall. Nie siłuj się z nimi.\nZnajdź i aktywuj PRZYCISK na planszy, by dezaktywować zabezpieczenia.",
		"image": preload("res://components/main_menu/img/img5.png")
	},
	{
		"text": "NARZĘDZIE: TELEPORT\n\nSektory są rozłączone wielką przepaścią?\nWejdź na relokator pamięci, aby natychmiast przeskoczyć barierę odległości bajtów.",
		"image": preload("res://components/main_menu/img/img6.png")
	},
	{
		"text": "ZADANIE GŁÓWNE: PRZEŁAM BARIERĘ\n\nMigoczące pola to GLITCH. System ich nie widzi, ale Ty tak.\nZnajdz przycisk i aktywuj glitch, by przejść przez barierę danych.",
		"image": preload("res://components/main_menu/img/img7.png")
	},
	{
		"text": "STATUS: GOTOWY\n\nZnasz już zasady. Teraz czas je złamać.\nPrzełam barierę i uciekaj z systemu. Powodzenia, Anomalio.",
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
		next_btn.modulate = Color.WHITE
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
	GameManager.change_scene_with_fade("res://levels/level_1.tscn")
