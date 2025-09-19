extends Control

var character_sprites : Array[AnimatedSprite2D] = []
var character_names : Array[String] = ["mario", "luigi", "bowser", "donkikon"]
var current_selection : int = 0

@onready var background = $Background
@onready var character_container = $CharacterContainer
@onready var start_button = $StartButton
@onready var selection_indicator = $SelectionIndicator

var selection_tween : Tween
var indicator_tween : Tween

var character_positions : Array[Vector2] = [
	Vector2(110, 320),
	Vector2(190, 320),
	Vector2(110, 420),
	Vector2(270, 320)
]

signal character_selected(character_name: String)

func _ready():
	setup_background()
	await setup_characters()
	setup_ui()
	setup_selection_indicator()
	update_selection()
	await animate_characters()

func setup_background():
	if background:
		var selector_texture = load("res://imagenes_selector/selector.png")
		background.texture = selector_texture
		background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func setup_characters():
	if character_container:
		for child in character_container.get_children():
			child.queue_free()
	character_sprites.clear()
	await get_tree().process_frame
	for i in character_names.size():
		var character_name = character_names[i]
		var character_sprite = create_simple_character(character_name, character_positions[i], i)
		if character_sprite:
			character_container.add_child(character_sprite)
			character_sprites.append(character_sprite)

func create_simple_character(character_name: String, pos: Vector2, character_index: int) -> AnimatedSprite2D:
	var animated_sprite = AnimatedSprite2D.new()
	animated_sprite.name = character_name.capitalize() + "Sprite"
	animated_sprite.position = pos
	animated_sprite.scale = Vector2(1.6, 1.6)
	var sprite_frames = SpriteFrames.new()
	var texture_path = "res://imagenes_selector/" + character_name + ".png"
	if ResourceLoader.exists(texture_path):
		var texture = load(texture_path) as Texture2D
		var frame_count = detect_frame_count(texture)
		var frame_width = texture.get_width() / frame_count
		var frame_height = texture.get_height()
		sprite_frames.add_animation("idle")
		sprite_frames.set_animation_speed("idle", 8.0)
		sprite_frames.set_animation_loop("idle", true)
		for frame_index in range(frame_count):
			var atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = texture
			atlas_texture.region = Rect2(frame_index * frame_width, 0, frame_width, frame_height)
			sprite_frames.add_frame("idle", atlas_texture)
		sprite_frames.add_animation("idle")
		var fallback_texture = create_fallback_texture(character_name)
		sprite_frames.add_frame("idle", fallback_texture)
	animated_sprite.sprite_frames = sprite_frames
	animated_sprite.animation = "idle"
	animated_sprite.play()
	var area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(65, 65)
	collision.shape = shape
	area.add_child(collision)
	area.input_event.connect(_on_character_input.bind(character_index))
	area.mouse_entered.connect(_on_character_hover.bind(character_index))
	area.mouse_exited.connect(_on_character_unhover.bind(character_index))
	animated_sprite.add_child(area)
	return animated_sprite

func detect_frame_count(texture: Texture2D) -> int:
	var width = texture.get_width()
	var height = texture.get_height()
	var ratio = float(width) / float(height)
	
	if ratio >= 3.5:
		return 4
	elif ratio >= 2.5:
		return 3
	elif ratio >= 1.5:
		return 2
	else:
		return 1

func create_fallback_texture(character_name: String) -> ImageTexture:
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var color = Color.BLUE
	match character_name:
		"mario": color = Color.RED
		"luigi": color = Color.GREEN
		"yoshi": color = Color.LIME_GREEN
		"bowser": color = Color.DARK_RED
		"donkikon": color = Color.BROWN
	image.fill(color)
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	return texture

func setup_ui():
	if start_button:
		start_button.text = "¡COMENZAR CARRERA!"
		start_button.position = Vector2(150, 600)
		start_button.pressed.connect(_on_start_pressed)

func setup_selection_indicator():
	if not selection_indicator:
		selection_indicator = ColorRect.new()
		add_child(selection_indicator)
	selection_indicator.color = Color(1, 1, 0, 0.6)
	selection_indicator.size = Vector2(95, 95)
	selection_indicator.visible = true

func _on_character_input(viewport: Node, event: InputEvent, shape_idx: int, character_index: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_character(character_index)

func _on_character_hover(character_index: int):
	animate_character_hover(character_index, true)

func _on_character_unhover(character_index: int):
	animate_character_hover(character_index, false)

func select_character(index: int):
	current_selection = index
	update_selection()
	animate_selection()
	create_sound_feedback(character_names[index])

func update_selection():
	if selection_indicator and current_selection < character_sprites.size():
		var target_pos = character_positions[current_selection] - Vector2(47, 47)
		if indicator_tween:
			indicator_tween.kill()
		indicator_tween = create_tween()
		indicator_tween.tween_property(selection_indicator, "position", target_pos, 0.3)
		indicator_tween.set_ease(Tween.EASE_OUT)
		indicator_tween.set_trans(Tween.TRANS_BACK)

func animate_selection():
	# Animación especial al seleccionar
	if current_selection < character_sprites.size():
		var sprite = character_sprites[current_selection]
		
		if selection_tween:
			selection_tween.kill()
		selection_tween = create_tween()
		selection_tween.set_parallel(true)
		selection_tween.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.15)
		selection_tween.tween_property(sprite, "scale", Vector2(0.95, 0.95), 0.1).set_delay(0.15)
		selection_tween.tween_property(sprite, "scale", Vector2(1.1, 1.1), 0.2).set_delay(0.25)
		selection_tween.tween_property(sprite, "modulate", Color(2.0, 2.0, 1.2, 1.0), 0.1)
		selection_tween.tween_property(sprite, "modulate", Color(1.3, 1.3, 1.1, 1.0), 0.4).set_delay(0.2)
		selection_tween.tween_property(sprite, "rotation", deg_to_rad(8), 0.1)
		selection_tween.tween_property(sprite, "rotation", deg_to_rad(-4), 0.1).set_delay(0.1)
		selection_tween.tween_property(sprite, "rotation", 0, 0.25).set_delay(0.2)
		create_selection_particles(sprite)

func animate_character_hover(index: int, is_hovering: bool):
	if index < character_sprites.size():
		var sprite = character_sprites[index]
		var target_scale = Vector2(1.05, 1.05) if is_hovering else Vector2(1.0, 1.0)
		var target_modulate = Color(1.2, 1.2, 1.2) if is_hovering else Color(1.0, 1.0, 1.0)
		
		var hover_tween = create_tween()
		hover_tween.set_parallel(true)
		hover_tween.tween_property(sprite, "scale", target_scale, 0.2)
		hover_tween.tween_property(sprite, "modulate", target_modulate, 0.2)

func animate_characters():
	await get_tree().process_frame
	
	for i in character_sprites.size():
		var sprite = character_sprites[i]
		if sprite:
			sprite.modulate.a = 0.0
			sprite.scale = Vector2(0.8, 0.8)
			
			var entrance_tween = create_tween()
			var delay = i * 0.15
			
			entrance_tween.tween_property(sprite, "modulate:a", 1.0, 0.4).set_delay(delay)
			entrance_tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.5).set_delay(delay)
			entrance_tween.set_ease(Tween.EASE_OUT)
			entrance_tween.set_trans(Tween.TRANS_BACK)

func _on_start_pressed():
	var selected_character = character_names[current_selection]
	
	var character_mapping = {
		"mario": "Mario",
		"luigi": "Luigi", 
		"yoshi": "Yoshi",
		"bowser": "Bowser",
		"donkikon": "DonkeyKong"
	}
	
	var game_character = character_mapping.get(selected_character, "Mario")
	Globals.selected_character = game_character
	
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT, KEY_A:
				navigate_selection(-1)
			KEY_RIGHT, KEY_D:
				navigate_selection(1)
			KEY_UP, KEY_W:
				navigate_selection_vertical(-1)
			KEY_DOWN, KEY_S:
				navigate_selection_vertical(1)
			KEY_ENTER, KEY_SPACE:
				_on_start_pressed()

func navigate_selection(direction: int):
	current_selection = (current_selection + direction) % character_names.size()
	if current_selection < 0:
		current_selection = character_names.size() - 1
	
	update_selection()
	animate_selection()

func navigate_selection_vertical(direction: int):
	var new_selection = current_selection
	
	if direction == -1:
		match current_selection:
			2: new_selection = 0
	elif direction == 1:  
		match current_selection:
			0: new_selection = 2
			1: new_selection = 2
			3: new_selection = 2
	
	if new_selection >= 0 and new_selection < character_names.size() and new_selection != current_selection:
		current_selection = new_selection
		update_selection()
		animate_selection()

func create_selection_particles(sprite: AnimatedSprite2D):
	var particle_count = 12
	
	for i in particle_count:
		var angle = (TAU / particle_count) * i
		var distance = 60
		var start_pos = sprite.position + Vector2(cos(angle), sin(angle)) * 20
		var end_pos = sprite.position + Vector2(cos(angle), sin(angle)) * distance
		
		var particle = ColorRect.new()
		particle.size = Vector2(6, 6)
		particle.color = Color(1, 0.8, 0, 1)
		particle.position = start_pos
		add_child(particle)
		
		var particle_tween = create_tween()
		particle_tween.set_parallel(true)
		
		particle_tween.tween_property(particle, "position", end_pos, 0.8)
		particle_tween.tween_property(particle, "modulate:a", 0.0, 0.8)
		particle_tween.tween_property(particle, "scale", Vector2(2.0, 2.0), 0.8)
		particle_tween.tween_property(particle, "rotation", deg_to_rad(360), 0.8)
		
		particle_tween.tween_callback(particle.queue_free).set_delay(0.9)

func create_sound_feedback(character_name: String):
	var feedback_label = Label.new()
	feedback_label.text = get_character_sound_effect(character_name)
	feedback_label.add_theme_font_size_override("font_size", 24)
	feedback_label.add_theme_color_override("font_color", Color.YELLOW)
	feedback_label.position = Vector2(240, 100)
	add_child(feedback_label)
	
	var sound_tween = create_tween()
	sound_tween.set_parallel(true)
	
	sound_tween.tween_property(feedback_label, "position:y", 50, 1.0)
	sound_tween.tween_property(feedback_label, "modulate:a", 0.0, 1.0)
	sound_tween.tween_property(feedback_label, "scale", Vector2(1.5, 1.5), 1.0)
	
	sound_tween.tween_callback(feedback_label.queue_free).set_delay(1.1)

func get_character_sound_effect(character_name: String) -> String:
	match character_name:
		"mario": return "¡Mamma Mia!"
		"luigi": return "¡Wahoo!"
		"yoshi": return "¡Yoshi!"
		"bowser": return "¡GRAAWR!"
		"donkikon": return "¡Ook Ook!"
		_: return "¡Yeah!"
