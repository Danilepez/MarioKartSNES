#Game.gd
extends Node2D
@export var _map : Node2D
@export var _collision : Node
var _player : Racer  # Removido @export - se asigna dinámicamente
@export var _spriteHandler : Node2D
@export var _animationHandler : Node
@export var _backgroundElements : Node2D
@export var _minimap : Control

var _debugLabel : Label
var _victoryScreen : Control
var _victoryVideoPlayer : VideoStreamPlayer
var _victoryAnimationPlayer : AnimationPlayer
var _pulsingTween : Tween
var _isVictoryScreenActive : bool = false
var _tKeyPressed : bool = false
var _vKeyPressed : bool = false

# Variables para sistema de oponentes AI
var _ai_opponents : Array[AIOpponent] = []
var _ai_opponent_script = preload("res://Scripts/World Elements/Racers/AIOpponent.gd")
var _available_characters : Array[String] = ["mario", "luigi", "bowser", "donkikon"]
var _opponents_created : bool = false
var _frame_counter : int = 0
var _navigation_region : NavigationRegion2D

func _ready():
	print("=== INICIANDO GAME.GD ===")
	print("Globals.selected_character al inicio: ", Globals.selected_character)
	
	# Configurar el personaje seleccionado ANTES de todo lo demás
	_setup_selected_character()
	
	# Verificar que _player fue asignado correctamente antes de continuar
	if not _player:
		print("ERROR CRITICO: _player no fue asignado en _setup_selected_character!")
		return
	
	print("Continuando con inicialización del juego...")
	_map.Setup(Globals.screenSize, _player)
	_collision.Setup()
	_spriteHandler.Setup(_map.ReturnWorldMatrix(), _map.texture.get_size().x, _player, _collision)
	_player.Setup(_map.texture.get_size().x, _spriteHandler)  # Pasar SpriteHandler al Player
	
	# Setup animation handler - ensure it updates when player changes
	if _animationHandler and _player:
		_animationHandler.Setup(_player)
		print("✅ AnimationHandler configurado para: ", _player.name)
	_minimap.Setup(_player, _map.texture)
	
	# Configurar debug label
	_debugLabel = $UI/Debug/PositionLabel
	
	# Configurar pantalla de victoria
	setup_victory_screen()
	
	# Añadir este nodo al grupo para recibir notificaciones
	add_to_group("game_manager")
	
	# Inicializar tiempo de carrera
	Globals.raceStartTime = Time.get_ticks_msec()
	
	# Setup navigation region for AI pathfinding
	setup_navigation_region()
	
	# Los oponentes AI se crearán en _process() para asegurar que se muestren
	print("🏁 Oponentes AI se crearán en _process()...")
	
	print("=== JUEGO INICIALIZADO ===")
	print("Tamaño de pantalla del juego: ", Globals.screenSize)
	print("Tamaño del mapa: ", _map.texture.get_size())
	print("Sistema de vueltas inicializado - Meta: ", Globals.finishLinePosition, " | Checkpoint: ", Globals.checkpointPosition)
	print("Personaje final en uso: ", _player.name if _player else "ERROR - NULL")
	print("Script del personaje: ", _player.get_script().get_global_name() if _player and _player.get_script() else "sin script")

func _setup_selected_character():
	print("=== DEBUG: Iniciando _setup_selected_character ===")
	print("Globals.selected_character = ", Globals.selected_character)
	
	# Obtener referencias a todos los personajes
	var mario_node = $"Sprite Handler/Racers/Mario"
	var luigi_node = $"Sprite Handler/Racers/Luigi"
	var bowser_node = $"Sprite Handler/Racers/Bowser"
	var donkey_kong_node = $"Sprite Handler/Racers/DonkeyKong"
	var yoshi_node = $"Sprite Handler/Racers/Yoshi"
	
	# Verificar que existan los nodos principales (Mario y Luigi son esenciales)
	if not mario_node:
		print("ERROR: Nodo Mario no encontrado!")
		return
	if not luigi_node:
		print("ERROR: Nodo Luigi no encontrado!")
		return
	
	print("Nodos encontrados - Mario: ", mario_node.name, " Luigi: ", luigi_node.name)
	if bowser_node:
		print("Bowser encontrado: ", bowser_node.name, " - Script: ", bowser_node.get_script().get_global_name() if bowser_node.get_script() else "sin script")
	else:
		print("ERROR: Nodo Bowser NO encontrado!")
	if donkey_kong_node:
		print("Donkey Kong encontrado: ", donkey_kong_node.name, " - Script: ", donkey_kong_node.get_script().get_global_name() if donkey_kong_node.get_script() else "sin script")
	else:
		print("ERROR: Nodo Donkey Kong NO encontrado!")
	if yoshi_node:
		print("Yoshi encontrado: ", yoshi_node.name, " - Script: ", yoshi_node.get_script().get_global_name() if yoshi_node.get_script() else "sin script")
	else:
		print("ERROR: Nodo Yoshi NO encontrado!")
	
	# Ocultar todos los personajes primero
	mario_node.visible = false
	luigi_node.visible = false
	if bowser_node:
		bowser_node.visible = false
	if donkey_kong_node:
		donkey_kong_node.visible = false
	if yoshi_node:
		yoshi_node.visible = false
	
	# Activar el personaje seleccionado
	print("Seleccionando personaje: '", Globals.selected_character, "'")
	match Globals.selected_character:
		"Luigi":
			luigi_node.visible = true
			_player = luigi_node
			print("✓ Luigi configurado como jugador principal")
		"Bowser":
			if bowser_node:
				bowser_node.visible = true
				_player = bowser_node
				print("✓ Bowser configurado como jugador principal")
			else:
				print("✗ ERROR: Bowser no encontrado, usando Mario por defecto")
				mario_node.visible = true
				_player = mario_node
		"DonkeyKong":
			if donkey_kong_node:
				donkey_kong_node.visible = true
				_player = donkey_kong_node
				print("✓ Donkey Kong configurado como jugador principal")
			else:
				print("✗ ERROR: Donkey Kong no encontrado, usando Mario por defecto")
				mario_node.visible = true
				_player = mario_node
		"Yoshi":
			if yoshi_node:
				yoshi_node.visible = true
				_player = yoshi_node
				print("✓ Yoshi configurado como jugador principal")
			else:
				print("✗ ERROR: Yoshi no encontrado, usando Mario por defecto")
				mario_node.visible = true
				_player = mario_node
		_:  # Mario por defecto
			mario_node.visible = true
			_player = mario_node
			print("✓ Mario configurado como jugador principal (por defecto)")
	
	# Verificar que _player esté correctamente asignado
	if not _player:
		print("ERROR: _player no fue asignado correctamente!")
		return
	
	# Re-setup animation handler when player changes
	if _animationHandler and _player:
		_animationHandler.Setup(_player)
		print("✅ AnimationHandler reconfigurado para nuevo jugador: ", _player.name)
	
	# Ensure proper sprite scale for player visibility
	var player_sprite = _player.ReturnSpriteGraphic()
	if player_sprite and player_sprite is AnimatedSprite2D:
		player_sprite.scale = Vector2(3.0, 3.0)
		print("✅ Set player sprite scale to 3.0 for: ", _player.name)
		
	print("=== DEBUG: _setup_selected_character completado ===")
	print("Jugador final (_player): ", _player.name if _player else "null")
	print("Tipo de _player: ", _player.get_script().get_global_name() if _player and _player.get_script() else "sin script")

func _process(delta):
	# Crear oponentes AI después de unos frames para asegurar que todo esté listo
	_frame_counter += 1
	if not _opponents_created and _frame_counter > 60:  # Después de 60 frames (1 segundo)
		print("🎮 CREANDO OPONENTES AI EN _PROCESS - Frame: ", _frame_counter)
		print("🎮 Player actual: ", _player.name if _player else "NULL")
		print("🎮 Selected character: ", Globals.selected_character)
		_create_ai_opponents()
		_opponents_created = true
		print("✅ Oponentes AI creados exitosamente en _process()")
	
	
	if _isVictoryScreenActive:
		# Solo procesar input para reiniciar si la pantalla de victoria está activa
		if Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_SPACE):
			restart_race()
		return
	
	# Funciones de testing:
	# Presionar T para simular completar una vuelta (solo una vez por presión)
	if Input.is_key_pressed(KEY_T):
		if !_tKeyPressed and !Globals.raceFinished:
			_tKeyPressed = true
			simulate_lap_completion()
	else:
		_tKeyPressed = false
	
	# Presionar V para forzar mostrar pantalla de victoria (solo una vez por presión)
	if Input.is_key_pressed(KEY_V):
		if !_vKeyPressed and !_isVictoryScreenActive:
			_vKeyPressed = true
			force_victory_for_testing()
	else:
		_vKeyPressed = false
	
	# PRUEBA TEMPORAL - Presiona ESPACIO para cambiar personajes (solo si no hay victoria)
	if Input.is_action_just_pressed("ui_accept"):
		test_next_character()
	
	_map.Update(_player)
	_player.Update(_map.ReturnForward())
	
	# Update AI opponents in same loop as player for physics consistency
	for i in range(_ai_opponents.size()):
		var opponent = _ai_opponents[i]
		if opponent and is_instance_valid(opponent):
			# Debug AI state before update
			var pos_before = opponent._mapPosition
			var speed_before = opponent._movementSpeed
			var input_before = opponent._inputDir
			
			# Try the new enhanced AI controller first
			var ai_controller = opponent.get_node("AIController")
			if ai_controller and ai_controller.has_method("update_ai_behavior"):
				ai_controller.update_ai_behavior(_map.ReturnForward())
				
				# Debug AI state after update every 60 frames
				if Engine.get_process_frames() % 60 == 0:
					var pos_after = opponent._mapPosition
					var speed_after = opponent._movementSpeed
					var velocity = opponent.ReturnVelocity()
					var move_dir = opponent._currentMoveDirection
					print("🔍 AI %s UPDATE: Pos(%.0f,%.0f→%.0f,%.0f) Speed(%.1f→%.1f) Vel(%.3f,%.3f,%.3f) Dir:%d" % [
						opponent.name, pos_before.x, pos_before.z, pos_after.x, pos_after.z,
						speed_before, speed_after, velocity.x, velocity.y, velocity.z, move_dir
					])
			else:
				print("⚠️ AI Controller not found or missing method for: ", opponent.name)
				# Fallback to old AIBehavior if it exists
				var ai_behavior = opponent.get_node("AIBehavior")
				if ai_behavior and ai_behavior.has_method("update_ai_behavior"):
					ai_behavior.update_ai_behavior(_map.ReturnForward())
		else:
			print("⚠️ Invalid AI opponent at index: ", i)
	
	# Debug AI status every 60 frames (1 second) for more frequent updates
	if Engine.get_process_frames() % 60 == 0 and _ai_opponents.size() > 0:
		print("🏎️ AI STATUS - Frame: ", Engine.get_process_frames(), " | Active opponents: ", _ai_opponents.size())
		for i in range(_ai_opponents.size()):
			var opponent = _ai_opponents[i]
			if opponent and is_instance_valid(opponent):
				var pos = opponent._mapPosition
				var speed = opponent._movementSpeed
				var input_dir = opponent._inputDir
				var visible = opponent.visible
				print("  🤖 %s: Pos(%.0f,%.0f) Speed:%.1f Input:(%.2f,%.2f) Visible:%s" % [opponent.name, pos.x, pos.z, speed, input_dir.x, input_dir.y, visible])
	
	# Verify player scale every 300 frames (5 seconds)
	if Engine.get_process_frames() % 300 == 0:
		var player_sprite = _player.ReturnSpriteGraphic()
		if player_sprite:
			print("🎮 Player ", _player.name, " sprite scale: ", player_sprite.scale)
	
	_spriteHandler.Update(_map.ReturnWorldMatrix())
	_animationHandler.Update()
	_backgroundElements.Update(_map.ReturnMapRotation())
	_minimap.UpdateMinimap()
	
	# Actualizar debug info
	if _debugLabel:
		var playerPos = _player._mapPosition
		var playerPos2D = Vector2(playerPos.x, playerPos.z)
		var lapInfo = "Vuelta: %d/%d" % [Globals.currentLap, Globals.totalLaps]
		var checkpointStatus = "CP: " + ("✓" if Globals.hasPassedCheckpoint else "✗")
		var raceStatus = "Estado: " + ("FINISH" if Globals.raceFinished else "RACING")
		var distanceToFinish = playerPos2D.distance_to(Globals.finishLinePosition)
		var distanceToCheckpoint = playerPos2D.distance_to(Globals.checkpointPosition)
		var victoryStatus = "Victoria: " + ("SÍ" if _isVictoryScreenActive else "NO")
		
		# Información de progreso más detallada
		var nextTarget = "→ " + ("META (64,64)" if Globals.hasPassedCheckpoint else "CHECKPOINT (500,350)")
		var nextDistance = distanceToCheckpoint if !Globals.hasPassedCheckpoint else distanceToFinish
		var progressIndicator = "🔥" if nextDistance < 120 else "●"
		
		var raceTime = (Time.get_ticks_msec() - Globals.raceStartTime) / 1000.0
		var distanceText = "Distancia a META: %.0f" % distanceToFinish
		var proximityIcon = "🔥" if distanceToFinish < 100 else "○"
		_debugLabel.text = "Pos: (%.0f, %.0f) | Speed: %.1f | %s\n%s | %s | Tiempo: %.1fs\n%s %s\n%s %s\nTEST: V=Victoria, T=Vuelta, SPACE=Cambiar personaje" % [playerPos.x, playerPos.z, _player.ReturnMovementSpeed(), Globals.selected_character, lapInfo, raceStatus, raceTime, proximityIcon, distanceText, victoryStatus, "Meta en: (64,64)"]

# Configurar la pantalla de victoria con video
func setup_victory_screen():
	print("=== CONFIGURANDO PANTALLA DE VICTORIA CON VIDEO ===")
	
	# Crear la pantalla de victoria
	_victoryScreen = Control.new()
	_victoryScreen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_victoryScreen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Fondo negro completo
	var background = ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color.BLACK
	_victoryScreen.add_child(background)
	
	# Crear contenedor para controlar el tamaño del video
	var videoContainer = AspectRatioContainer.new()
	videoContainer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	videoContainer.stretch_mode = AspectRatioContainer.STRETCH_FIT
	videoContainer.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	videoContainer.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	
	# Crear el reproductor de video
	_victoryVideoPlayer = VideoStreamPlayer.new()
	_victoryVideoPlayer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_victoryVideoPlayer.expand = true
	
	# Añadir el video al contenedor
	videoContainer.add_child(_victoryVideoPlayer)
	
	print("📺 Video configurado con AspectRatioContainer")
	
	# Cargar el video en formato OGV (compatible con Godot)
	var videoPath = "res://imagenes_final/yoshiVictory.ogv"
	print("🔍 Intentando cargar video desde: ", videoPath)
	
	# Verificar si el archivo existe
	if ResourceLoader.exists(videoPath):
		print("✅ Archivo encontrado, cargando...")
		
		# Intentar cargar como recurso
		var videoStream = load(videoPath)
		if videoStream != null:
			print("✅ Video cargado como recurso")
			_victoryVideoPlayer.stream = videoStream
			_victoryVideoPlayer.autoplay = false
			_victoryVideoPlayer.loop = true
		else:
			print("❌ Error al cargar video como recurso")
			# Fallback: crear VideoStreamTheora manualmente
			var theoraStream = VideoStreamTheora.new()
			theoraStream.file = videoPath
			_victoryVideoPlayer.stream = theoraStream
			_victoryVideoPlayer.autoplay = false
			_victoryVideoPlayer.loop = true
			print("🔄 Usando VideoStreamTheora como fallback")
	else:
		print("❌ Video no encontrado en: ", videoPath)
		print("🔍 Verificando archivos disponibles...")
		# Mostrar qué archivos hay disponibles para debug
		var dir = DirAccess.open("res://imagenes_final/")
		if dir:
			dir.list_dir_begin()
			var fileName = dir.get_next()
			while fileName != "":
				print("📁 Archivo encontrado: ", fileName)
				fileName = dir.get_next()
			dir.list_dir_end()
	
	_victoryScreen.add_child(videoContainer)
	
	# Texto de instrucciones sobre el video
	var instructionLabel = Label.new()
	instructionLabel.text = "Presiona ENTER para jugar de nuevo"
	instructionLabel.add_theme_color_override("font_color", Color.WHITE)
	instructionLabel.add_theme_font_size_override("font_size", 24)
	instructionLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructionLabel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instructionLabel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	instructionLabel.position = Vector2(-300, -50)
	instructionLabel.size = Vector2(600, 40)
	_victoryScreen.add_child(instructionLabel)
	
	# Añadir a la escena
	$UI.add_child(_victoryScreen)
	_victoryScreen.visible = false
	print("✅ Pantalla de victoria con video configurada")

# Iniciar la animación de palpitación
# Función de fallback si el video no funciona
func create_fallback_victory_text():
	print("🔄 Creando texto de fallback para la victoria...")
	
	# Crear texto de YOU WIN
	var youWinLabel = Label.new()
	youWinLabel.text = "¡YOU WIN!"
	youWinLabel.add_theme_font_size_override("font_size", 72)
	youWinLabel.add_theme_color_override("font_color", Color.YELLOW)
	youWinLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	youWinLabel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	youWinLabel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	youWinLabel.position = Vector2(-300, -100)
	youWinLabel.size = Vector2(600, 100)
	_victoryScreen.add_child(youWinLabel)
	
	# Crear texto de PRIMER LUGAR
	var firstPlaceLabel = Label.new()
	firstPlaceLabel.text = "🏆 PRIMER LUGAR 🏆"
	firstPlaceLabel.add_theme_font_size_override("font_size", 48)
	firstPlaceLabel.add_theme_color_override("font_color", Color.GOLD)
	firstPlaceLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	firstPlaceLabel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	firstPlaceLabel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	firstPlaceLabel.position = Vector2(-300, 0)
	firstPlaceLabel.size = Vector2(600, 80)
	_victoryScreen.add_child(firstPlaceLabel)
	
	print("✅ Texto de fallback creado")

# Mostrar la pantalla de victoria
func show_victory_screen():
	print("=== MOSTRANDO VICTORIA CON VIDEO ===")
	if _isVictoryScreenActive:
		print("Victoria ya activa")
		return
		
	if not _victoryScreen:
		print("Error: Pantalla de victoria no existe")
		return
		
	_isVictoryScreenActive = true
	_victoryScreen.visible = true
	
	# Reproducir el video de victoria
	if _victoryVideoPlayer:
		if _victoryVideoPlayer.stream:
			print("🎬 Reproduciendo video de victoria...")
			_victoryVideoPlayer.play()
			print("📺 Estado del reproductor: ", _victoryVideoPlayer.get_stream_name())
		else:
			print("❌ No hay stream de video cargado")
			# Crear texto de fallback si no hay video
			create_fallback_victory_text()
	else:
		print("❌ VideoStreamPlayer no existe")
		create_fallback_victory_text()
	
	print("✅ Victoria con video activada - ENTER para reiniciar")

# Función para simular completar una vuelta (testing)
func simulate_lap_completion():
	print("=== SIMULANDO VUELTA ===")
	if Globals.raceFinished:
		print("La carrera ya terminó")
		return
		
	Globals.currentLap += 1
	print("Vuelta: ", Globals.currentLap, "/", Globals.totalLaps)
	
	if Globals.currentLap >= Globals.totalLaps:
		Globals.raceFinished = true
		print("¡Carrera terminada! Mostrando victoria...")
		show_victory_screen()
		
# Función simple para mostrar pantalla de victoria
func force_victory_for_testing():
	print("=== FORZANDO VICTORIA ===")
	if _isVictoryScreenActive:
		print("La pantalla ya está activa")
		return
	Globals.raceFinished = true
	show_victory_screen()

# Reiniciar la carrera
func restart_race():
	print("=== REINICIANDO CARRERA ===")
	_isVictoryScreenActive = false
	
	# Ocultar pantalla de victoria
	if _victoryScreen:
		_victoryScreen.visible = false
	
	# Detener video de victoria
	if _victoryVideoPlayer:
		_victoryVideoPlayer.stop()
		print("🎬 Video de victoria detenido")
	
	# Detener animación
	if _pulsingTween:
		_pulsingTween.kill()
	
	# Reiniciar variables globales (vueltas, tiempo, etc.)
	Globals.reset_race()
	
	# Reposicionar y reiniciar jugador completamente
	if _player:
		# Reposicionar a la posición inicial
		if _player.has_method("SetMapPosition"):
			_player.SetMapPosition(Globals.startPosition)
			print("🏁 Jugador reposicionado a: ", Globals.startPosition)
		
		# Reiniciar completamente el estado del jugador
		if _player.has_method("ResetPlayerState"):
			_player.ResetPlayerState()
	
	print("✅ Carrera reiniciada - Jugador en posición inicial")

func _setup_simple_opponents():
	print("=== CONFIGURANDO OPONENTES SIMPLES ===")
	print("🔍 DEBUG: _available_characters = ", _available_characters)
	print("🔍 DEBUG: Globals.selected_character = ", Globals.selected_character)
	
	# Obtener personajes disponibles (todos excepto el seleccionado)
	var opponent_characters = _available_characters.duplicate()
	var selected_char = Globals.selected_character.to_lower()
	
	# Remover el personaje seleccionado de la lista
	opponent_characters.erase(selected_char)
	
	print("Personaje del jugador: ", selected_char)
	print("Oponentes a crear: ", opponent_characters)
	print("🔍 DEBUG: SpriteHandler disponible: ", _spriteHandler != null)
	
	# Crear oponentes simples
	for i in range(opponent_characters.size()):
		var character_name = opponent_characters[i]
		print("🎮 Intentando crear oponente: ", character_name)
		var opponent = _create_simple_opponent(character_name, i)
		if opponent:
			_ai_opponents.append(opponent)
			print("✅ Oponente simple creado: ", character_name)
		else:
			print("❌ ERROR: No se pudo crear oponente: ", character_name)
	
	print("🏁 Total de oponentes creados: ", _ai_opponents.size())

func _create_simple_opponent(character_name: String, position_index: int) -> SimpleOpponent:
	print("🎮 Creando oponente simple: ", character_name, " en posición: ", position_index)
	
	# Crear nodo directamente
	var opponent = SimpleOpponent.new()
	if not opponent:
		print("❌ Error: No se pudo crear el oponente simple")
		return null
	
	print("✅ Nodo SimpleOpponent creado exitosamente")
	
	# Configurar propiedades básicas CORRECTAS
	opponent.character_name = character_name
	opponent.ai_speed = randf_range(60.0, 100.0)  # Usar ai_speed que existe en SimpleOpponent
	opponent.start_delay = position_index * 0.5    # Usar start_delay en lugar de position_offset
	
	print("🔧 Propiedades configuradas - speed:", opponent.ai_speed, " delay:", opponent.start_delay)
	
	# Agregar al mundo
	add_child(opponent)
	print("🌍 Oponente agregado como hijo")
	
	# Agregar al SpriteHandler para que sea visible
	if _spriteHandler:
		_spriteHandler.AddSimpleOpponent(opponent)
		print("🖼️ Oponente agregado al SpriteHandler: ", character_name)
	else:
		print("❌ ERROR: _spriteHandler es null!")
	
	print("✅ Oponente simple configurado completamente: ", character_name)
	return opponent

func setup_navigation_region():
	print("🗺️ Setting up NavigationRegion2D for AI pathfinding...")
	
	# Create NavigationRegion2D
	_navigation_region = NavigationRegion2D.new()
	_navigation_region.name = "AINavigationRegion"
	add_child(_navigation_region)
	
	# Create a navigation polygon that properly covers the track layout
	var navigation_polygon = NavigationPolygon.new()
	
	# Define track boundaries based on actual track layout (Donut Plains style)
	# This creates a larger area that encompasses the entire racing circuit
	var track_outline = PackedVector2Array([
		Vector2(60, 200),    # Left side start
		Vector2(60, 600),    # Left side bottom
		Vector2(200, 600),   # Bottom left curve
		Vector2(400, 580),   # Bottom section
		Vector2(500, 500),   # Bottom right curve
		Vector2(520, 400),   # Right side
		Vector2(500, 300),   # Right side middle
		Vector2(480, 200),   # Right side top
		Vector2(400, 150),   # Top right curve
		Vector2(300, 140),   # Top section
		Vector2(200, 150),   # Top left curve
		Vector2(120, 180)    # Back to start
	])
	
	navigation_polygon.add_outline(track_outline)
	navigation_polygon.make_polygons_from_outlines()
	
	_navigation_region.navigation_polygon = navigation_polygon
	print("✅ NavigationRegion2D configured with proper track boundaries covering racing circuit")

func _create_ai_opponents():
	print("🤖 Creating AI opponents using existing character nodes...")
	
	# Get selected character to exclude from AI opponents
	var selected_char = Globals.selected_character.to_lower()
	print("Selected character (excluded from AI): ", selected_char)
	
	# Define all possible opponent characters and starting positions
	var all_opponent_data = [
		{"name": "mario", "position": Vector3(100, 0, 520), "node_path": "Sprite Handler/Racers/Mario"},
		{"name": "luigi", "position": Vector3(110, 0, 525), "node_path": "Sprite Handler/Racers/Luigi"},
		{"name": "bowser", "position": Vector3(136, 0, 520), "node_path": "Sprite Handler/Racers/Bowser"},
		{"name": "donkeykong", "position": Vector3(145, 0, 525), "node_path": "Sprite Handler/Racers/DonkeyKong"},
		{"name": "yoshi", "position": Vector3(155, 0, 520), "node_path": "Sprite Handler/Racers/Yoshi"}
	]
	
	# Filter out the selected character - ALL others become AI
	var opponent_data = []
	for data in all_opponent_data:
		if data.name != selected_char:
			opponent_data.append(data)
	
	print("AI opponents to create: ", opponent_data.size(), " characters")
	
	# Convert existing character nodes to AI opponents
	for data in opponent_data:
		var opponent = _convert_character_to_ai(data)
		if opponent:
			_ai_opponents.append(opponent)
			# Add to minimap
			_minimap.AddOpponent(opponent)
			print("✅ AI opponent created: ", data.name)
		else:
			print("❌ Failed to convert character to AI: ", data.name)
	
	print("🏁 Total AI opponents created: ", _ai_opponents.size(), " | Player: ", Globals.selected_character)

func _convert_character_to_ai(data: Dictionary) -> Node2D:
	print("🔄 Converting character to AI: ", data.name)
	
	# Get the existing character node
	var character_node = get_node(data.node_path)
	if not character_node:
		print("❌ Character node not found: ", data.node_path)
		return null
	
	# Skip if this is the player character
	if character_node == _player:
		print("⚠️ Skipping player character: ", data.name)
		return null
	
	print("✓ Character node found: ", character_node.name, " | Type: ", character_node.get_class())
	
	# Check if already has AI behavior
	if character_node.has_node("AIController"):
		print("⚠️ Character already has AI behavior: ", data.name)
		return character_node
	
	# Add enhanced AI controller script to existing node
	var ai_script = load("res://Scripts/World Elements/Racers/AIController.gd")
	if not ai_script:
		print("❌ AIController script not found")
		return null
	
	print("✓ AIController script loaded successfully")
	
	# Create enhanced AI controller component
	var ai_controller = Node.new()
	ai_controller.name = "AIController"
	ai_controller.set_script(ai_script)
	character_node.add_child(ai_controller)
	
	print("✓ AIController node created and added to character")
	
	# Configure AI controller with player reference
	print("✓ Configuring AI with player reference: ", _player.name if _player else "NULL")
	ai_controller.setup_ai(data.name, data.position, character_node, _player)
	
	# Setup map size and collision handler if methods exist
	if character_node.has_method("SetMapSize"):
		character_node.SetMapSize(_map.texture.get_size().x)
		print("✓ Map size set for AI character")
	if character_node.has_method("_collisionHandler"):
		character_node._collisionHandler = _collision
		print("✓ Collision handler set for AI character")
	
	# Set starting position
	if character_node.has_method("SetMapPosition"):
		character_node.SetMapPosition(data.position)
		print("✓ Starting position set: ", data.position)
	
	# Make character visible and active
	character_node.visible = true
	print("✓ Character made visible")
	
	# Add to SpriteHandler
	_spriteHandler.AddAIOpponent(character_node)
	print("✓ Added to SpriteHandler")
	
	print("✅ Character converted to Enhanced AI: ", data.name, " at position: ", data.position)
	return character_node

# Función temporal para probar todos los personajes
var test_characters = ["Mario", "Luigi", "Bowser", "DonkeyKong"]
var current_test_index = 0

func test_next_character():
	current_test_index = (current_test_index + 1) % test_characters.size()
	var new_character = test_characters[current_test_index]
	print("\n=== PRUEBA: Cambiando a ", new_character, " ===")
	Globals.selected_character = new_character
	_setup_selected_character()
	print("=== FIN PRUEBA ===\n")
