extends Control
## Pause menu scene
##
## Shown when the game is paused. Handles resume, settings, and return to menu.

@export var transition: SceneTransition = null

@onready var resume_button: Button = %ResumeButton
@onready var settings_button: Button = %SettingsButton
@onready var main_menu_button: Button = %MainMenuButton


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
	AudioManager.play_sfx(preload("res://assets/audio/sfx/ui_click.wav")) if ResourceLoader.exists("res://assets/audio/sfx/ui_click.wav") else null
	
	SceneManager.pop_scene(transition)
	GameManager.resume_game()


func _on_settings_pressed() -> void:
	AudioManager.play_sfx(preload("res://assets/audio/sfx/ui_click.wav")) if ResourceLoader.exists("res://assets/audio/sfx/ui_click.wav") else null
	
	# Push settings menu on top of pause menu
	SceneManager.push_scene(Constants.SCENE_SETTINGS_MENU)


func _on_main_menu_pressed() -> void:
	AudioManager.play_sfx(preload("res://assets/audio/sfx/ui_click.wav")) if ResourceLoader.exists("res://assets/audio/sfx/ui_click.wav") else null
	
	# Pop pause menu and return to main menu
	SceneManager.pop_scene(null)  # Remove pause menu instantly
	GameManager.return_to_menu()