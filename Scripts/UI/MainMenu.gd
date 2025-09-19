extends Control

@onready var title_label = $UI/TitleLabel
@onready var start_button = $UI/StartButton
@onready var quit_button = $UI/QuitButton
@onready var background = $Background

var button_tween : Tween
var welcome_audio : AudioStreamPlayer

func _ready():
	print("=== MENÚ PRINCIPAL CARGADO ===")
	setup_background_image()
	setup_welcome_sound()
	setup_menu()
	animate_title()
	play_welcome_sound()

func setup_menu():
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
		start_button.mouse_entered.connect(_on_button_hover.bind(start_button))
		start_button.mouse_exited.connect(_on_button_unhover.bind(start_button))
	
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
		quit_button.mouse_entered.connect(_on_button_hover.bind(quit_button))
		quit_button.mouse_exited.connect(_on_button_unhover.bind(quit_button))

func setup_background_image():	
	if background:
		if background is ColorRect:
			var texture_rect = TextureRect.new()
			texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			
			var image_path = "res://imagenes_inicio/imagen_inicio.png"
			if ResourceLoader.exists(image_path):
				var texture = load(image_path)
				texture_rect.texture = texture
				background.add_child(texture_rect)
			else:
		elif background is TextureRect:
			var image_path = "res://imagenes_inicio/imagen_inicio.png"
			if ResourceLoader.exists(image_path):
				var texture = load(image_path)
				background.texture = texture
		else:
			print("Background no es ColorRect ni TextureRect: ", background.get_class())
	else:
		print("Nodo Background no encontrado")

func setup_welcome_sound():
	welcome_audio = AudioStreamPlayer.new()
	add_child(welcome_audio)
	
	var sound_path = "res://Sounds/welcome-to-mario-kart_1.mp3"
	if ResourceLoader.exists(sound_path):
		var sound_stream = load(sound_path)
		welcome_audio.stream = sound_stream
		welcome_audio.volume_db = -5.0
		print("Sonido de bienvenida cargado: ", sound_path)
	else:
		print("Sonido de bienvenida no encontrado: ", sound_path)

func play_welcome_sound():
	if welcome_audio and welcome_audio.stream:
		await get_tree().create_timer(0.5).timeout
		welcome_audio.play()
		print("Sonido de bienvenida reproducido")

func animate_title():
	if title_label:
		var title_tween = create_tween()
		title_tween.set_loops()
		title_tween.tween_property(title_label, "modulate", Color(1.2, 1.2, 1.2, 1.0), 1.0)
		title_tween.tween_property(title_label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 1.0)

func _on_start_pressed():
	print("🎮 Iniciando selector de personajes...")
	
	if welcome_audio and welcome_audio.playing:
		welcome_audio.stop()
		print("Música de bienvenida detenida")
	
	get_tree().change_scene_to_file("res://Scenes/SelectorPersonajes.tscn")

func _on_quit_pressed():
	print("👋 Saliendo del juego...")
	get_tree().quit()

func _on_button_hover(button: Button):
	if button_tween:
		button_tween.kill()
	
	button_tween = create_tween()
	button_tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.2)

func _on_button_unhover(button: Button):
	if button_tween:
		button_tween.kill()
	
	button_tween = create_tween()
	button_tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ENTER:
				_on_start_pressed()
			KEY_ESCAPE:
				_on_quit_pressed()
