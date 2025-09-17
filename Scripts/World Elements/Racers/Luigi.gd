#Luigi.gd
extends Player
class_name Luigi

# Variables para animaciones progresivas
var _leftHoldTime: float = 0.0
var _rightHoldTime: float = 0.0
var _turnThreshold: float = 0.1
var _maxTurnTime: float = 1.0

# Propiedades específicas de Luigi
var character_name: String = "Luigi"

# Override para devolver AnimatedSprite2D en lugar de Sprite2D
func ReturnSpriteGraphic() -> AnimatedSprite2D:
	return _spriteGFX as AnimatedSprite2D

# Override del Update para agregar animaciones
func Update(mapForward : Vector3):
	# Llamar la lógica original de Player
	super.Update(mapForward)
	# Agregar el manejo de animaciones
	HandleAnimations()

# Sistema de animaciones progresivas mejorado
func HandleAnimations():
	var animated_sprite = ReturnSpriteGraphic()
	if !animated_sprite:
		return
	
	var input = ReturnPlayerInput()
	
	# Permitir animación incluso cuando el personaje esté quieto
	# Pero usar diferentes umbrales para movimiento vs quieto
	var can_animate = true
	var movement_multiplier = 1.0
	
	if _movementSpeed <= 0:
		# Cuando está quieto, permitir solo el primer frame de animación
		movement_multiplier = 0.25  # Solo llega al primer frame
	
	# Detectar input de giro y manejar timing progresivo - DIRECCIONES REALMENTE CORREGIDAS
	if input.x < 0:  # Input izquierda → Animación "Left"
		_leftHoldTime += get_process_delta_time()
		_rightHoldTime = max(_rightHoldTime - get_process_delta_time() * 3, 0.0)  # Retorno rápido
		
		if _leftHoldTime >= _turnThreshold:
			animated_sprite.animation = "Right"
			# Calcular frame basado en tiempo de giro
			var max_time = _maxTurnTime * movement_multiplier
			var progress = min(_leftHoldTime / max_time, 1.0)
			if _movementSpeed <= 0:
				animated_sprite.frame = 0  # Solo primer frame cuando está quieto
			else:
				animated_sprite.frame = int(progress * 3)  # 0-3 frames cuando se mueve
	elif input.x > 0:  # Input derecha → Animación "Right"
		_rightHoldTime += get_process_delta_time()
		_leftHoldTime = max(_leftHoldTime - get_process_delta_time() * 3, 0.0)  # Retorno rápido
		
		if _rightHoldTime >= _turnThreshold:
			animated_sprite.animation = "Left"
			# Calcular frame basado en tiempo de giro
			var max_time = _maxTurnTime * movement_multiplier
			var progress = min(_rightHoldTime / max_time, 1.0)
			if _movementSpeed <= 0:
				animated_sprite.frame = 0  # Solo primer frame cuando está quieto
			else:
				animated_sprite.frame = int(progress * 3)  # 0-3 frames cuando se mueve
	else:  # No hay input de giro - retorno progresivo
		# Retorno rápido hacia idle
		_leftHoldTime = max(_leftHoldTime - get_process_delta_time() * 3, 0.0)
		_rightHoldTime = max(_rightHoldTime - get_process_delta_time() * 3, 0.0)
		
		# Si todavía hay tiempo residual, mostrar animación decreciente
		if _leftHoldTime > 0:
			animated_sprite.animation = "Right"
			var progress = min(_leftHoldTime / _maxTurnTime, 1.0)
			if _movementSpeed <= 0:
				animated_sprite.frame = 0  # Solo primer frame cuando está quieto
			else:
				animated_sprite.frame = int(progress * 3)
		elif _rightHoldTime > 0:
			animated_sprite.animation = "Left"
			var progress = min(_rightHoldTime / _maxTurnTime, 1.0)
			if _movementSpeed <= 0:
				animated_sprite.frame = 0  # Solo primer frame cuando está quieto
			else:
				animated_sprite.frame = int(progress * 3)
		else:
			animated_sprite.animation = "Idle"
			animated_sprite.frame = 0

# Override ReturnPlayerInput para manejar AI correctamente
func ReturnPlayerInput() -> Vector2:
	# Si es controlado por AI, no sobrescribir el _inputDir que ya fue configurado por AIController
	if not _isAIControlled:
		_inputDir.x = Input.get_action_strength("Left") - Input.get_action_strength("Right")
		_inputDir.y = -Input.get_action_strength("Forward")
	# Para AI, _inputDir ya fue configurado por AIController, solo retornarlo
	return Vector2(_inputDir.x, _inputDir.y)

# Sonidos específicos de Luigi
func play_character_sound(sound_type: String):
	match sound_type:
		"jump":
			print("Luigi: Let's-a go!")
		"hit":
			print("Luigi: Oh no!")
		"win":
			print("Luigi: I'm-a the winner!")
		"scared":
			print("Luigi: Mamma mia!")
		_:
			print("Luigi: Here we go!")