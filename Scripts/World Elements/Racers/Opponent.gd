extends Racer

var ai_target_speed : float = 0.8
var ai_reaction_time : float = 0.3
var ai_aggression : float = 0.5
var ai_skill_level : float = 0.7
var random_offset : float = 0.0
var random_change_timer : float = 0.0
var random_change_interval : float = 2.0
var track_progress : float = 0.0
var target_line : float = 0.0
var character_name : String = "mario"
var is_player_controlled : bool = false
var throttle_input : float = 0.0
var steering_input : float = 0.0
var current_speed : float = 0.0
var max_speed : float = 120.0
var track_position : float = 0.0

func _ready():
	setup_ai_personality()
	setup_character_sprites()

func setup_ai_personality():
	match character_name:
		"mario":
			ai_skill_level = 0.8
			ai_aggression = 0.6
			ai_target_speed = 0.85
		"luigi":
			ai_skill_level = 0.7
			ai_aggression = 0.4
			ai_target_speed = 0.8
		"bowser":
			ai_skill_level = 0.9
			ai_aggression = 0.9
			ai_target_speed = 0.9
		"donkikon":
			ai_skill_level = 0.6
			ai_aggression = 0.7
			ai_target_speed = 0.75

func setup_character_sprites():
	var sprite_path = "res://Textures/Racers/" + character_name.capitalize() + " Back.png"
	if ResourceLoader.exists(sprite_path):
		var texture = load(sprite_path) as Texture2D
		var sprite_node = get_node_or_null("Sprite2D")
		if sprite_node and texture:
			sprite_node.texture = texture
		print("Oponente configurado: ", character_name)
	else:
		print("Sprite no encontrado para oponente: ", character_name)

func _physics_process(delta):
	if not is_player_controlled:
		process_ai_movement(delta)
		apply_ai_inputs()

func apply_ai_inputs():
	if throttle_input > 0.5:
		_currentMoveDirection = 1
	else:
		_currentMoveDirection = 0
	_inputDir.x = steering_input
	_inputDir.y = throttle_input - 0.5

func process_ai_movement(delta):
	random_change_timer += delta
	if random_change_timer >= random_change_interval:
		generate_random_movement()
		random_change_timer = 0.0
	var ai_throttle = calculate_ai_throttle()
	var ai_steering = calculate_ai_steering()
	
	throttle_input = ai_throttle + random_offset * 0.1
	steering_input = ai_steering + random_offset * 0.2
	
	throttle_input = clamp(throttle_input, 0.0, 1.0)
	steering_input = clamp(steering_input, -1.0, 1.0)

func calculate_ai_throttle() -> float:
	current_speed = _movementSpeed
	max_speed = _maxMovementSpeed
	
	var current_speed_ratio = current_speed / max_speed
	var target_ratio = ai_target_speed
	
	if current_speed_ratio < target_ratio:
		return 1.0
	elif current_speed_ratio > target_ratio * 1.1:
		return 0.3
	else:
		return 0.8

func calculate_ai_steering() -> float:
	var base_steering = target_line * ai_skill_level
	var steering_variation = sin(Time.get_ticks_msec() * 0.001) * 0.1
	var final_steering = base_steering + steering_variation
	final_steering *= (0.5 + ai_skill_level * 0.5)
	
	return clamp(final_steering, -1.0, 1.0)

func generate_random_movement():
	random_offset = randf_range(-0.5, 0.5)
	if randf() < 0.3:
		target_line = randf_range(-0.5, 0.5)
	random_change_interval = randf_range(1.5, 3.0)

func set_character(character : String):
	if character == "":
		return
		
	character_name = character
	setup_ai_personality()
	setup_character_sprites()

func set_starting_position(pos : Vector3, track_pos : float):
	position = Vector2(pos.x, pos.y)
	track_position = track_pos
	track_progress = 0.0
	print("🏁 Oponente ", character_name, " posicionado en: ", position)
