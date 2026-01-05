extends Control
## Pause menu scene
##
## Shown when the game is paused. Handles resume, settings, and return to menu.

@export var transition: SceneTransition = null

@onready var resume_button: Button = %ResumeButton
@onready var settings_button: Button = %SettingsButton
@onready var main_menu_button: Button = %MainMenuButton

var _ui_click_stream: AudioStream = load(GameConstants.SFX_UI_CLICK)


func _ready() -> void:
	# Connect button signals
	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	
	# Focus the resume button
	resume_button.grab_focus()
	
	# Set process mode to always so it works while paused
	process_mode = Node.PROCESS_MODE_ALWAYS


func _on_resume_pressed() -> void:
	_play_ui_click()

	GameServices.scenes.pop_scene(transition)
	GameServices.game.resume_game()


func _on_settings_pressed() -> void:
	_play_ui_click()

	# Push settings menu on top of pause menu
	GameServices.scenes.push_scene(GameConstants.SCENE_SETTINGS_MENU)


func _on_main_menu_pressed() -> void:
	_play_ui_click()

	# Pop pause menu and return to main menu
	GameServices.scenes.pop_scene(null)  # Remove pause menu instantly
	GameServices.game.return_to_menu()


func _play_ui_click() -> void:
	var audio = GameServices.audio
	if not audio or not _ui_click_stream:
		return

	audio.play_sfx(_ui_click_stream)