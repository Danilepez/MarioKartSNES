#Minimap.gd
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
	
	print("=== MINIMAP SETUP ===")
	print("Tamaño del mapa: ", _mapSize)
	print("Tamaño del minimapa: ", size)
	
	# Configurar el fondo del minimapa - mostrar TODO el mapa
	if _mapBackground:
		_mapBackground.texture = _mapTexture
		_mapBackground.size = size
		_mapBackground.position = Vector2.ZERO
		print("Minimapa configurado con textura del mapa completo")
	
	# Configurar el ícono del jugador - punto rojo más pequeño
	if _playerIcon:
		_playerIcon.size = Vector2(6, 6)
		print("Ícono del jugador configurado (6x6 píxeles)")

func AddOpponent(opponent: Racer):
	if opponent in _opponents:
		return
	
	_opponents.append(opponent)
	
	# Create opponent icon
	var opponentIcon = ColorRect.new()
	opponentIcon.size = Vector2(4, 4)
	opponentIcon.color = get_opponent_color(_opponents.size() - 1)
	add_child(opponentIcon)
	_opponentIcons.append(opponentIcon)
	
	print("🗺️ Opponent added to minimap: ", opponent.name if opponent.name else "Unknown")

func get_opponent_color(index: int) -> Color:
	var colors = [Color.BLUE, Color.GREEN, Color.YELLOW, Color.MAGENTA, Color.CYAN]
	return colors[index % colors.size()]

func UpdateMinimap():
	if not _player or not _playerIcon or not _mapBackground:
		return
	
	# Update player position
	update_icon_position(_player, _playerIcon)
	
	# Update opponent positions
	for i in range(_opponents.size()):
		if i < _opponentIcons.size() and _opponents[i]:
			update_icon_position(_opponents[i], _opponentIcons[i])

func update_icon_position(racer: Racer, icon: Control):
	if not racer or not icon:
		return
	
	# Obtener la posición del racer en coordenadas del mundo
	var racerMapPos : Vector3 = racer._mapPosition
	
	# Convertir directamente basándose en el tamaño del mapa
	# Las coordenadas van de 0 a tamaño del mapa
	var normalizedX = racerMapPos.x / _mapSize.x
	var normalizedZ = racerMapPos.z / _mapSize.y
	
	# Convertir a coordenadas del minimapa
	var iconPosX = normalizedX * size.x
	var iconPosZ = normalizedZ * size.y
	
	# Centrar el ícono
	var iconSize = icon.size
	var finalPos = Vector2(iconPosX - iconSize.x/2, iconPosZ - iconSize.y/2)
	
	# NO limitar dentro del área - permitir que se salga como antes
	# para mantener la precisión del movimiento
	icon.position = finalPos
	
	# Debug menos frecuente solo para el jugador
	if racer == _player and randf() < 0.005:
		print("=== MINIMAP DEBUG ===")
		print("Pos jugador mundo: (", racerMapPos.x, ", ", racerMapPos.z, ")")
		print("Normalizado: (", normalizedX, ", ", normalizedZ, ")")
		print("Pos en minimapa: ", finalPos)
		print("Tamaño minimapa: ", size)