#SpriteHandler.gd
extends Node2D

@export var _showSpriteInRangeOf : int = 440
@export var _hazards : Array[Hazard]
var _worldElements : Array[WorldElement]
var _player : Racer

var _mapSize : int = 1024
var _worldMatrix : Basis
var _collisionHandler : Node  # Referencia al collision handler para usar road type map

func Setup(worldMatrix : Basis, mapSize : int, player : Racer, collisionHandler : Node = null):
	_worldMatrix = worldMatrix
	_mapSize = mapSize
	_player = player
	if collisionHandler:
		_collisionHandler = collisionHandler
	_worldElements.append(player)
	
	# Debug: Verificar que los hazards se cargaron desde el array exportado
	print("=== SPRITEHANDLER SETUP ===")
	print("Array _hazards configurado desde editor tiene ", _hazards.size(), " elementos")
	
	# Si el array está vacío, buscar hazards automáticamente en la escena
	if _hazards.size() == 0:
		print("Array vacío - buscando hazards automáticamente en la escena...")
		_hazards = []
		
		# Buscar en el nodo Hazards
		var hazards_node = get_node("Hazards")
		if hazards_node:
			print("Encontrado nodo Hazards, buscando grupos...")
			
			# Buscar en todos los grupos de hazards
			for group_name in ["Bridge", "Shortcut", "Lake", "Last Turn"]:
				var group_node = hazards_node.get_node_or_null(group_name)
				if group_node:
					print("  Grupo encontrado: ", group_name)
					for child in group_node.get_children():
						if child is Hazard:
							_hazards.append(child)
							print("    Añadido hazard: ", child.name, " en ", child.ReturnMapPosition())
						else:
							print("    Nodo ignorado (no es Hazard): ", child.name, " tipo: ", child.get_class())
				else:
					print("  Grupo NO encontrado: ", group_name)
		else:
			print("ERROR: Nodo Hazards no encontrado!")
	
	# Verificar cada hazard individualmente
	print("Verificando hazards finales...")
	for i in range(_hazards.size()):
		if _hazards[i] == null:
			print("Hazard[", i, "]: ES NULL!")
		elif not is_instance_valid(_hazards[i]):
			print("Hazard[", i, "]: NO ES VÁLIDO!")
		else:
			print("Hazard[", i, "]: ", _hazards[i].name, " en posición ", _hazards[i].ReturnMapPosition())
	
	print("Intentando agregar ", _hazards.size(), " hazards a worldElements...")
	_worldElements.append_array(_hazards)
	print("Total worldElements después: ", _worldElements.size())
	
	WorldToScreenPosition(player)

func AddAIOpponent(opponent: Racer):
	if opponent and not opponent in _worldElements:
		_worldElements.append(opponent)
		print("🖼️ AI opponent added to SpriteHandler: ", opponent.name)

func Update(worldMatrix : Basis):
	_worldMatrix = worldMatrix
	
	# Update all world elements (player, AI opponents, hazards)
	for element in _worldElements:
		if element and is_instance_valid(element):
			HandleSpriteDetail(element)
			WorldToScreenPosition(element)
	
	var visibleHazards = 0
	for hazard in _hazards:
		if hazard and is_instance_valid(hazard):
			if hazard.ReturnSpriteGraphic().visible:
				visibleHazards += 1
	
	# Debug cada 60 frames (aproximadamente 1 segundo)
	if Engine.get_process_frames() % 60 == 0:
		print("Frame ", Engine.get_process_frames(), ": ", visibleHazards, " hazards visibles de ", _hazards.size(), " total, ", _worldElements.size(), " elementos totales")
	
	HandleYLayerSorting()

func HandleSpriteDetail(element : WorldElement):
	var spriteGraphic = element.ReturnSpriteGraphic()
	if !spriteGraphic:
		return
	
	var distance : float = element.ReturnMapPosition().z
	
	# Special handling for AI opponents and player characters - keep them always visible
	var is_character = false
	if element.has_method("GetCharacterName"):
		is_character = true
	elif element.get_script():
		var script_name = element.get_script().get_global_name()
		if script_name in ["Mario", "Luigi", "Bowser", "DonkeyKong", "Yoshi", "Player"]:
			is_character = true
	elif element.has_node("AIBehavior"):
		is_character = true
	
	if is_character:
		# Always keep characters visible
		spriteGraphic.visible = true
		element.visible = true
		
		# Handle AnimatedSprite2D - set proper scale for visibility
		if spriteGraphic is AnimatedSprite2D:
			# Ensure the AnimatedSprite2D is playing and visible
			if not spriteGraphic.is_playing():
				spriteGraphic.play()
			# Set larger scale for better visibility (3.0 as requested)
			spriteGraphic.scale = Vector2(3.0, 3.0)
			return
		
		# For Sprite2D characters, handle region adjustments
		if spriteGraphic is Sprite2D:
			if distance <= 0.3:
				spriteGraphic.region_rect.size = Vector2(32, 32)
			elif distance <= 0.6:
				spriteGraphic.region_rect.size = Vector2(16, 16)
			else:
				spriteGraphic.region_rect.size = Vector2(8, 8)
		return
	
	# Regular sprite handling for other elements (hazards, etc.) - revert to original behavior
	if distance > 1:
		spriteGraphic.visible = false
	else:
		spriteGraphic.visible = true
		# Remove region_rect adjustments that were making hazards too large
		# Let hazards use their original size

func HandleYLayerSorting():
	_worldElements.sort_custom(SortByScreenY)
	for i in range(_worldElements.size()):
		var element = _worldElements[i]
		var sprite_graphic = element.ReturnSpriteGraphic()
		if sprite_graphic is Sprite2D:
			(sprite_graphic as Sprite2D).z_index = i
		elif sprite_graphic is AnimatedSprite2D:
			(sprite_graphic as AnimatedSprite2D).z_index = i
		else:
			# Fallback para otros tipos que tengan z_index
			if sprite_graphic.has_method("set"):
				sprite_graphic.z_index = i

func SortByScreenY(a : WorldElement, b : WorldElement) -> int:
	var aPosY : float = a.ReturnScreenPosition().y
	var bPosY : float = b.ReturnScreenPosition().y
	return aPosY < bPosY if -1 else (aPosY > bPosY if 1 else 0)

func CheckHazardCollision(playerPosition : Vector3, playerRadius : float = 16.0) -> bool:
	# Verificar colisión con cada hazard usando radio (revertido temporalmente)
	for hazard in _hazards:
		if hazard and is_instance_valid(hazard):
			var hazardPos = hazard.ReturnMapPosition() * _mapSize
			var playerPos = Vector2(playerPosition.x, playerPosition.z)
			var hazardPos2D = Vector2(hazardPos.x, hazardPos.z)
			
			# Calcular distancia entre player y hazard
			var distance = playerPos.distance_to(hazardPos2D)
			
			# Radio del hazard muy reducido para colisión ultra precisa
			var hazardRadius = 2.0
			
			if distance < (playerRadius + hazardRadius):
				return true  # Hay colisión
	
	return false  # No hay colisión

# Función para obtener la dirección de empuje al colisionar con un hazard
func GetHazardCollisionDirection(playerPosition : Vector3, playerRadius : float = 16.0) -> Vector3:
	# Usar el método de radio (revertido temporalmente)
	for hazard in _hazards:
		if hazard and is_instance_valid(hazard):
			var hazardPos = hazard.ReturnMapPosition() * _mapSize
			var playerPos = Vector2(playerPosition.x, playerPosition.z)
			var hazardPos2D = Vector2(hazardPos.x, hazardPos.z)
			
			var distance = playerPos.distance_to(hazardPos2D)
			var hazardRadius = 4.0  # Radio consistente
			
			if distance < (playerRadius + hazardRadius):
				# Calcular dirección de empuje (desde hazard hacia player)
				var pushDirection = (playerPos - hazardPos2D).normalized()
				return Vector3(pushDirection.x, 0, pushDirection.y)
	
	return Vector3.ZERO

func WorldToScreenPosition(worldElement : WorldElement):
	var transformedPos : Vector3 = _worldMatrix.inverse() * Vector3(worldElement.ReturnMapPosition().x, worldElement.ReturnMapPosition().z, 1.0)
	
	# Debug específico para hazards cada 2 segundos
	if worldElement is Hazard and Engine.get_process_frames() % 120 == 0:
		print("Debug hazard: ", worldElement.name, " pos: ", worldElement.ReturnMapPosition(), " transformed: ", transformedPos)
	
	if (transformedPos.z < 0.0):
		worldElement.SetScreenPosition(Vector2i(-1000, -1000)) 
		return  
	
	var screenPos : Vector2 = Vector2(transformedPos.x / transformedPos.z, transformedPos.y / transformedPos.z) 
	screenPos = (screenPos + Vector2(0.5, 0.5)) * Globals.screenSize
	
	# Manejar diferentes tipos de sprites
	var sprite_graphic = worldElement.ReturnSpriteGraphic()
	if sprite_graphic is Sprite2D:
		# Para Sprite2D (hazards) usar region_rect
		var sprite_2d = sprite_graphic as Sprite2D
		screenPos.y -= (sprite_2d.region_rect.size.y * sprite_2d.scale.x) / 2
	elif sprite_graphic is AnimatedSprite2D:
		# Para AnimatedSprite2D (player characters) usar el tamaño del frame actual
		var animated_sprite = sprite_graphic as AnimatedSprite2D
		var sprite_size = animated_sprite.sprite_frames.get_frame_texture(animated_sprite.animation, animated_sprite.frame).get_size()
		screenPos.y -= (sprite_size.y * animated_sprite.scale.x) / 2
	else:
		# Fallback para otros tipos
		print("Warning: Unknown sprite type: ", sprite_graphic.get_class())
	
	if(screenPos.floor().x > Globals.screenSize.x or screenPos.x < 0 or screenPos.floor().y > Globals.screenSize.y or screenPos.y < 0): 
		worldElement.visible = false
		worldElement.SetScreenPosition(Vector2i(-1000, -1000)) 
		if worldElement is Hazard and Engine.get_process_frames() % 120 == 0:
			print("  -> FUERA DE PANTALLA: ", screenPos, " (screen size: ", Globals.screenSize, ")")
		return  
	else:
		worldElement.SetScreenPosition(Vector2i(screenPos.floor()))
		if worldElement is Hazard and Engine.get_process_frames() % 120 == 0:
			print("  -> VISIBLE en pantalla: ", screenPos.floor())

func AddOpponent(opponent: Racer):
	# Verificar que el oponente es válido
	if not opponent:
		print("❌ Error: Oponente es null, no se puede agregar")
		return
		
	# Agregar oponente a la lista de elementos del mundo
	if not _worldElements.has(opponent):
		_worldElements.append(opponent)
		print("✅ Oponente agregado al SpriteHandler: ", opponent.name)
	else:
		print("⚠️ Oponente ya existe en SpriteHandler: ", opponent.name)

func AddSimpleOpponent(opponent: SimpleOpponent):
	# Verificar que el oponente simple es válido
	if not opponent:
		print("❌ Error: Oponente simple es null, no se puede agregar")
		return
		
	# Agregar oponente simple a la lista de elementos del mundo
	if not _worldElements.has(opponent):
		_worldElements.append(opponent)
		print("✅ Oponente simple agregado al SpriteHandler: ", opponent.character_name)
	else:
		print("⚠️ Oponente simple ya existe en SpriteHandler: ", opponent.character_name)
