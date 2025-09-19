class_name AIOpponent
extends Racer

var navigation_agent: NavigationAgent2D

var character_name: String = "mario"
var ai_speed: float = 80.0
var ai_aggression: float = 0.5
var ai_skill: float = 0.7
var target_position: Vector3 = Vector3.ZERO
var waypoint_index: int = 0
var race_waypoints: Array[Vector3] = []
var is_following_player: bool = false
var follow_distance: float = 100.0

var character_textures: Dictionary = {}

func _ready():
	if not _spriteGFX:
		_spriteGFX = Sprite2D.new()
		_spriteGFX.name = "SpriteGFX"
		add_child(_spriteGFX)
	
	_mapPosition = Vector3(120, 0, 500)
	_mapSize = 1000.0
	
	setup_navigation_agent()
	setup_character_appearance()
	setup_race_waypoints()

func setup_navigation_agent():
	if not navigation_agent:
		navigation_agent = NavigationAgent2D.new()
		add_child(navigation_agent)
	
	navigation_agent.path_desired_distance = 10.0
	navigation_agent.target_desired_distance = 15.0
	navigation_agent.path_max_distance = 50.0
	navigation_agent.avoidance_enabled = true
	navigation_agent.radius = 20.0
	navigation_agent.max_speed = ai_speed
	
	navigation_agent.velocity_computed.connect(_on_velocity_computed)
	navigation_agent.navigation_finished.connect(_on_navigation_finished)

func setup_character_appearance():
	character_textures = {
		"mario": "res://Textures/Racers/mario-3-0000-Photoroom.png",
		"luigi": "res://Textures/Racers/luigi-3-0000-Photoroom.png",
		"bowser": "res://Textures/Racers/bowser-3.png",
		"donkikon": "res://Textures/Racers/donkeykongjr-3.png"
	}
	
	if character_name in character_textures:
		var texture_path = character_textures[character_name]
		if ResourceLoader.exists(texture_path):
			var texture = load(texture_path)
			if _spriteGFX and _spriteGFX is Sprite2D:
				_spriteGFX.texture = texture
				_spriteGFX.scale = Vector2(0.8, 0.8)
			else:
				print("_spriteGFX not available or not Sprite2D")
		else:
			print("Texture not found: ", texture_path)

func setup_race_waypoints():
	race_waypoints = [
		Vector3(123, 0, 513),   # Start/Finish line (from Globals)
		Vector3(150, 0, 480),   # Move forward from start
		Vector3(200, 0, 420),   # First curve approach
		Vector3(280, 0, 380),   # Mid-track section
		Vector3(350, 0, 350),   # Right side of track
		Vector3(420, 0, 320),   # Far right section
		Vector3(450, 0, 280),   # Top right curve
		Vector3(400, 0, 220),   # Top section
		Vector3(320, 0, 180),   # Top left curve
		Vector3(240, 0, 200),   # Left side return
		Vector3(180, 0, 280),   # Left side middle
		Vector3(140, 0, 380),   # Left side approach
		Vector3(120, 0, 450),   # Approaching finish
		Vector3(123, 0, 500),   # Near finish line
	]
	
	if race_waypoints.size() > 0:
		set_target_waypoint(0)

func set_character(new_character_name: String):
	character_name = new_character_name.to_lower()
	setup_ai_personality()
	setup_character_appearance()

func setup_ai_personality():
	match character_name:
		"mario":
			ai_speed = 85.0
			ai_aggression = 0.6
			ai_skill = 0.8
		"luigi":
			ai_speed = 80.0
			ai_aggression = 0.4
			ai_skill = 0.7
		"bowser":
			ai_speed = 90.0
			ai_aggression = 0.9
			ai_skill = 0.9
		"donkikon":
			ai_speed = 75.0
			ai_aggression = 0.7
			ai_skill = 0.6
		_:
			ai_speed = 80.0
			ai_aggression = 0.5
			ai_skill = 0.7

func set_target_waypoint(index: int):
	if index >= 0 and index < race_waypoints.size():
		waypoint_index = index
		target_position = race_waypoints[index]
		var target_2d = Vector2(target_position.x, target_position.z)
		navigation_agent.target_position = target_2d

func Update(mapForward: Vector3):
	if _isPushedBack:
		ApplyCollisionBump()
		return
	process_ai_behavior()
	update_ai_input()
	UpdateMovementSpeed()
	UpdateVelocity(mapForward)
	var next_pos = _mapPosition + _velocity
	var nextPixelPos = Vector2i(ceil(next_pos.x), ceil(next_pos.z))
	var hit_wall = false
	if _collisionHandler and _collisionHandler.IsCollidingWithWall(Vector2i(ceil(next_pos.x), ceil(_mapPosition.z))):
		next_pos.x = _mapPosition.x
		SetCollisionBump(Vector3(-sign(_velocity.x) * 50, 0, 0))
		hit_wall = true
	
	if _collisionHandler and _collisionHandler.IsCollidingWithWall(Vector2i(ceil(_mapPosition.x), ceil(next_pos.z))):
		next_pos.z = _mapPosition.z
		SetCollisionBump(Vector3(0, 0, -sign(_velocity.z) * 50))
		hit_wall = true
	
	if hit_wall:
		find_alternative_path()
	
	if _collisionHandler:
		HandleRoadType(nextPixelPos, _collisionHandler.ReturnCurrentRoadType(nextPixelPos))
	
	SetMapPosition(next_pos)

func process_ai_behavior():
	var current_pos_2d = Vector2(_mapPosition.x, _mapPosition.z)
	var target_2d = Vector2(target_position.x, target_position.z)
	var distance_to_target = current_pos_2d.distance_to(target_2d)
	
	if distance_to_target < 30.0:
		var next_waypoint = (waypoint_index + 1) % race_waypoints.size()
		set_target_waypoint(next_waypoint)
	
	if randf() < 0.01:
		is_following_player = !is_following_player

func update_ai_input():
	if waypoint_index >= race_waypoints.size():
		waypoint_index = 0
	var target = race_waypoints[waypoint_index]
	var current_pos_2d = Vector2(_mapPosition.x, _mapPosition.z)
	var target_2d = Vector2(target.x, target.z)
	var next_path_position = Vector2.ZERO
	if navigation_agent and not navigation_agent.is_navigation_finished():
		next_path_position = navigation_agent.get_next_path_position()
	else:
		next_path_position = target_2d
	
	var direction = (next_path_position - current_pos_2d).normalized()
	
	_inputDir.x = clamp(direction.x * 0.8, -1.0, 1.0)
	_inputDir.y = -1.0
	
	if _movementSpeed < 10.0:
		_movementSpeed = 20.0
	
	if randf() < 0.05:
		_inputDir.x += randf_range(-0.1, 0.1)
		_inputDir.x = clamp(_inputDir.x, -1.0, 1.0)

func find_alternative_path():
	var avoidance_direction = Vector2.ZERO
	for angle in [PI/4, -PI/4, PI/2, -PI/2]:
		var test_direction = Vector2(cos(angle), sin(angle))
		var test_pos = Vector2(_mapPosition.x, _mapPosition.z) + test_direction * 50
		
		if _collisionHandler and not _collisionHandler.IsCollidingWithWall(Vector2i(test_pos.x, test_pos.y)):
			avoidance_direction = test_direction
			break
	
	if avoidance_direction != Vector2.ZERO:
		_inputDir.x = avoidance_direction.x * 0.8
		print("🚧 AI ", character_name, " avoiding obstacle, steering: ", _inputDir.x)

func _on_velocity_computed(safe_velocity: Vector2):
	var velocity_3d = Vector3(safe_velocity.x, 0, safe_velocity.y)
	_velocity = velocity_3d * get_process_delta_time()

func _on_navigation_finished():
	var next_waypoint = (waypoint_index + 1) % race_waypoints.size()
	set_target_waypoint(next_waypoint)


func set_starting_position(pos: Vector3):
	SetMapPosition(pos)
	if navigation_agent:
		navigation_agent.global_position = Vector2(pos.x, pos.z)
func ReturnSpriteGraphic() -> Node2D:
	if _spriteGFX and is_instance_valid(_spriteGFX):
		_spriteGFX.visible = true
		_spriteGFX.modulate = Color.WHITE
		return _spriteGFX
	
	if not has_node("FallbackSprite"):
		var fallback = ColorRect.new()
		fallback.name = "FallbackSprite"
		fallback.size = Vector2(30, 40)
		fallback.color = Color.RED
		fallback.visible = true
		add_child(fallback)
		return fallback
	return get_node("FallbackSprite")

func ReturnMapPosition() -> Vector3:
	return _mapPosition / _mapSize

func ReturnTotalDetailStates() -> int:
	return 1
