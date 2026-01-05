extends Control
## Main menu scene
##
## Entry point for the game with Play, Settings, and Quit options

var _ui_click_stream: AudioStream = load(GameConstants.SFX_UI_CLICK)

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
	_play_ui_click()

	if not first_level_scene.is_empty():
		GameServices.scenes.change_scene(first_level_scene, transition)
	else:
		push_warning("MainMenu: first_level_scene not set")


func _on_settings_pressed() -> void:
	_play_ui_click()

	GameServices.scenes.push_scene(GameConstants.SCENE_SETTINGS_MENU)


func _on_quit_pressed() -> void:
	_play_ui_click()

	get_tree().quit()

func _play_ui_click() -> void:
	var audio = GameServices.audio
	if audio and _ui_click_stream:
		audio.play_sfx(_ui_click_stream)