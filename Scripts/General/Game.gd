extends Node2D
@export var _map : Node2D
@export var _collision : Node
var _player : Racer 
@export var _spriteHandler : Node2D
@export var _animationHandler : Node
@export var _backgroundElements : Node2D
@export var _minimap : Control

var _debugLabel : Label
var _victoryScreen : Control
var _victoryVideoPlayer : VideoStreamPlayer
var _pulsingTween : Tween
var _isVictoryScreenActive : bool = false
var _tKeyPressed : bool = false
var _vKeyPressed : bool = false

var _countdownLabel : Label
var _countdownTimer : Timer
var _countdownValue : int = 3
var _countdownAudio : AudioStreamPlayer

var _lapLabel : Label

var _gameplayMusic : AudioStreamPlayer
var _lap2Audio : AudioStreamPlayer
var _finalLapAudio : AudioStreamPlayer

var _ai_opponents : Array[Racer] = []
var _available_characters : Array[String] = ["mario", "luigi", "bowser", "donkikon"]
var _opponents_created : bool = false
var _frame_counter : int = 0
var _navigation_region : NavigationRegion2D

func _ready():
	
	_setup_selected_character()
	
	if not _player:
		print("ERROR CRITICO: _player no fue asignado en _setup_selected_character!")
		return
	
	_map.Setup(Globals.screenSize, _player)
	_collision.Setup()
	_spriteHandler.Setup(_map.ReturnWorldMatrix(), _map.texture.get_size().x, _player, _collision)
	_player.Setup(_map.texture.get_size().x, _spriteHandler)
	
	if _animationHandler and _player:
		_animationHandler.Setup(_player)
	_minimap.Setup(_player, _map.texture)
	
	_debugLabel = $UI/Debug/PositionLabel
	
	setup_victory_screen()
	
	setup_countdown_system()
	
	setup_lap_hud()
	
	setup_gameplay_music()
	
	add_to_group("game")
	
	Globals.raceStartTime = Time.get_ticks_msec()
	
	setup_navigation_region()
	
	var script_name = "sin script"
	if _player and _player.get_script():
		script_name = _player.get_script().get_global_name()
	
	await get_tree().create_timer(1.0).timeout
	start_countdown()

func _setup_selected_character():
	var mario_node = $"Sprite Handler/Racers/Mario"
	var luigi_node = $"Sprite Handler/Racers/Luigi"
	var bowser_node = $"Sprite Handler/Racers/Bowser"
	var donkey_kong_node = $"Sprite Handler/Racers/DonkeyKong"
	var yoshi_node = $"Sprite Handler/Racers/Yoshi"
	
	if not mario_node:
		print("ERROR: Nodo Mario no encontrado!")
		return
	if not luigi_node:
		print("ERROR: Nodo Luigi no encontrado!")
		return
	
	
	mario_node.visible = false
	luigi_node.visible = false
	if bowser_node:
		bowser_node.visible = false
	if donkey_kong_node:
		donkey_kong_node.visible = false
	if yoshi_node:
		yoshi_node.visible = false
	
	match Globals.selected_character:
		"Luigi":
			luigi_node.visible = true
			_player = luigi_node
		"Bowser":
			if bowser_node:
				bowser_node.visible = true
				_player = bowser_node
			else:
				mario_node.visible = true
				_player = mario_node
		"DonkeyKong":
			if donkey_kong_node:
				donkey_kong_node.visible = true
				_player = donkey_kong_node
			else:
				mario_node.visible = true
				_player = mario_node
		"Yoshi":
			if yoshi_node:
				yoshi_node.visible = true
				_player = yoshi_node
			else:
				mario_node.visible = true
				_player = mario_node
		_:  # Mario por defecto
			mario_node.visible = true
			_player = mario_node
	
	if not _player:
		print("ERROR: _player no fue asignado correctamente!")
		return
	
	if _animationHandler and _player:
		_animationHandler.Setup(_player)
	
	var player_sprite = _player.ReturnSpriteGraphic()
	if player_sprite and player_sprite is AnimatedSprite2D:
		player_sprite.scale = Vector2(3.0, 3.0)
		
	var player_type = "sin script"
	if _player and _player.get_script():
		player_type = _player.get_script().get_global_name()

func _process(_delta):
	_frame_counter += 1
	if not _opponents_created and _frame_counter > 60:
		_create_ai_opponents()
		_opponents_created = true
	
	
	if _isVictoryScreenActive:
		if Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_SPACE):
			restart_race()
		return
	
	if Input.is_key_pressed(KEY_T):
		if !_tKeyPressed and !Globals.raceFinished:
			_tKeyPressed = true
			simulate_lap_completion()
	else:
		_tKeyPressed = false
	
	if Input.is_key_pressed(KEY_V):
		if !_vKeyPressed and !_isVictoryScreenActive:
			_vKeyPressed = true
			force_victory_for_testing()
	else:
		_vKeyPressed = false
	
	if Input.is_action_just_pressed("ui_accept"):
		test_next_character()
	
	_map.Update(_player)
	_player.Update(_map.ReturnForward())
	
	for i in range(_ai_opponents.size()):
		var opponent = _ai_opponents[i]
		if opponent and is_instance_valid(opponent):
			var pos_before = opponent._mapPosition
			var speed_before = opponent._movementSpeed
			var _input_before = opponent._inputDir
			
			var ai_controller = opponent.get_node("AIController")
			if ai_controller and ai_controller.has_method("update_ai_behavior"):
				ai_controller.update_ai_behavior(_map.ReturnForward())
				
				if Engine.get_process_frames() % 60 == 0:
					var pos_after = opponent._mapPosition
					var speed_after = opponent._movementSpeed
					var velocity = opponent.ReturnVelocity()
					var move_dir = opponent._currentMoveDirection
					
			else:
				var ai_behavior = opponent.get_node("AIBehavior")
				if ai_behavior and ai_behavior.has_method("update_ai_behavior"):
					ai_behavior.update_ai_behavior(_map.ReturnForward())
		else:
			pass
	
	if Engine.get_process_frames() % 60 == 0 and _ai_opponents.size() > 0:
		for i in range(_ai_opponents.size()):
			var opponent = _ai_opponents[i]
			if opponent and is_instance_valid(opponent):
				var pos = opponent._mapPosition
				var speed = opponent._movementSpeed
				var input_dir = opponent._inputDir
				var is_visible = opponent.visible
	
	
	_spriteHandler.Update(_map.ReturnWorldMatrix())
	_animationHandler.Update()
	_backgroundElements.Update(_map.ReturnMapRotation())
	_minimap.UpdateMinimap()
	
	if _lapLabel:
		var lapText = "VUELTA: %d/%d" % [Globals.currentLap, Globals.totalLaps]
		if Globals.raceFinished:
			lapText = "¡TERMINADO!"
			_lapLabel.add_theme_color_override("font_color", Color.GOLD)
		elif Globals.currentLap == Globals.totalLaps - 1:
			_lapLabel.add_theme_color_override("font_color", Color.YELLOW)
		else:
			_lapLabel.add_theme_color_override("font_color", Color.WHITE)
		_lapLabel.text = lapText
	
	if _debugLabel:
		var playerPos = _player._mapPosition
		var playerPos2D = Vector2(playerPos.x, playerPos.z)
		var lapInfo = "Vuelta: %d/%d" % [Globals.currentLap, Globals.totalLaps]
		var _checkpointStatus = "CP: " + ("✓" if Globals.hasPassedCheckpoint else "✗")
		var raceStatus = "Estado: " + ("FINISH" if Globals.raceFinished else "RACING")
		var distanceToFinish = playerPos2D.distance_to(Globals.finishLinePosition)
		var distanceToCheckpoint = playerPos2D.distance_to(Globals.checkpointPosition)
		var victoryStatus = "Victoria: " + ("SÍ" if _isVictoryScreenActive else "NO")
		
		var _nextTarget = "→ " + ("META (64,64)" if Globals.hasPassedCheckpoint else "CHECKPOINT (500,350)")
		var nextDistance = distanceToCheckpoint if !Globals.hasPassedCheckpoint else distanceToFinish
		var _progressIndicator = "🔥" if nextDistance < 120 else "●"
		
		var raceTime = (Time.get_ticks_msec() - Globals.raceStartTime) / 1000.0
		var distanceText = "Distancia a META: %.0f" % distanceToFinish
		var proximityIcon = "🔥" if distanceToFinish < 100 else "○"
		_debugLabel.text = "Pos: (%.0f, %.0f) | Speed: %.1f | %s\n%s | %s | Tiempo: %.1fs\n%s %s\n%s %s\nTEST: V=Victoria, T=Vuelta, SPACE=Cambiar personaje" % [playerPos.x, playerPos.z, _player.ReturnMovementSpeed(), Globals.selected_character, lapInfo, raceStatus, raceTime, proximityIcon, distanceText, victoryStatus, "Meta en: (64,64)"]

func setup_victory_screen():
	_victoryScreen = Control.new()
	_victoryScreen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_victoryScreen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var background = ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color.BLACK
	_victoryScreen.add_child(background)
	
	var videoContainer = AspectRatioContainer.new()
	videoContainer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	videoContainer.stretch_mode = AspectRatioContainer.STRETCH_FIT
	videoContainer.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	videoContainer.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	
	_victoryVideoPlayer = VideoStreamPlayer.new()
	_victoryVideoPlayer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_victoryVideoPlayer.expand = true
	
	videoContainer.add_child(_victoryVideoPlayer)
	
	var videoPath = "res://imagenes_final/yoshiVictory.ogv"
	
	if ResourceLoader.exists(videoPath):
		
		var videoStream = load(videoPath)
		if videoStream != null:
			_victoryVideoPlayer.stream = videoStream
			_victoryVideoPlayer.autoplay = false
			_victoryVideoPlayer.loop = true
		else:
			var theoraStream = VideoStreamTheora.new()
			theoraStream.file = videoPath
			_victoryVideoPlayer.stream = theoraStream
			_victoryVideoPlayer.autoplay = false
			_victoryVideoPlayer.loop = true
	else:
		var dir = DirAccess.open("res://imagenes_final/")
		if dir:
			dir.list_dir_begin()
			var fileName = dir.get_next()
			while fileName != "":
				fileName = dir.get_next()
			dir.list_dir_end()
	
	_victoryScreen.add_child(videoContainer)
	
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
	
	$UI.add_child(_victoryScreen)
	_victoryScreen.visible = false

func create_fallback_victory_text():
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
	
func show_victory_screen():
	if _isVictoryScreenActive:
		return
		
	if not _victoryScreen:
		return
		
	_isVictoryScreenActive = true
	_victoryScreen.visible = true
	
	if _victoryVideoPlayer:
		if _victoryVideoPlayer.stream:
			_victoryVideoPlayer.play()
		else:
			create_fallback_victory_text()
	else:
		create_fallback_victory_text()

func simulate_lap_completion():
	if Globals.raceFinished:
		return
		
	Globals.currentLap += 1
	
	if Globals.currentLap >= Globals.totalLaps:
		Globals.raceFinished = true
		show_victory_screen()
		
func force_victory_for_testing():
	if _isVictoryScreenActive:
		return
	Globals.raceFinished = true
	show_victory_screen()

func restart_race():
	_isVictoryScreenActive = false
	stop_gameplay_music()
	
	if _victoryScreen:
		_victoryScreen.visible = false
	
	if _victoryVideoPlayer:
		_victoryVideoPlayer.stop()
	
	if _pulsingTween:
		_pulsingTween.kill()
	
	Globals.reset_race()
	
	if _player:
		if _player.has_method("SetMapPosition"):
			_player.SetMapPosition(Globals.startPosition)
		
		if _player.has_method("ResetPlayerState"):
			_player.ResetPlayerState()
	
	for opponent in _ai_opponents:
		if opponent and is_instance_valid(opponent):
			var ai_start_positions = [
				Vector3(110, 0, 580),
				Vector3(136, 0, 575),
				Vector3(145, 0, 580),
				Vector3(155, 0, 575)
			]
			var index = _ai_opponents.find(opponent)
			if index >= 0 and index < ai_start_positions.size():
				if opponent.has_method("SetMapPosition"):
					opponent.SetMapPosition(ai_start_positions[index])
					
			if opponent.has_method("ResetPlayerState"):
				opponent.ResetPlayerState()
			
			if opponent.has_method("SetAIControlled"):
				opponent.SetAIControlled(true)
				
			opponent._movementSpeed = 0.0
			opponent._velocity = Vector3.ZERO
			
	await get_tree().create_timer(1.0).timeout
	start_countdown()

func _setup_simple_opponents():
	var opponent_characters = _available_characters.duplicate()
	var selected_char = Globals.selected_character.to_lower()
	
	opponent_characters.erase(selected_char)
	
	for i in range(opponent_characters.size()):
		var character_name = opponent_characters[i]
		var opponent = _create_simple_opponent(character_name, i)
		if opponent:
			_ai_opponents.append(opponent)
		else:
			print("ERROR: No se pudo crear oponente: ", character_name)
	
func _create_simple_opponent(character_name: String, position_index: int) -> SimpleOpponent:
	var opponent = SimpleOpponent.new()
	if not opponent:
		return null
	
	opponent.character_name = character_name
	opponent.ai_speed = randf_range(60.0, 100.0)  
	opponent.start_delay = position_index * 0.5    
	
	
	add_child(opponent)
	
	if _spriteHandler:
		_spriteHandler.AddSimpleOpponent(opponent)
	else:
		print("ERROR: _spriteHandler es null!")
	
	return opponent

func setup_navigation_region():
	_navigation_region = NavigationRegion2D.new()
	_navigation_region.name = "AINavigationRegion"
	add_child(_navigation_region)
	
	var navigation_polygon = NavigationPolygon.new()
	
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

func _create_ai_opponents():
	var selected_char = Globals.selected_character.to_lower()
	
	var all_opponent_data = [
		{"name": "mario", "position": Vector3(100, 0, 580), "node_path": "Sprite Handler/Racers/Mario"},
		{"name": "luigi", "position": Vector3(110, 0, 580), "node_path": "Sprite Handler/Racers/Luigi"},
		{"name": "bowser", "position": Vector3(136, 0, 575), "node_path": "Sprite Handler/Racers/Bowser"},
		{"name": "donkeykong", "position": Vector3(145, 0, 580), "node_path": "Sprite Handler/Racers/DonkeyKong"},
		{"name": "yoshi", "position": Vector3(155, 0, 575), "node_path": "Sprite Handler/Racers/Yoshi"}
	]
	
	var opponent_data = []
	for data in all_opponent_data:
		if data.name != selected_char:
			opponent_data.append(data)
	
	for data in opponent_data:
		var opponent = _convert_character_to_ai(data)
		var opponent_name = "NULL"
		if opponent:
			opponent_name = opponent.name
		if opponent:
			_ai_opponents.append(opponent)
			var last_opponent_name = "NONE"
			if _ai_opponents.size() > 0:
				last_opponent_name = _ai_opponents[-1].name
			_minimap.AddOpponent(opponent)
	
	for i in range(_ai_opponents.size()):
		var opp = _ai_opponents[i]

func _convert_character_to_ai(data: Dictionary) -> Node2D:
	var character_node = get_node(data.node_path)
	if not character_node:
		return null
	if character_node == _player:
		return null
	
	var ai_controller
	if character_node.has_node("AIController"):
		ai_controller = character_node.get_node("AIController")
	else:
		var ai_script = load("res://Scripts/World Elements/Racers/AIController.gd")
		if not ai_script:
			return null
		
		ai_controller = Node.new()
		ai_controller.name = "AIController"
		ai_controller.set_script(ai_script)
		character_node.add_child(ai_controller)
	
	ai_controller.setup_ai(data.name, data.position, character_node, _player)
	
	if character_node.has_method("SetMapSize"):
		character_node.SetMapSize(_map.texture.get_size().x)
	if character_node.has_method("Setup"):
		character_node.Setup(_map.texture.get_size().x, _spriteHandler)
	
	character_node._collisionHandler = _collision
	
	if character_node.has_method("SetMapPosition"):
		character_node.SetMapPosition(data.position)
	
	character_node.visible = true
	
	var sprite_graphic = character_node.ReturnSpriteGraphic()
	if sprite_graphic and sprite_graphic is AnimatedSprite2D:
		sprite_graphic.scale = Vector2(3.0, 3.0)
	
	character_node._movementSpeed = 50.0
	character_node._inputDir = Vector2(0.0, -1.0)
	
	_spriteHandler.AddAIOpponent(character_node)
	return character_node

# ========== SISTEMA DE MÚSICA DE GAMEPLAY ==========

func setup_gameplay_music():
	
	_gameplayMusic = AudioStreamPlayer.new()
	add_child(_gameplayMusic)
	
	var gameplay_music_path = "res://Sounds/gameplay.mp3"
	if ResourceLoader.exists(gameplay_music_path):
		var music_stream = load(gameplay_music_path)
		if music_stream is AudioStreamMP3:
			music_stream.loop = true
		elif music_stream is AudioStreamOggVorbis:
			music_stream.loop = true
		_gameplayMusic.stream = music_stream
	else:
		print("ERROR: No se encontró archivo de música: ", gameplay_music_path)
	
	_lap2Audio = AudioStreamPlayer.new()
	add_child(_lap2Audio)
	var lap2_path = "res://Sounds/mario-kart-lap-2.mp3"
	if ResourceLoader.exists(lap2_path):
		_lap2Audio.stream = load(lap2_path)
	
	_finalLapAudio = AudioStreamPlayer.new()
	add_child(_finalLapAudio)
	var final_lap_path = "res://Sounds/mk64_finallap.mp3"
	if ResourceLoader.exists(final_lap_path):
		_finalLapAudio.stream = load(final_lap_path)

func start_gameplay_music():
	if _gameplayMusic and _gameplayMusic.stream:
		_gameplayMusic.play()

func stop_gameplay_music():
	if _gameplayMusic and _gameplayMusic.playing:
		_gameplayMusic.stop()

func play_lap2_sound():
	if _lap2Audio and _lap2Audio.stream:
		_lap2Audio.play()

func play_final_lap_sound():
	if _finalLapAudio and _finalLapAudio.stream:
		_finalLapAudio.play()

# ========== SISTEMA DE COUNTDOWN 3-2-1-GO ==========

func setup_countdown_system():
	
	_countdownLabel = Label.new()
	_countdownLabel.text = ""
	_countdownLabel.add_theme_font_size_override("font_size", 120)
	_countdownLabel.add_theme_color_override("font_color", Color.RED)
	_countdownLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdownLabel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var gameplay_area = $UI/GameplayArea
	if gameplay_area:
		_countdownLabel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		_countdownLabel.size = Vector2(400, 200)
		_countdownLabel.position = Vector2(-200, -100)
		gameplay_area.add_child(_countdownLabel)
	else:
		_countdownLabel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		_countdownLabel.size = Vector2(400, 200)
		_countdownLabel.position = Vector2(-200, -100)
		$UI.add_child(_countdownLabel)
	
	_countdownLabel.visible = false
	
	_countdownTimer = Timer.new()
	_countdownTimer.wait_time = 1.0
	_countdownTimer.one_shot = false
	_countdownTimer.timeout.connect(_on_countdown_timer_timeout)
	add_child(_countdownTimer)
	
	_countdownAudio = AudioStreamPlayer.new()
	add_child(_countdownAudio)
	
	var countdown_sound_path = "res://Sounds/countdown.mp3"
	if ResourceLoader.exists(countdown_sound_path):
		var countdown_sound = load(countdown_sound_path)
		_countdownAudio.stream = countdown_sound
	else:
		print("ERROR: Sonido de countdown no encontrado en: ", countdown_sound_path)

func setup_lap_hud():	
	_lapLabel = Label.new()
	_lapLabel.text = "VUELTA: 0/3"
	_lapLabel.add_theme_font_size_override("font_size", 24)
	_lapLabel.add_theme_color_override("font_color", Color.WHITE)
	_lapLabel.add_theme_color_override("font_shadow_color", Color.BLACK)
	_lapLabel.add_theme_constant_override("shadow_offset_x", 2)
	_lapLabel.add_theme_constant_override("shadow_offset_y", 2)
	_lapLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lapLabel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var gameplay_area = $UI/GameplayArea
	if gameplay_area:
		_lapLabel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		_lapLabel.size = Vector2(150, 40)
		_lapLabel.position = Vector2(-160, 10)
		gameplay_area.add_child(_lapLabel)
	else:
		_lapLabel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		_lapLabel.size = Vector2(150, 40)
		_lapLabel.position = Vector2(-160, 10)
		$UI.add_child(_lapLabel)

func start_countdown():	
	if not _countdownLabel or not _countdownTimer:
		print("ERROR: Sistema de countdown no configurado")
		return
	
	Globals.raceCountdown = true
	Globals.raceStarted = false
	_countdownValue = 3
	_countdownLabel.visible = true
	_countdownLabel.text = str(_countdownValue)
	_countdownLabel.add_theme_color_override("font_color", Color.RED)
	
	if _countdownAudio and _countdownAudio.stream:
		_countdownAudio.play()
	
	start_gameplay_music()	
	_countdownTimer.start()

func _on_countdown_timer_timeout():
	_countdownValue -= 1
	
	if _countdownValue > 0:
		_countdownLabel.text = str(_countdownValue)
		
		if _countdownValue == 1:
			_countdownLabel.add_theme_color_override("font_color", Color.YELLOW)
		else:
			_countdownLabel.add_theme_color_override("font_color", Color.RED)
		
	elif _countdownValue == 0:
		_countdownLabel.text = "GO!"
		_countdownLabel.add_theme_color_override("font_color", Color.GREEN)
		
		Globals.raceStarted = true
		Globals.raceCountdown = false
		
		await get_tree().create_timer(1.0).timeout
		_countdownLabel.visible = false
		_countdownTimer.stop()
		

var test_characters = ["Mario", "Luigi", "Bowser", "DonkeyKong"]
var current_test_index = 0

func test_next_character():
	current_test_index = (current_test_index + 1) % test_characters.size()
	var new_character = test_characters[current_test_index]
	Globals.selected_character = new_character
	_setup_selected_character()
