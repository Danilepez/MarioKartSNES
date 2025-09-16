# AIBehavior.gd - AI behavior component for existing character nodes
class_name AIBehavior
extends Node

# Reference to the character node this AI controls
var character_node: Node2D
var animated_sprite: AnimatedSprite2D

# AI personality variables
var character_name: String = "mario"
var ai_speed: float = 80.0
var ai_aggression: float = 0.5
var ai_skill: float = 0.7

# Movement variables
var target_position: Vector3 = Vector3.ZERO
var waypoint_index: int = 0
var race_waypoints: Array[Vector3] = []
var is_following_player: bool = false
var follow_distance: float = 100.0

# NavigationAgent2D for pathfinding
var navigation_agent: NavigationAgent2D

func setup_ai(char_name: String, start_pos: Vector3, char_node: Node2D):
	character_name = char_name.to_lower()
	character_node = char_node
	
	# Find the AnimatedSprite2D in the character node
	animated_sprite = find_animated_sprite(character_node)
	if not animated_sprite:
		print("❌ No AnimatedSprite2D found in character node: ", char_name)
	else:
		print("✅ Found AnimatedSprite2D: ", animated_sprite.name)
		# Start with idle animation
		animated_sprite.play("Idle")
	
	setup_ai_personality()
	setup_navigation_agent()
	setup_race_waypoints()
	
	# Initialize position
	character_node.SetMapPosition(start_pos)
	
	print("🤖 AI Behavior setup complete for: ", character_name, " at position: ", start_pos)

func find_animated_sprite(node: Node) -> AnimatedSprite2D:
	# Look for AnimatedSprite2D in the node and its children
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
	# Create NavigationAgent2D if it doesn't exist
	if not navigation_agent:
		navigation_agent = NavigationAgent2D.new()
		character_node.add_child(navigation_agent)
	
	# Configure NavigationAgent2D with simpler settings
	navigation_agent.path_desired_distance = 30.0
	navigation_agent.target_desired_distance = 40.0
	navigation_agent.avoidance_enabled = false  # Disable for simplicity
	navigation_agent.max_speed = ai_speed

func setup_ai_personality():
	# Different AI personalities based on character
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
	# Define waypoints that follow the actual track layout and match NavigationRegion2D
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
	
	# Start with first waypoint
	if race_waypoints.size() > 0:
		set_target_waypoint(0)
		print("🗺️ AI ", character_name, " waypoints setup: ", race_waypoints.size(), " points following track layout")

func set_target_waypoint(index: int):
	if index >= 0 and index < race_waypoints.size():
		waypoint_index = index
		target_position = race_waypoints[index]
		var target_2d = Vector2(target_position.x, target_position.z)
		if navigation_agent:
			navigation_agent.target_position = target_2d
		print("🎯 AI ", character_name, " targeting waypoint ", index, ": ", target_2d)

func update_ai_behavior(mapForward: Vector3):
	if not character_node or not is_instance_valid(character_node):
		return
	
	# Update AI input first
	update_ai_input()
	
	# Update waypoint following
	update_waypoint_following()
	
	# Use Player.Update() system instead of bypassing it
	if character_node.has_method("Update"):
		character_node.Update(mapForward)
	else:
		# Fallback for non-Player nodes
		character_node.UpdateMovementSpeed()
		character_node.UpdateVelocity(mapForward)
		var next_position = character_node._mapPosition + character_node.ReturnVelocity()
		character_node.SetMapPosition(next_position)
	
	# Update animations
	update_animations()
	
	# Debug every 120 frames for performance
	if Engine.get_process_frames() % 120 == 0:
		print("🤖 AI ", character_name, " - Pos: ", character_node._mapPosition, " Speed: ", character_node._movementSpeed)

func update_waypoint_following():
	if race_waypoints.size() == 0:
		return
	
	var current_pos_2d = Vector2(character_node._mapPosition.x, character_node._mapPosition.z)
	var target_2d = Vector2(target_position.x, target_position.z)
	var distance_to_target = current_pos_2d.distance_to(target_2d)
	
	# Check if we're close enough to the current waypoint to move to the next one
	if distance_to_target < 60.0:  # Reasonable threshold for waypoint switching
		var next_waypoint = (waypoint_index + 1) % race_waypoints.size()
		set_target_waypoint(next_waypoint)
		print("🎯 AI ", character_name, " reached waypoint ", waypoint_index, ", moving to: ", next_waypoint)
	
	# Update NavigationAgent2D target position to current waypoint
	if navigation_agent and target_position != Vector3.ZERO:
		var target_2d_nav = Vector2(target_position.x, target_position.z)
		navigation_agent.target_position = target_2d_nav

func process_ai_behavior():
	# Check if we need to switch to next waypoint
	var current_pos_2d = Vector2(character_node._mapPosition.x, character_node._mapPosition.z)
	var target_2d = Vector2(target_position.x, target_position.z)
	var distance_to_target = current_pos_2d.distance_to(target_2d)
	
	# If close to current waypoint, move to next one
	if distance_to_target < 30.0:
		var next_waypoint = (waypoint_index + 1) % race_waypoints.size()
		set_target_waypoint(next_waypoint)
	
	# Handle collision detection and avoidance
	handle_collision_detection()
	
	# Occasionally follow the player for more dynamic racing
	if randf() < 0.01:  # 1% chance per frame to switch behavior
		is_following_player = !is_following_player

func handle_collision_detection():
	if not character_node._collisionHandler:
		return
	
	var current_pos = character_node._mapPosition
	var velocity = character_node.ReturnVelocity()
	var next_pos = current_pos + velocity
	var nextPixelPos = Vector2i(ceil(next_pos.x), ceil(next_pos.z))
	
	# Handle road types at next position
	character_node.HandleRoadType(nextPixelPos, character_node._collisionHandler.ReturnCurrentRoadType(nextPixelPos))
	
	# Check for wall collision at next position
	if character_node._collisionHandler.IsCollidingWithWall(Vector2i(ceil(next_pos.x), ceil(current_pos.z))):
		# Horizontal collision - adjust steering
		character_node._inputDir.x = -sign(velocity.x) * 0.8
		character_node.SetCollisionBump(Vector3(-sign(velocity.x) * 40, 0, 0))
		find_alternative_path()
	
	if character_node._collisionHandler.IsCollidingWithWall(Vector2i(ceil(current_pos.x), ceil(next_pos.z))):
		# Vertical collision - try to steer around
		character_node._inputDir.x += randf_range(-0.5, 0.5)
		character_node.SetCollisionBump(Vector3(0, 0, -sign(velocity.z) * 40))
		find_alternative_path()

func update_ai_input():
	# Get current target waypoint
	if waypoint_index >= race_waypoints.size():
		waypoint_index = 0
	
	var target = race_waypoints[waypoint_index]
	var current_pos_2d = Vector2(character_node._mapPosition.x, character_node._mapPosition.z)
	var target_2d = Vector2(target.x, target.z)
	
	# Simple direct movement toward target (bypass NavigationAgent2D for now)
	var direction = (target_2d - current_pos_2d).normalized()
	
	# Set AI input to match Racer system expectations
	character_node._inputDir.x = clamp(direction.x * 0.6, -1.0, 1.0)  # Steering
	character_node._inputDir.y = -1.0  # Always accelerate forward
	
	# Force minimum speed for AI movement
	if character_node._movementSpeed < 20.0:
		character_node._movementSpeed = 30.0
	
	# Debug every 60 frames to track movement
	if Engine.get_process_frames() % 60 == 0:
		var distance_to_target = current_pos_2d.distance_to(target_2d)
		print("🎮 AI ", character_name, " - Pos: (%.0f,%.0f) → Target: (%.0f,%.0f) | Dist: %.0f | Speed: %.1f" % [current_pos_2d.x, current_pos_2d.y, target_2d.x, target_2d.y, distance_to_target, character_node._movementSpeed])

func update_animations():
	if not animated_sprite:
		return
	
	# Update animation based on steering direction
	var steering = character_node._inputDir.x
	
	if abs(steering) < 0.1:
		# Going straight
		animated_sprite.play("Idle")
	elif steering > 0.1:
		# Turning right
		animated_sprite.play("Right")
	elif steering < -0.1:
		# Turning left
		animated_sprite.play("Left")

# Add ReturnPlayerInput() method for Racer compatibility
func ReturnPlayerInput() -> Vector2:
	if character_node:
		return character_node._inputDir
	return Vector2.ZERO

func find_alternative_path():
	# When hitting a wall, try to steer away
	var avoidance_direction = Vector2.ZERO
	
	# Check multiple directions to find a clear path
	for angle in [PI/4, -PI/4, PI/2, -PI/2]:
		var test_direction = Vector2(cos(angle), sin(angle))
		var test_pos = Vector2(character_node._mapPosition.x, character_node._mapPosition.z) + test_direction * 50
		
		if character_node._collisionHandler and not character_node._collisionHandler.IsCollidingWithWall(Vector2i(test_pos.x, test_pos.y)):
			avoidance_direction = test_direction
			break
	
	# Apply avoidance steering
	if avoidance_direction != Vector2.ZERO:
		character_node._inputDir.x = avoidance_direction.x * 0.8
		print("🚧 AI ", character_name, " avoiding obstacle, steering: ", character_node._inputDir.x)

func _on_velocity_computed(safe_velocity: Vector2):
	# Apply the computed safe velocity
	var velocity_3d = Vector3(safe_velocity.x, 0, safe_velocity.y)
	character_node._velocity = velocity_3d * get_process_delta_time()

func _on_navigation_finished():
	# Move to next waypoint when navigation is finished
	var next_waypoint = (waypoint_index + 1) % race_waypoints.size()
	set_target_waypoint(next_waypoint)

# Override WorldElement methods to ensure proper integration
func ReturnSpriteGraphic() -> Node2D:
	if animated_sprite:
		return animated_sprite
	return character_node.ReturnSpriteGraphic()

func ReturnMapPosition() -> Vector3:
	return character_node.ReturnMapPosition()

func ReturnTotalDetailStates() -> int:
	return character_node.ReturnTotalDetailStates()

# Add debug function
func _ready():
	print("🤖 AIBehavior _ready() called for: ", character_name)
