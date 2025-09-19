extends WorldElement
class_name SimpleOpponent

var character_name : String = "mario"
var ai_speed : float = 80.0
var ai_progress : float = 0.0
var start_delay : float = 0.0
var movement_variation : float = 0.0

var base_position : Vector2 = Vector2.ZERO
var current_offset : Vector2 = Vector2.ZERO
var time_alive : float = 0.0

func _init():
	pass

func _ready():
	setup_opponent_sprite()
	ai_speed = randf_range(60.0, 100.0)
	start_delay = randf_range(0.0, 2.0)
	movement_variation = randf_range(-10.0, 10.0)
	_mapPosition = Vector3(150 + randf_range(-20, 20), 0, 550 + start_delay * 50)

func setup_opponent_sprite():
	var sprite_path = "res://Textures/Racers/" + character_name.capitalize() + " Back.png"
	var sprite_node = get_node_or_null("Sprite2D")
	if not sprite_node:
		sprite_node = Sprite2D.new()
		sprite_node.name = "Sprite2D"
		add_child(sprite_node)
	
	_spriteGFX = sprite_node
	if ResourceLoader.exists(sprite_path):
		var texture = load(sprite_path) as Texture2D
		sprite_node.texture = texture
		sprite_node.scale = Vector2(1.2, 1.2)
	else:
		var fallback_texture = create_fallback_sprite()
		sprite_node.texture = fallback_texture

func create_fallback_sprite() -> ImageTexture:
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	var color = Color.RED
	
	match character_name:
		"mario": color = Color.RED
		"luigi": color = Color.GREEN
		"bowser": color = Color.ORANGE
		"donkikon": color = Color.BROWN
	
	image.fill(color)
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	return texture

func _physics_process(delta):
	time_alive += delta
	if time_alive < start_delay:
		return
	ai_progress += ai_speed * delta
	var lateral_movement = sin(time_alive * 2.0 + movement_variation) * 5.0
	current_offset.x = lateral_movement
	var new_z = _mapPosition.z + (ai_speed * delta * 10.0)
	var new_x = 150 + current_offset.x
	_mapPosition = Vector3(new_x, 0, new_z)

func set_character_name(name: String):
	character_name = name
	setup_opponent_sprite()

func set_start_position(pos: Vector2, delay: float = 0.0):
	base_position = pos
	position = pos
	start_delay = delay
	ai_progress = 0.0