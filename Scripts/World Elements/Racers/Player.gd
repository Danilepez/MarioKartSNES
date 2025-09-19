class_name Player
extends Racer

var _spriteHandler : Node2D

func Setup(mapSize : int, spriteHandler : Node2D = null):
	SetMapSize(mapSize)
	_spriteHandler = spriteHandler

func SetAIControlled(isAI: bool):
	super.SetAIControlled(isAI)

func Update(mapForward : Vector3):
	if(_isPushedBack):
		ApplyCollisionBump()
	
	var nextPos : Vector3 = _mapPosition + ReturnVelocity()
	var nextPixelPos : Vector2i = Vector2i(ceil(nextPos.x), ceil(nextPos.z))
	
	if(_collisionHandler.ReturnCurrentRoadType(nextPixelPos) == Globals.RoadType.WALL):
		_bumpDir = -ReturnVelocity().normalized()
		_isPushedBack = true
		_currPushbackTime = 0.0
		return
	
	if _spriteHandler and _spriteHandler.has_method("check_hazard_collision"):
		var collision_result = _spriteHandler.check_hazard_collision(nextPos)
		if collision_result.has_collision:
			_bumpDir = collision_result.bump_direction
			_isPushedBack = true
			_currPushbackTime = 0.0
			return
	
	HandleRoadType(nextPixelPos, _collisionHandler.ReturnCurrentRoadType(nextPixelPos))
	
	SetMapPosition(nextPos)
	UpdateMovementSpeed()
	UpdateVelocity(mapForward)
	
	CheckLapProgress()

func ReturnPlayerInput() -> Vector2:
	if Globals.raceStarted:
		_inputDir.x = Input.get_action_strength("Left") - Input.get_action_strength("Right")
		_inputDir.y = -Input.get_action_strength("Forward")
	else:
		_inputDir = Vector2.ZERO
	return Vector2(_inputDir.x, _inputDir.y)
func CheckLapProgress():
	if Globals.raceFinished or not Globals.raceStarted:
		return
	
	var playerX = _mapPosition.x
	var playerY = _mapPosition.z
	var finishLineY = 520.0
	var isInFinishArea = (playerX >= 100 and playerX <= 150)
	
	
	var isBeforeFinishLine = (playerY < 400)
	var isCrossingFinishLine = (playerY >= finishLineY - 10 and playerY <= finishLineY + 10)
	
	if Globals.playerBeforeFinishLine and isCrossingFinishLine and isInFinishArea:
		var currentTime = Time.get_ticks_msec()
		if (currentTime - Globals.lastLapTime) >= 8000:
			Globals.lastLapTime = currentTime
			Globals.playerBeforeFinishLine = false
			CompleteLap()
		else:
			var timeLeft = (8000 - (currentTime - Globals.lastLapTime)) / 1000.0
	
	elif isBeforeFinishLine and isInFinishArea:
		if not Globals.playerBeforeFinishLine:
			pass
		Globals.playerBeforeFinishLine = true

func CompleteLap():
	Globals.currentLap += 1
	print(" ¡VUELTA COMPLETADA! Vuelta: %d/%d" % [Globals.currentLap, Globals.totalLaps])
	play_lap_sound()
	
	if Globals.currentLap > Globals.totalLaps:
		print(" ¡CARRERA COMPLETADA AL COMPLETAR VUELTA %d/%d!" % [Globals.currentLap - 1, Globals.totalLaps])
		call_deferred("activate_victory")

func play_lap_sound():
	var game_node = get_tree().get_first_node_in_group("game")
	if not game_node:
		print(" No se encontró el nodo Game para reproducir sonido de vuelta")
		return
	
	if Globals.currentLap == 2:
		if game_node.has_method("play_lap2_sound"):
			game_node.play_lap2_sound()
	elif Globals.currentLap == 3:
		if game_node.has_method("play_final_lap_sound"):
			game_node.play_final_lap_sound()

func activate_victory():
	var game_node = get_tree().get_first_node_in_group("game")
	if game_node and game_node.has_method("stop_gameplay_music"):
		game_node.stop_gameplay_music()
	
	if game_node and game_node.has_method("show_victory_screen"):
		game_node.show_victory_screen()
	else:
		print("ERROR: No se encontró el nodo Game o método show_victory_screen")

func ApplyCollisionBump():
	_currPushbackTime += get_process_delta_time()
	if(_currPushbackTime >= _pushbackTime):
		_isPushedBack = false
		_currPushbackTime = 0.0
		_bumpDir = Vector3.ZERO
		return
	
	var bumpVelocity = _bumpDir * _bumpIntensity * (1.0 - (_currPushbackTime / _pushbackTime))
	SetMapPosition(_mapPosition + bumpVelocity * get_process_delta_time())

func ResetPlayerState():
	
	_velocity = Vector3.ZERO
	_movementSpeed = 0.0
	_currentMoveDirection = 0
	_inputDir = Vector2.ZERO
	
	_isPushedBack = false
	_currPushbackTime = 0.0
	_bumpDir = Vector3.ZERO
	
	_speedMultiplier = 1.0
	_onRoadType = Globals.RoadType.ROAD
