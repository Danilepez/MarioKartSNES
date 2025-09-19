extends Control

var character_buttons : Array[TextureButton] = []
var character_names : Array[String] = ["Mario", "Luigi", "Bowser", "DonkeyKong", "Yoshi"]
var current_selection : int = 0
@onready var background_selector = $SelectorBackground
@onready var title_label = $UI/TitleLabel
@onready var character_name_label = $UI/CharacterNameLabel
@onready var start_button = $UI/StartButton
@onready var character_container = $UI/CharacterContainer

var selection_tween : Tween
var hover_tween : Tween

signal character_selected(character_name: String)

func _ready():
	setup_ui()
	setup_character_buttons()
	update_selection_display()
	animate_entrance()
	
func setup_ui():
	if title_label:
		title_label.text = "🏆 SELECCIONA TU PILOTO 🏆"
		title_label.add_theme_font_size_override("font_size", 28)
		title_label.add_theme_color_override("font_color", Color.GOLD)
	
	if start_button:
		start_button.text = "¡COMENZAR CARRERA!"
		start_button.pressed.connect(_on_start_pressed)

func setup_character_buttons():
	
	for child in character_container.get_children():
		child.queue_free()
	character_buttons.clear()
	
	var h_container = HBoxContainer.new()
	h_container.add_theme_constant_override("separation", 20)
	character_container.add_child(h_container)
	
	# Texturas de personajes
	var character_textures = [
		"res://Textures/Racers/mario-3-0000-Photoroom.png",    # Mario
		"res://Textures/Racers/luigi-3-0000-Photoroom.png",    # Luigi  
		"res://Textures/Racers/bowser-3.png",                  # Bowser
		"res://Textures/Racers/donkeykongjr-3.png",           # DonkeyKong
		"res://Textures/Racers/yoshi.png"                      # Yoshi
	]
	
	for i in character_names.size():
		var character_name = character_names[i]
		var texture_path = character_textures[i]
		
		var v_container = VBoxContainer.new()
		v_container.add_theme_constant_override("separation", 10)
		
		var button = TextureButton.new()
		button.name = character_name + "Button"
		
		if ResourceLoader.exists(texture_path):
			var texture = load(texture_path) as Texture2D
			button.texture_normal = texture
		
		button.custom_minimum_size = Vector2(80, 80)
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		
		button.pressed.connect(_on_character_pressed.bind(i))
		button.mouse_entered.connect(_on_character_hover.bind(i))
		button.mouse_exited.connect(_on_character_unhover.bind(i))
		
		var name_label = Label.new()
		name_label.text = character_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.add_theme_color_override("font_color", Color.WHITE)
		
		v_container.add_child(button)
		v_container.add_child(name_label)
		
		h_container.add_child(v_container)
		character_buttons.append(button)
	

func _on_character_pressed(index: int):
	var character_name = character_names[index]
	
	current_selection = index
	update_selection_display()
	animate_selection(index)
	create_selection_particles(character_buttons[index])
	
func _on_character_hover(index: int):
	animate_hover(index, true)
	
func _on_character_unhover(index: int):
	animate_hover(index, false)

func update_selection_display():
	if character_name_label:
		var character_name = character_names[current_selection]
		
		if character_name == "DonkeyKong":
			character_name_label.text = "🐵 " + character_name + " 🐵"
			character_name_label.add_theme_color_override("font_color", Color.ORANGE)
		else:
			character_name_label.text = character_name
			character_name_label.add_theme_color_override("font_color", Color.YELLOW)
	
	for i in character_buttons.size():
		var button = character_buttons[i]
		if i == current_selection:
			button.modulate = Color(1.2, 1.2, 1.2, 1.0)
			button.scale = Vector2(1.1, 1.1)
		else:
			button.modulate = Color(0.8, 0.8, 0.8, 1.0)
			button.scale = Vector2(1.0, 1.0)

func animate_selection(index: int):
	if selection_tween:
		selection_tween.kill()
	
	selection_tween = create_tween()
	selection_tween.set_parallel(true)
	
	var button = character_buttons[index]
	
	selection_tween.tween_property(button, "scale", Vector2(1.4, 1.4), 0.15)
	selection_tween.tween_property(button, "scale", Vector2(0.9, 0.9), 0.1).set_delay(0.15)
	selection_tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.2).set_delay(0.25)
	
	selection_tween.tween_property(button, "modulate", Color(2.0, 2.0, 1.0, 1.0), 0.1)
	selection_tween.tween_property(button, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.3).set_delay(0.2)
	
	selection_tween.tween_property(button, "rotation", deg_to_rad(10), 0.1)
	selection_tween.tween_property(button, "rotation", deg_to_rad(-5), 0.1).set_delay(0.1)
	selection_tween.tween_property(button, "rotation", 0, 0.2).set_delay(0.2)

func animate_hover(index: int, is_hovering: bool):
	if hover_tween:
		hover_tween.kill()
	
	hover_tween = create_tween()
	var button = character_buttons[index]
	
	if is_hovering and index != current_selection:
		hover_tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)
		hover_tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)
	elif not is_hovering and index != current_selection:
		hover_tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
		hover_tween.tween_property(button, "modulate", Color(0.8, 0.8, 0.8, 1.0), 0.1)

func _on_start_pressed():
	var selected_character = character_names[current_selection]
	
	Globals.selected_character = selected_character
	
	character_selected.emit(selected_character)
	
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT, KEY_A:
				navigate_selection(-1)
			KEY_RIGHT, KEY_D:
				navigate_selection(1)
			KEY_ENTER, KEY_SPACE:
				_on_start_pressed()

func navigate_selection(direction: int):
	current_selection = (current_selection + direction) % character_names.size()
	if current_selection < 0:
		current_selection = character_names.size() - 1
	
	update_selection_display()
	animate_selection(current_selection)

func animate_entrance():	
	if title_label:
		title_label.modulate.a = 0.0
		title_label.scale = Vector2(0.5, 0.5)
	
	if character_name_label:
		character_name_label.modulate.a = 0.0
	
	if start_button:
		start_button.modulate.a = 0.0
		start_button.scale = Vector2(0.8, 0.8)
	
	for button in character_buttons:
		button.modulate.a = 0.0
		button.scale = Vector2(0.3, 0.3)
		button.rotation = deg_to_rad(180)
	
	var entrance_tween = create_tween()
	entrance_tween.set_parallel(true)

	if title_label:
		entrance_tween.tween_property(title_label, "modulate:a", 1.0, 0.8).set_delay(0.2)
		entrance_tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 0.8).set_delay(0.2)
		entrance_tween.set_ease(Tween.EASE_OUT)
		entrance_tween.set_trans(Tween.TRANS_BACK)
	
	for i in character_buttons.size():
		var button = character_buttons[i]
		var delay = 0.8 + (i * 0.15) 
		
		entrance_tween.tween_property(button, "modulate:a", 1.0, 0.4).set_delay(delay)
		entrance_tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.6).set_delay(delay)
		entrance_tween.tween_property(button, "rotation", 0.0, 0.5).set_delay(delay)
		entrance_tween.set_ease(Tween.EASE_OUT)
		entrance_tween.set_trans(Tween.TRANS_ELASTIC)
	
	if character_name_label:
		entrance_tween.tween_property(character_name_label, "modulate:a", 1.0, 0.5).set_delay(1.5)
	
	if start_button:
		entrance_tween.tween_property(start_button, "modulate:a", 1.0, 0.5).set_delay(1.8)
		entrance_tween.tween_property(start_button, "scale", Vector2(1.0, 1.0), 0.6).set_delay(1.8)
		entrance_tween.set_ease(Tween.EASE_OUT)
		entrance_tween.set_trans(Tween.TRANS_BACK)

func create_selection_particles(button: TextureButton):
	var particles_tween = create_tween()
	particles_tween.set_parallel(true)
	
	for i in 8:
		var angle = (PI * 2 / 8) * i
		var offset = Vector2(cos(angle), sin(angle)) * 50
		
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = Color.YELLOW
		particle.position = button.global_position + button.size / 2 + offset
		get_tree().current_scene.add_child(particle)
		
		particles_tween.tween_property(particle, "modulate:a", 0.0, 0.8)
		particles_tween.tween_property(particle, "scale", Vector2(2.0, 2.0), 0.8)
		
		particles_tween.tween_callback(particle.queue_free).set_delay(0.9)