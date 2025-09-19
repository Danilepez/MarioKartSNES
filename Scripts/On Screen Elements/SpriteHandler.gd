extends Node2D

@export var _showSpriteInRangeOf : int = 440
@export var _hazards : Array[Hazard]
var _worldElements : Array[WorldElement]
var _player : Racer

var _mapSize : int = 1024
var _worldMatrix : Basis
var _collisionHandler : Node

func Setup(worldMatrix : Basis, mapSize : int, player : Racer, collisionHandler : Node = null):
	_worldMatrix = worldMatrix
	_mapSize = mapSize
	_player = player
	if collisionHandler:
		_collisionHandler = collisionHandler
	_worldElements.append(player)
		
	if _hazards.size() == 0:
		_hazards = []
		
		var hazards_node = get_node("Hazards")
		if hazards_node:
			for group_name in ["Bridge", "Shortcut", "Lake", "Last Turn"]:
				var group_node = hazards_node.get_node_or_null(group_name)
				if group_node:
					for child in group_node.get_children():
						if child is Hazard:
							_hazards.append(child)
	
	for i in range(_hazards.size()):
		if _hazards[i] == null:
			pass
		elif not is_instance_valid(_hazards[i]):
			pass
		else:
			pass
	
	_worldElements.append_array(_hazards)
	WorldToScreenPosition(player)

func AddAIOpponent(opponent: Racer):
	if opponent and not opponent in _worldElements:
		_worldElements.append(opponent)

func Update(worldMatrix : Basis):
	_worldMatrix = worldMatrix
	
	for element in _worldElements:
		if element and is_instance_valid(element):
			HandleSpriteDetail(element)
			WorldToScreenPosition(element)
	
	var visibleHazards = 0
	for hazard in _hazards:
		if hazard and is_instance_valid(hazard):
			if hazard.ReturnSpriteGraphic().visible:
				visibleHazards += 1
	
	HandleYLayerSorting()

func HandleSpriteDetail(element : WorldElement):
	var spriteGraphic = element.ReturnSpriteGraphic()
	if !spriteGraphic:
		return
	
	var distance : float = element.ReturnMapPosition().z
	
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
		spriteGraphic.visible = true
		element.visible = true
		
		if spriteGraphic is AnimatedSprite2D:
			if not spriteGraphic.is_playing():
				spriteGraphic.play()
			spriteGraphic.scale = Vector2(3.0, 3.0)
			return
		
		if spriteGraphic is Sprite2D:
			if distance <= 0.3:
				spriteGraphic.region_rect.size = Vector2(32, 32)
			elif distance <= 0.6:
				spriteGraphic.region_rect.size = Vector2(16, 16)
			else:
				spriteGraphic.region_rect.size = Vector2(8, 8)
		return
	
	if distance > 1:
		spriteGraphic.visible = false
	else:
		spriteGraphic.visible = true

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
			if sprite_graphic.has_method("set"):
				sprite_graphic.z_index = i

func SortByScreenY(a : WorldElement, b : WorldElement) -> int:
	var aPosY : float = a.ReturnScreenPosition().y
	var bPosY : float = b.ReturnScreenPosition().y
	return aPosY < bPosY if -1 else (aPosY > bPosY if 1 else 0)

func CheckHazardCollision(playerPosition : Vector3, playerRadius : float = 16.0) -> bool:
	for hazard in _hazards:
		if hazard and is_instance_valid(hazard):
			var hazardPos = hazard.ReturnMapPosition() * _mapSize
			var playerPos = Vector2(playerPosition.x, playerPosition.z)
			var hazardPos2D = Vector2(hazardPos.x, hazardPos.z)
			
			var distance = playerPos.distance_to(hazardPos2D)
			
			var hazardRadius = 2.0
			
			if distance < (playerRadius + hazardRadius):
				return true
	
	return false

func GetHazardCollisionDirection(playerPosition : Vector3, playerRadius : float = 16.0) -> Vector3:
	for hazard in _hazards:
		if hazard and is_instance_valid(hazard):
			var hazardPos = hazard.ReturnMapPosition() * _mapSize
			var playerPos = Vector2(playerPosition.x, playerPosition.z)
			var hazardPos2D = Vector2(hazardPos.x, hazardPos.z)
			
			var distance = playerPos.distance_to(hazardPos2D)
			var hazardRadius = 4.0
			
			if distance < (playerRadius + hazardRadius):
				var pushDirection = (playerPos - hazardPos2D).normalized()
				return Vector3(pushDirection.x, 0, pushDirection.y)
	
	return Vector3.ZERO

func WorldToScreenPosition(worldElement : WorldElement):
	var transformedPos : Vector3 = _worldMatrix.inverse() * Vector3(worldElement.ReturnMapPosition().x, worldElement.ReturnMapPosition().z, 1.0)
	
	if (transformedPos.z < 0.0):
		worldElement.SetScreenPosition(Vector2i(-1000, -1000)) 
		return  
	
	var screenPos : Vector2 = Vector2(transformedPos.x / transformedPos.z, transformedPos.y / transformedPos.z) 
	screenPos = (screenPos + Vector2(0.5, 0.5)) * Globals.screenSize
	
	var sprite_graphic = worldElement.ReturnSpriteGraphic()
	if sprite_graphic is Sprite2D:
		var sprite_2d = sprite_graphic as Sprite2D
		screenPos.y -= (sprite_2d.region_rect.size.y * sprite_2d.scale.x) / 2
	elif sprite_graphic is AnimatedSprite2D:
		var animated_sprite = sprite_graphic as AnimatedSprite2D
		var sprite_size = animated_sprite.sprite_frames.get_frame_texture(animated_sprite.animation, animated_sprite.frame).get_size()
		screenPos.y -= (sprite_size.y * animated_sprite.scale.x) / 2
	else:
		pass
	
	if(screenPos.floor().x > Globals.screenSize.x or screenPos.x < 0 or screenPos.floor().y > Globals.screenSize.y or screenPos.y < 0): 
		worldElement.visible = false
		worldElement.SetScreenPosition(Vector2i(-1000, -1000)) 
		pass
		return  
	else:
		worldElement.SetScreenPosition(Vector2i(screenPos.floor()))
		pass

func AddOpponent(opponent: Racer):
	if not opponent:
		return
		
	if not _worldElements.has(opponent):
		_worldElements.append(opponent)

func AddSimpleOpponent(opponent: SimpleOpponent):
	if not opponent:
		return
		
	if not _worldElements.has(opponent):
		_worldElements.append(opponent)
