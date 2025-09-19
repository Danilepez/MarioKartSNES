extends Control

@export var _mapBackground : TextureRect
@export var _playerIcon : Control
@export var _mapTexture : Texture2D
var _mapSize : Vector2 = Vector2.ZERO
var _player : Racer
var _opponents : Array[Racer] = []
var _opponentIcons : Array[Control] = []

func Setup(player : Racer, mapTexture : Texture2D):
	_player = player
	_mapTexture = mapTexture
	_mapSize = _mapTexture.get_size()
	
	if _mapBackground:
		_mapBackground.texture = _mapTexture
		_mapBackground.size = size
		_mapBackground.position = Vector2.ZERO
	
	if _playerIcon:
		_playerIcon.size = Vector2(6, 6)

func AddOpponent(opponent: Racer):
	if opponent in _opponents:
		return
	
	_opponents.append(opponent)
	
	var opponentIcon = ColorRect.new()
	opponentIcon.size = Vector2(4, 4)
	opponentIcon.color = get_opponent_color(_opponents.size() - 1)
	add_child(opponentIcon)
	_opponentIcons.append(opponentIcon)
	
func get_opponent_color(index: int) -> Color:
	var colors = [Color.BLUE, Color.GREEN, Color.YELLOW, Color.MAGENTA, Color.CYAN]
	return colors[index % colors.size()]

func UpdateMinimap():
	if not _player or not _playerIcon or not _mapBackground:
		return
	
	update_icon_position(_player, _playerIcon)
	
	for i in range(_opponents.size()):
		if i < _opponentIcons.size() and _opponents[i]:
			update_icon_position(_opponents[i], _opponentIcons[i])

func update_icon_position(racer: Racer, icon: Control):
	if not racer or not icon:
		return
	
	var racerMapPos : Vector3 = racer._mapPosition
	
	var normalizedX = racerMapPos.x / _mapSize.x
	var normalizedZ = racerMapPos.z / _mapSize.y
	
	var iconPosX = normalizedX * size.x
	var iconPosZ = normalizedZ * size.y
	
	var iconSize = icon.size
	var finalPos = Vector2(iconPosX - iconSize.x/2, iconPosZ - iconSize.y/2)
	
	icon.position = finalPos