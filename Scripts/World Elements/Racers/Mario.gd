extends Player
class_name Mario

var character_name: String = "Mario"

var _leftHoldTime: float = 0.0
var _rightHoldTime: float = 0.0
var _turnThreshold: float = 0.1
var _maxTurnTime: float = 1.0

func ReturnSpriteGraphic() -> AnimatedSprite2D:
	return _spriteGFX as AnimatedSprite2D

func Update(mapForward : Vector3):
	super.Update(mapForward)
	HandleAnimations()

func HandleAnimations():
	var animated_sprite = ReturnSpriteGraphic()
	if !animated_sprite:
		return
	
	var input = ReturnPlayerInput()
	
	var can_animate = true
	var movement_multiplier = 1.0
	
	if _movementSpeed <= 0:
		movement_multiplier = 0.25
	
	if input.x < 0:
		_leftHoldTime += get_process_delta_time()
		_rightHoldTime = max(_rightHoldTime - get_process_delta_time() * 3, 0.0)
		
		if _leftHoldTime >= _turnThreshold:
			animated_sprite.animation = "Right"
			var max_time = _maxTurnTime * movement_multiplier
			var progress = min(_leftHoldTime / max_time, 1.0)
			if _movementSpeed <= 0:
				animated_sprite.frame = 0
			else:
				animated_sprite.frame = int(progress * 3)
	elif input.x > 0:
		_rightHoldTime += get_process_delta_time()
		_leftHoldTime = max(_leftHoldTime - get_process_delta_time() * 3, 0.0)
		
		if _rightHoldTime >= _turnThreshold:
			animated_sprite.animation = "Left"
			var max_time = _maxTurnTime * movement_multiplier
			var progress = min(_rightHoldTime / max_time, 1.0)
			if _movementSpeed <= 0:
				animated_sprite.frame = 0
			else:
				animated_sprite.frame = int(progress * 3)
	else:
		_leftHoldTime = max(_leftHoldTime - get_process_delta_time() * 3, 0.0)
		_rightHoldTime = max(_rightHoldTime - get_process_delta_time() * 3, 0.0)
		
		if _leftHoldTime > 0:
			animated_sprite.animation = "Right"
			var progress = min(_leftHoldTime / _maxTurnTime, 1.0)
			if _movementSpeed <= 0:
				animated_sprite.frame = 0
			else:
				animated_sprite.frame = int(progress * 3)
		elif _rightHoldTime > 0:
			animated_sprite.animation = "Left"
			var progress = min(_rightHoldTime / _maxTurnTime, 1.0)
			if _movementSpeed <= 0:
				animated_sprite.frame = 0
			else:
				animated_sprite.frame = int(progress * 3)
		else:
			animated_sprite.animation = "Idle"
			animated_sprite.frame = 0

func ReturnPlayerInput() -> Vector2:
	if _isAIControlled:
		if not Globals.raceStarted:
			return Vector2.ZERO
		return Vector2(_inputDir.x, _inputDir.y)
	else:
		if Globals.raceStarted:
			_inputDir.x = Input.get_action_strength("Left") - Input.get_action_strength("Right")
			_inputDir.y = -Input.get_action_strength("Forward")
		else:
			_inputDir = Vector2.ZERO
		return Vector2(_inputDir.x, _inputDir.y)

func play_character_sound(sound_type: String):
	match sound_type:
		"jump":
			print("Mario: Wahoo!")
		"hit":
			print("Mario: Mamma mia!")
		"win":
			print("Mario: Yahoo!")
		_:
			print("Mario: Let's-a go!")
