class_name AIBehavior
extends Node

var character_node: Node2D
var animated_sprite: AnimatedSprite2D

var character_name: String = "mario"
var ai_speed: float = 80.0
var ai_aggression: float = 0.5
var ai_skill: float = 0.7

var target_position: Vector3 = Vector3.ZERO
var waypoint_index: int = 0
var race_waypoints: Array[Vector3] = []
var is_following_player: bool = false
var follow_distance: float = 100.0

var navigation_agent: NavigationAgent2D

func setup_ai(char_name: String, start_pos: Vector3, char_node: Node2D):
	character_name = char_name.to_lower()
	character_node = char_node
	
	animated_sprite = find_animated_sprite(character_node)
	if not animated_sprite:
		pass
	else:
		animated_sprite.play("Idle")
	
	setup_ai_personality()
	setup_navigation_agent()
	setup_race_waypoints()
	
	character_node.SetMapPosition(start_pos)
	
func find_animated_sprite(node: Node) -> AnimatedSprite2D:
	if node is AnimatedSprite2D:
		return node as AnimatedSprite2D
	
	for child in node.get_children():
		if child is AnimatedSprite2D:
			return child as AnimatedSprite2D
		var result = find_animated_sprite(child)
		if result:
			return result
	
	return null

func setup_navigation_agent():
	if not navigation_agent:
		navigation_agent = NavigationAgent2D.new()
		character_node.add_child(navigation_agent)
	
	navigation_agent.path_desired_distance = 30.0
	navigation_agent.target_desired_distance = 40.0
	navigation_agent.avoidance_enabled = false
	navigation_agent.max_speed = ai_speed

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
		_:
			ai_speed = 80.0
			ai_aggression = 0.5
			ai_skill = 0.7

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

func set_target_waypoint(index: int):
	if index >= 0 and index < race_waypoints.size():
		waypoint_index = index
		target_position = race_waypoints[index]
		var target_2d = Vector2(target_position.x, target_position.z)
		if navigation_agent:
			navigation_agent.target_position = target_2d

func update_ai_behavior(mapForward: Vector3):
	if not character_node or not is_instance_valid(character_node):
		return
	update_ai_input()
	update_waypoint_following()
	if character_node.has_method("Update"):
		character_node.Update(mapForward)
	else:
		character_node.UpdateMovementSpeed()
		character_node.UpdateVelocity(mapForward)
		var next_position = character_node._mapPosition + character_node.ReturnVelocity()
		character_node.SetMapPosition(next_position)
	update_animations()

func update_waypoint_following():
	if race_waypoints.size() == 0:
		return
	
	var current_pos_2d = Vector2(character_node._mapPosition.x, character_node._mapPosition.z)
	var target_2d = Vector2(target_position.x, target_position.z)
	var distance_to_target = current_pos_2d.distance_to(target_2d)
	
	if distance_to_target < 60.0:
		var next_waypoint = (waypoint_index + 1) % race_waypoints.size()
		set_target_waypoint(next_waypoint)
	
	if navigation_agent and target_position != Vector3.ZERO:
		var target_2d_nav = Vector2(target_position.x, target_position.z)
		navigation_agent.target_position = target_2d_nav

func process_ai_behavior():
	var current_pos_2d = Vector2(character_node._mapPosition.x, character_node._mapPosition.z)
	var target_2d = Vector2(target_position.x, target_position.z)
	var distance_to_target = current_pos_2d.distance_to(target_2d)
	
	if distance_to_target < 30.0:
		var next_waypoint = (waypoint_index + 1) % race_waypoints.size()
		set_target_waypoint(next_waypoint)
	
	handle_collision_detection()
	
	if randf() < 0.01:
		is_following_player = !is_following_player

func handle_collision_detection():
	if not character_node._collisionHandler:
		return
	
	var current_pos = character_node._mapPosition
	var velocity = character_node.ReturnVelocity()
	var next_pos = current_pos + velocity
	var nextPixelPos = Vector2i(ceil(next_pos.x), ceil(next_pos.z))
	
	character_node.HandleRoadType(nextPixelPos, character_node._collisionHandler.ReturnCurrentRoadType(nextPixelPos))
	
	if character_node._collisionHandler.IsCollidingWithWall(Vector2i(ceil(next_pos.x), ceil(current_pos.z))):
		character_node._inputDir.x = -sign(velocity.x) * 0.8
		character_node.SetCollisionBump(Vector3(-sign(velocity.x) * 40, 0, 0))
		find_alternative_path()
	
	if character_node._collisionHandler.IsCollidingWithWall(Vector2i(ceil(current_pos.x), ceil(next_pos.z))):
		character_node._inputDir.x += randf_range(-0.5, 0.5)
		character_node.SetCollisionBump(Vector3(0, 0, -sign(velocity.z) * 40))
		find_alternative_path()

func update_ai_input():
	if waypoint_index >= race_waypoints.size():
		waypoint_index = 0
	
	var target = race_waypoints[waypoint_index]
	var current_pos_2d = Vector2(character_node._mapPosition.x, character_node._mapPosition.z)
	var target_2d = Vector2(target.x, target.z)
	
	var direction = (target_2d - current_pos_2d).normalized()
	
	character_node._inputDir.x = clamp(direction.x * 0.8, -1.0, 1.0)
	character_node._inputDir.y = -1.0
	
	if character_node._movementSpeed < 30.0:
		character_node._movementSpeed = 40.0
	
	var random_steering = randf_range(-0.1, 0.1) * ai_aggression
	character_node._inputDir.x += random_steering
	character_node._inputDir.x = clamp(character_node._inputDir.x, -1.0, 1.0)
	
	if Engine.get_process_frames() % 60 == 0:
		var distance_to_target = current_pos_2d.distance_to(target_2d)

func update_animations():
	if not animated_sprite:
		return
	var steering = character_node._inputDir.x
	
	if abs(steering) < 0.1:
		animated_sprite.play("Idle")
	elif steering > 0.1:
		animated_sprite.play("Right")
	elif steering < -0.1:
		animated_sprite.play("Left")
func ReturnPlayerInput() -> Vector2:
	if character_node:
		return character_node._inputDir
	return Vector2.ZERO

func find_alternative_path():
	var avoidance_direction = Vector2.ZERO
	for angle in [PI/4, -PI/4, PI/2, -PI/2]:
		var test_direction = Vector2(cos(angle), sin(angle))
		var test_pos = Vector2(character_node._mapPosition.x, character_node._mapPosition.z) + test_direction * 50
		
		if character_node._collisionHandler and not character_node._collisionHandler.IsCollidingWithWall(Vector2i(test_pos.x, test_pos.y)):
			avoidance_direction = test_direction
			break
	
	if avoidance_direction != Vector2.ZERO:
		character_node._inputDir.x = avoidance_direction.x * 0.8

func _on_velocity_computed(safe_velocity: Vector2):
	var velocity_3d = Vector3(safe_velocity.x, 0, safe_velocity.y)
	character_node._velocity = velocity_3d * get_process_delta_time()

func _on_navigation_finished():
	var next_waypoint = (waypoint_index + 1) % race_waypoints.size()
	set_target_waypoint(next_waypoint)

func ReturnSpriteGraphic() -> Node2D:
	if animated_sprite:
		return animated_sprite
	return character_node.ReturnSpriteGraphic()

func ReturnMapPosition() -> Vector3:
	return character_node.ReturnMapPosition()

func ReturnTotalDetailStates() -> int:
	return character_node.ReturnTotalDetailStates()
