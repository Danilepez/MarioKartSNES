class_name AIController
extends Node

const FOLLOW_WAYPOINTS = 0
const FOLLOW_PLAYER = 1
const AGGRESSIVE_CHASE = 2
const DEFENSIVE = 3
var character_node: Node2D
var character_name: String = "ai"

var ai_speed: float = 80.0
var ai_aggression: float = 0.5
var ai_skill: float = 0.7
var target_position: Vector3 = Vector3.ZERO
var waypoint_index: int = 0
var race_waypoints: Array[Vector3] = []

var player_reference: Node2D = null
var follow_player: bool = false
var follow_distance_min: float = 80.0
var follow_distance_max: float = 150.0
var player_detection_radius: float = 200.0
var last_behavior_switch: float = 0.0
var behavior_switch_cooldown: float = 2.0

var current_behavior: int = FOLLOW_WAYPOINTS

func setup_ai(char_name: String, start_pos: Vector3, char_node: Node2D, player_ref: Node2D = null):
	character_name = char_name.to_lower()
	character_node = char_node
	player_reference = player_ref
	
	setup_ai_personality()
	setup_race_waypoints()
	if character_node.has_method("SetMapPosition"):
		character_node.SetMapPosition(start_pos)
	if character_node.has_method("SetAIControlled"):
		character_node.SetAIControlled(true)
	else:
		print("ERROR: SetAIControlled method not found")
	
	character_node._inputDir = Vector2.ZERO
	
	var sprite_graphic = character_node.ReturnSpriteGraphic()
	if sprite_graphic and sprite_graphic is AnimatedSprite2D:
		sprite_graphic.scale = Vector2(3.0, 3.0)
	
	character_node._movementSpeed = 60.0
	character_node._maxMovementSpeed = ai_speed
	character_node._currentMoveDirection = -1
	
	character_node._inputDir.x = 0.0
	character_node._inputDir.y = -1.0
	
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
		"donkeykong":
			ai_speed = 75.0
			ai_aggression = 0.7
			ai_skill = 0.6
		"yoshi":
			ai_speed = 88.0
			ai_aggression = 0.5
			ai_skill = 0.85
		_:
			ai_speed = 80.0
			ai_aggression = 0.5
			ai_skill = 0.7

func setup_race_waypoints():
	race_waypoints = [
		Vector3(123, 0, 513),   # Start/Finish line
		Vector3(140, 0, 480),   # Post-start acceleration
		Vector3(160, 0, 450),   # Early straight section
		Vector3(180, 0, 420),   # Building speed
		Vector3(210, 0, 390),   # Turn entry
		Vector3(250, 0, 370),   # Turn apex approach
		Vector3(290, 0, 350),   # Mid-turn
		Vector3(330, 0, 330),   # Turn exit
		Vector3(370, 0, 310),   # Right straight
		Vector3(400, 0, 290),   # Bridge approach (near 400,144 from pipe locations)
		Vector3(430, 0, 270),   # Bridge crossing
		Vector3(460, 0, 250),   # Post-bridge
		Vector3(480, 0, 220),   # Top right approach
		Vector3(490, 0, 190),   # Hairpin entry
		Vector3(485, 0, 160),   # Hairpin apex
		Vector3(470, 0, 140),   # Hairpin mid
		Vector3(450, 0, 130),   # Hairpin exit
		Vector3(420, 0, 125),   # Top straight
		Vector3(380, 0, 130),   # Left turn entry
		Vector3(340, 0, 145),   # Left turn apex
		Vector3(300, 0, 165),   # Left turn exit
		Vector3(260, 0, 190),   # Left side
		Vector3(220, 0, 220),   # Lake area approach (near 336,336 from pipe locations)
		Vector3(190, 0, 260),   # Lake section
		Vector3(170, 0, 300),   # Lake exit
		Vector3(160, 0, 340),   # Bottom left
		Vector3(155, 0, 380),   # Final turn entry
		Vector3(150, 0, 420),   # Final turn
		Vector3(145, 0, 460),   # Pre-finish
		Vector3(135, 0, 490),   # Final approach
	]
	
	if race_waypoints.size() > 0:
		set_target_waypoint(0)

func set_target_waypoint(index: int):
	if index >= 0 and index < race_waypoints.size():
		waypoint_index = index
		target_position = race_waypoints[index]

func update_ai_behavior(mapForward: Vector3):
	if not character_node or not is_instance_valid(character_node):
		return
	
	maintain_sprite_scale()
	
	if Globals.raceStarted:
		update_waypoint_following()
		update_behavior_based_on_player()
		update_ai_input()
	else:
		pass
	
	character_node.Update(mapForward)
	
	if Engine.get_process_frames() % 60 == 0:
		var pos = character_node._mapPosition
		var speed = character_node._movementSpeed
		var input_dir = character_node._inputDir
		var player_dist = get_distance_to_player()
		var behavior = get_behavior_name()
		var target_waypoint = waypoint_index if waypoint_index < race_waypoints.size() else -1

func update_waypoint_following():
	if race_waypoints.size() == 0:
		return
	
	var current_pos_2d = Vector2(character_node._mapPosition.x, character_node._mapPosition.z)
	var target_2d = Vector2(target_position.x, target_position.z)
	var distance_to_target = current_pos_2d.distance_to(target_2d)
	
	var switch_distance = 50.0
	match current_behavior:
		AGGRESSIVE_CHASE:
			switch_distance = 40.0
		DEFENSIVE:
			switch_distance = 60.0
		FOLLOW_PLAYER:
			switch_distance = 45.0
		_:
			switch_distance = 50.0 + (ai_skill * 20.0)
	
	if distance_to_target < switch_distance:
		var next_waypoint = (waypoint_index + 1) % race_waypoints.size()
		set_target_waypoint(next_waypoint)
		
		if ai_aggression > 0.7 and randf() < 0.15:
			next_waypoint = (waypoint_index + 1) % race_waypoints.size()
			set_target_waypoint(next_waypoint)

func update_ai_input():
	var direction: Vector2
	var target_speed_modifier: float = 1.0
	
	match current_behavior:
		FOLLOW_PLAYER:
			direction = calculate_player_following_direction()
			target_speed_modifier = 1.1
		AGGRESSIVE_CHASE:
			direction = calculate_aggressive_chase_direction()
			target_speed_modifier = 1.2
		DEFENSIVE:
			direction = calculate_defensive_direction()
			target_speed_modifier = 0.9
		_: # FOLLOW_WAYPOINTS
			direction = calculate_waypoint_direction()
			target_speed_modifier = 1.0
	
	character_node._inputDir.x = clamp(direction.x, -1.0, 1.0)
	character_node._inputDir.y = -1.0
	
	var target_speed = ai_speed * target_speed_modifier
	
	if character_node._movementSpeed < 30.0:
		character_node._movementSpeed = 50.0
	
	if character_node._inputDir.y > -0.5:
		character_node._inputDir.y = -1.0
	
	character_node._maxMovementSpeed = target_speed
	

func ReturnPlayerInput() -> Vector2:
	if character_node:
		return Vector2(character_node._inputDir.x, character_node._inputDir.y)
	return Vector2.ZERO

func update_behavior_based_on_player():
	if not player_reference or not is_instance_valid(player_reference):
		current_behavior = FOLLOW_WAYPOINTS
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_behavior_switch < behavior_switch_cooldown:
		return
	
	var distance_to_player = get_distance_to_player()
	
	if distance_to_player < follow_distance_min:
		if ai_aggression > 0.6:
			current_behavior = AGGRESSIVE_CHASE
		else:
			current_behavior = DEFENSIVE
	elif distance_to_player < player_detection_radius:
		if ai_aggression > 0.5:
			current_behavior = FOLLOW_PLAYER
		else:
			current_behavior = FOLLOW_WAYPOINTS
	else:
		current_behavior = FOLLOW_WAYPOINTS
	
	last_behavior_switch = current_time

func get_distance_to_player() -> float:
	if not player_reference or not is_instance_valid(player_reference):
		return 999999.0
	
	var ai_pos = Vector2(character_node._mapPosition.x, character_node._mapPosition.z)
	var player_pos = Vector2(player_reference._mapPosition.x, player_reference._mapPosition.z)
	return ai_pos.distance_to(player_pos)

func calculate_player_following_direction() -> Vector2:
	if not player_reference or not is_instance_valid(player_reference):
		return calculate_waypoint_direction()
	
	var ai_pos = Vector2(character_node._mapPosition.x, character_node._mapPosition.z)
	var player_pos = Vector2(player_reference._mapPosition.x, player_reference._mapPosition.z)
	var to_player = (player_pos - ai_pos).normalized()
	
	var distance = ai_pos.distance_to(player_pos)
	if distance < follow_distance_min:
		return -to_player * 0.8
	elif distance > follow_distance_max:
		return to_player * 1.2
	else:
		var player_velocity = Vector2.ZERO
		if player_reference.has_method("ReturnVelocity"):
			var vel3d = player_reference.ReturnVelocity()
			player_velocity = Vector2(vel3d.x, vel3d.z).normalized()
		return player_velocity * 0.8 + to_player * 0.2

func calculate_aggressive_chase_direction() -> Vector2:
	if not player_reference or not is_instance_valid(player_reference):
		return calculate_waypoint_direction()
	
	var ai_pos = Vector2(character_node._mapPosition.x, character_node._mapPosition.z)
	var player_pos = Vector2(player_reference._mapPosition.x, player_reference._mapPosition.z)
	
	var player_velocity = Vector2.ZERO
	if player_reference.has_method("ReturnVelocity"):
		var vel3d = player_reference.ReturnVelocity()
		player_velocity = Vector2(vel3d.x, vel3d.z)
	
	var prediction_time = 1.0
	var predicted_player_pos = player_pos + player_velocity * prediction_time
	
	return (predicted_player_pos - ai_pos).normalized() * 1.3

func calculate_defensive_direction() -> Vector2:
	var waypoint_dir = calculate_waypoint_direction()
	
	if not player_reference or not is_instance_valid(player_reference):
		return waypoint_dir
	
	var ai_pos = Vector2(character_node._mapPosition.x, character_node._mapPosition.z)
	var player_pos = Vector2(player_reference._mapPosition.x, player_reference._mapPosition.z)
	var distance = ai_pos.distance_to(player_pos)
	
	if distance < follow_distance_min * 1.5:
		var away_from_player = (ai_pos - player_pos).normalized()
		return waypoint_dir * 0.7 + away_from_player * 0.3
	
	return waypoint_dir

func calculate_waypoint_direction() -> Vector2:
	if waypoint_index >= race_waypoints.size():
		waypoint_index = 0
	
	var target = race_waypoints[waypoint_index]
	var current_pos_2d = Vector2(character_node._mapPosition.x, character_node._mapPosition.z)
	var target_2d = Vector2(target.x, target.z)
	
	return (target_2d - current_pos_2d).normalized() * 1.2

func get_behavior_name() -> String:
	match current_behavior:
		FOLLOW_PLAYER:
			return "FOLLOW_PLAYER"
		AGGRESSIVE_CHASE:
			return "AGGRESSIVE_CHASE"
		DEFENSIVE:
			return "DEFENSIVE"
		_:
			return "FOLLOW_WAYPOINTS"

func maintain_sprite_scale():
	var sprite_graphic = character_node.ReturnSpriteGraphic()
	if sprite_graphic and sprite_graphic is AnimatedSprite2D:
		if sprite_graphic.scale != Vector2(3.0, 3.0):
			sprite_graphic.scale = Vector2(3.0, 3.0)

func follow_player_simple_quiet():
	if not player_reference or not is_instance_valid(player_reference):
		character_node._inputDir.x = 0.0
		character_node._inputDir.y = -1.0
		character_node._movementSpeed = max(character_node._movementSpeed, 60.0)
		return
	
	var ai_pos = Vector2(character_node._mapPosition.x, character_node._mapPosition.z)
	var player_pos = Vector2(player_reference._mapPosition.x, player_reference._mapPosition.z)
	var direction_to_player = (player_pos - ai_pos).normalized()
	var distance_to_player = ai_pos.distance_to(player_pos)
	
	character_node._inputDir.x = clamp(direction_to_player.x * 1.5, -1.0, 1.0)
	character_node._inputDir.y = -1.0
	
	if character_node._movementSpeed < 50.0:
		character_node._movementSpeed = 60.0
	
	if distance_to_player > 200.0:
		character_node._maxMovementSpeed = ai_speed * 1.3
	elif distance_to_player < 50.0:
		character_node._maxMovementSpeed = ai_speed * 0.8
	else:
		character_node._maxMovementSpeed = ai_speed

func follow_player_simple():
	if not player_reference or not is_instance_valid(player_reference):
		character_node._inputDir.x = 0.0
		character_node._inputDir.y = -1.0
		character_node._movementSpeed = max(character_node._movementSpeed, 60.0)
		return
	
	var ai_pos = Vector2(character_node._mapPosition.x, character_node._mapPosition.z)
	var player_pos = Vector2(player_reference._mapPosition.x, player_reference._mapPosition.z)
	
	var direction_to_player = (player_pos - ai_pos).normalized()
	var distance_to_player = ai_pos.distance_to(player_pos)
		
	character_node._inputDir.x = clamp(direction_to_player.x * 1.5, -1.0, 1.0)
	character_node._inputDir.y = -1.0
	
	var verified_input = character_node.ReturnPlayerInput()
	
	if character_node._movementSpeed < 50.0:
		character_node._movementSpeed = 60.0
	
	if distance_to_player > 200.0:
		character_node._maxMovementSpeed = ai_speed * 1.3
	elif distance_to_player < 50.0:
		character_node._maxMovementSpeed = ai_speed * 0.8
	else:
		character_node._maxMovementSpeed = ai_speed
