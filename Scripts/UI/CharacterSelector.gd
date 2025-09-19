extends Control

signal character_selected(character_name: String)

func _ready():
	pass

func _on_mario_selected():
	character_selected.emit("Mario")
	_start_game("Mario")

func _on_luigi_selected():
	character_selected.emit("Luigi")
	_start_game("Luigi")

func _on_bowser_selected():
	character_selected.emit("Bowser")
	_start_game("Bowser")

func _on_donkey_kong_selected():
	character_selected.emit("DonkeyKong")
	_start_game("DonkeyKong")

func _on_yoshi_selected():
	character_selected.emit("Yoshi")
	_start_game("Yoshi")

func _start_game(character_name: String):
	Globals.selected_character = character_name
	
	get_tree().change_scene_to_file("res://Scenes/main.tscn")