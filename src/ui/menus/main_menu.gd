extends Control
## Main menu scene
##
## Entry point for the game with Play, Settings, and Quit options

@export_file("*.tscn") var first_level_scene: String = "res://scenes/level_1.tscn"
@export var transition: SceneTransition = null

@onready var play_button: Button = %PlayButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	# Connect button signals
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Focus the play button
	play_button.grab_focus()
	
	# Set game state to menu
	GameServices.game.set_state(GameConstants.GameState.MENU)
	
	# Play menu music if configured
	# AudioManager.play_music(preload("res://audio/music/menu_theme.ogg"))


func _on_play_pressed() -> void:
	if ResourceLoader.exists(GameConstants.SFX_UI_CLICK):
		GameServices.audio.play_sfx(preload(GameConstants.SFX_UI_CLICK))
	
	if not first_level_scene.is_empty():
		GameServices.scenes.change_scene(first_level_scene, transition)
	else:
		push_warning("MainMenu: first_level_scene not set")


func _on_settings_pressed() -> void:
	if ResourceLoader.exists(GameConstants.SFX_UI_CLICK):
		GameServices.audio.play_sfx(preload(GameConstants.SFX_UI_CLICK))
	
	GameServices.scenes.push_scene(GameConstants.SCENE_SETTINGS_MENU)


func _on_quit_pressed() -> void:
	if ResourceLoader.exists(GameConstants.SFX_UI_CLICK):
		GameServices.audio.play_sfx(preload(GameConstants.SFX_UI_CLICK))
	
	get_tree().quit()