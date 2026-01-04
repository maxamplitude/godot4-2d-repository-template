extends Node
## Central service locator - THE ONLY AUTOLOAD
##
## Manages all game services with lazy loading for non-critical systems.
## Provides clean dependency injection and breaks circular dependencies.

# ============================================================================
# CORE SERVICES (Always loaded - lightweight, used everywhere)
# ============================================================================

var events: EventBus
var input: InputHelper

# ============================================================================
# LAZY-LOADED SERVICES (Created on first access)
# ============================================================================

var _audio: AudioManager
var _settings: SettingsManager
var _save: SaveManager
var _scenes: SceneManager
var _game: GameManager

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
    # Wait one frame to ensure scene tree is ready
    await get_tree().process_frame

    # Initialize core services (lightweight, always needed)
    _init_core_services()

    print("GameServices: Core services initialized")


func _init_core_services() -> void:
    # EventBus - Always available, no dependencies
    events = EventBus.new()
    events.name = "EventBus"
    add_child(events)

    # InputHelper - Always available, no dependencies
    input = InputHelper.new()
    input.name = "InputHelper"
    add_child(input)


# ============================================================================
# LAZY GETTERS (Services created on first access)
# ============================================================================

## Audio manager - handles music, SFX, and bus volumes
## Depends on: SettingsManager (for volume persistence)
var audio: AudioManager:
    get:
        print("GameServices: Getting audio manager")
        if not _audio:
            print("GameServices: Initializing audio manager")
            _init_audio()
        print("GameServices: Returning audio manager")
        return _audio


## Settings manager - handles game configuration and persistence
## Depends on: Nothing (but AudioManager depends on it, so init first)
var settings: SettingsManager:
    get:
        if not _settings:
            _init_settings()
        return _settings


## Save manager - handles game state save/load
## Depends on: Nothing
var save: SaveManager:
    get:
        if not _save:
            _init_save()
        return _save


## Scene manager - handles scene transitions and loading
## Depends on: Nothing
var scenes: SceneManager:
    get:
        if not _scenes:
            _init_scenes()
        return _scenes


## Game manager - handles high-level game state and flow
## Depends on: SceneManager, EventBus
var game: GameManager:
    get:
        if not _game:
            _init_game()
        return _game


# ============================================================================
# INITIALIZATION METHODS (Break circular dependencies)
# ============================================================================

func _init_settings() -> void:
    _settings = SettingsManager.new()
    _settings.name = "SettingsManager"
    add_child(_settings)
    print("GameServices: SettingsManager loaded")


func _init_audio() -> void:
    # Ensure settings exists first (AudioManager needs it)
    if not _settings:
        _init_settings()
    
    _audio = AudioManager.new()
    _audio.name = "AudioManager"
    add_child(_audio)
    print("GameServices: AudioManager loaded")


func _init_save() -> void:
    _save = SaveManager.new()
    _save.name = "SaveManager"
    add_child(_save)
    print("GameServices: SaveManager loaded")


func _init_scenes() -> void:
    _scenes = SceneManager.new()
    _scenes.name = "SceneManager"
    add_child(_scenes)
    print("GameServices: SceneManager loaded")


func _init_game() -> void:
    # Ensure SceneManager exists (GameManager needs it)
    if not _scenes:
        _init_scenes()
    
    _game = GameManager.new()
    _game.name = "GameManager"
    add_child(_game)
    print("GameServices: GameManager loaded")


# ============================================================================
# UTILITY METHODS
# ============================================================================

## Check if a service is currently loaded
func is_service_loaded(service_name: String) -> bool:
    match service_name:
        "audio": return _audio != null
        "settings": return _settings != null
        "save": return _save != null
        "scenes": return _scenes != null
        "game": return _game != null
        "events": return events != null
        "input": return input != null
        _: return false


## Get all currently loaded service names
func get_loaded_services() -> Array[String]:
    var loaded: Array[String] = []
    if events: loaded.append("events")
    if input: loaded.append("input")
    if _audio: loaded.append("audio")
    if _settings: loaded.append("settings")
    if _save: loaded.append("save")
    if _scenes: loaded.append("scenes")
    if _game: loaded.append("game")
    return loaded


## Force load all services (useful for testing)
func preload_all_services() -> void:
    var _dummy_audio = audio
    var _dummy_settings = settings
    var _dummy_save = save
    var _dummy_scenes = scenes
    var _dummy_game = game
    print("GameServices: All services preloaded")


# ============================================================================
# CLEANUP
# ============================================================================

func _exit_tree() -> void:
    # Services will be freed automatically as children
    print("GameServices: Shutting down")
