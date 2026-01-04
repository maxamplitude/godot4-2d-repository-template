# Godot 2D Template - Autoload Managers Setup Guide

## Installation

1. Copy `game_services.gd` from the template into `res://src/autoloads/`

2. Configure autoloads in **Project → Project Settings → Autoload**:
   - Add `GameServices` → `res://src/autoloads/game_services.gd`

   `GameServices` is the only required autoload. It owns the core managers: `EventBus` and `InputHelper` are created immediately, while `SettingsManager`, `AudioManager`, `SaveManager`, `SceneManager`, and `GameManager` are instantiated lazily in the correct dependency order. This keeps your project setup minimal while preserving all manager APIs via `GameServices.settings`, `GameServices.audio`, `GameServices.save`, `GameServices.scenes`, and `GameServices.game`.

   **Note:** Order matters! Constants and SettingsManager should load first since other managers depend on them.

3. Set up audio bus layout:
   - Open **Audio → Audio Buses**
   - Create these buses under Master:
     - Music
     - SFX
     - UI
     - Ambience
   - Save as `res://src/resources/default_audio_bus_layout.tres`

4. Set up input actions (Project Settings → Input Map):
   - See `default_input_map.gd` for recommended configuration
   - At minimum, add these actions:
     - move_left, move_right, move_up, move_down
     - jump, attack, interact
     - pause (for GameManager)
   - Or use the setup functions in `default_input_map.gd` in a tool script

5. Create transition resources:
   - Right-click in FileSystem → New Resource
   - Choose FadeTransition, SlideTransition, or CircularWipeTransition
   - Configure and save to `res://src/resources/transitions/`
   - Set your default in SceneManager's inspector

---

## Usage Examples

### Constants

```gdscript
# Set collision layers using predefined constants
collision_layer = Constants.LAYER_PLAYER
collision_mask = Constants.LAYER_ENEMY | Constants.LAYER_GROUND

# Use physics constants
velocity.y += Constants.GRAVITY * delta
velocity.y = min(velocity.y, Constants.TERMINAL_VELOCITY)

# Node groups
get_tree().call_group(Constants.GROUP_ENEMIES, "take_damage", 10)
var enemies = get_tree().get_nodes_in_group(Constants.GROUP_ENEMIES)

# Scene paths
SceneManager.change_scene(Constants.SCENE_MAIN_MENU)

# Game state
var current_state = Constants.GameState.PLAYING
```

**Important:** See `CONSTANTS_GUIDE.md` for when to use Constants vs local constants vs static classes.

### GameManager

```gdscript
# Game state management
GameManager.set_state(Constants.GameState.PLAYING)
var current_state = GameManager.get_state()

# Pause/resume
GameManager.pause_game()  # Auto-shows pause menu if configured
GameManager.resume_game()

# Navigation
GameManager.return_to_menu()  # Returns to initial scene
GameManager.quit_game()  # With optional confirmation

# Listen for state changes
GameManager.state_changed.connect(_on_state_changed)

# Integration with EventBus
EventBus.game_started.emit()  # GameManager auto-sets state to PLAYING
EventBus.game_ended.emit(true)  # Sets state to GAME_OVER
```

**Built-in Input Handling:**
- ui_cancel/pause → Pause/resume/quit
- F11 → Toggle fullscreen
- F3 → Toggle debug mode

### InputHelper

```gdscript
# Movement vectors
var move = InputHelper.get_movement_vector()  # Normalized 0-1
velocity = move * speed

var raw_move = InputHelper.get_movement_vector_raw()  # Full diagonal speed
velocity = raw_move * speed

# Single direction
var h_dir = InputHelper.get_horizontal_direction()  # -1, 0, or 1

# Input buffering (solves "pressed jump before landing" problem)
if is_on_floor() and InputHelper.is_action_buffered("jump"):
    velocity.y = JUMP_VELOCITY
    InputHelper.consume_buffered_action("jump")

# Combo detection
if InputHelper.check_combo_sequence(["attack", "attack", "special"], 0.5):
    perform_special_combo()

# Gamepad support
var stick = InputHelper.get_gamepad_stick(JOY_AXIS_LEFT_X)
velocity = stick * speed
```

### AudioManager

```gdscript
# Play SFX with variance
AudioManager.play_sfx(preload("res://audio/sfx/jump.wav"))

# Play SFX without variance (consistent sound)
AudioManager.play_sfx(preload("res://audio/sfx/menu_click.wav"), false)

# Play music with crossfade
AudioManager.play_music(preload("res://audio/music/level_1.ogg"))

# Stop music with fadeout
AudioManager.stop_music()

# Set bus volumes (0.0 to 1.0)
AudioManager.set_bus_volume("Music", 0.5)
AudioManager.set_bus_volume("SFX", 0.8)

# Playlist support
AudioManager.music_playlist = [
    preload("res://audio/music/track1.ogg"),
    preload("res://audio/music/track2.ogg"),
]
AudioManager.play_next_in_playlist()
```

### SceneManager

**Note:** SceneManager now uses resource-based transitions. See `TRANSITIONS_AND_GAMEMANAGER_GUIDE.md` for details.

```gdscript
# Create transition resources first (File → New Resource → FadeTransition/SlideTransition/etc)
var fade_transition = preload("res://resources/transitions/fade_black.tres")

# Change scene with transition
SceneManager.change_scene("res://scenes/level_1.tscn", fade_transition)

# Use default transition (set in SceneManager inspector)
SceneManager.change_scene("res://scenes/level_1.tscn")

# Change with specific transition type
var slide_left = preload("res://resources/transitions/slide_left.tres")
SceneManager.change_scene("res://scenes/level_1.tscn", slide_left)

# Instant scene change
SceneManager.change_scene_immediate("res://scenes/main_menu.tscn")

# Reload current scene
SceneManager.reload_scene()

# Push/pop for overlays (pause menu, inventory, etc.)
SceneManager.push_scene("res://ui/menus/pause_menu.tscn")
SceneManager.pop_scene()  # Returns to previous scene

# Preload scenes for instant loading
SceneManager.scenes_to_preload = [
    "res://scenes/level_1.tscn",
    "res://scenes/level_2.tscn",
]

# Listen for scene events
SceneManager.scene_loaded.connect(_on_scene_loaded)
SceneManager.transition_finished.connect(_on_transition_finished)
```

### EventBus

```gdscript
# Connect to events
EventBus.player_damaged.connect(_on_player_damaged)
EventBus.level_completed.connect(_on_level_completed)
EventBus.game_paused.connect(_on_game_paused)

# Emit events
EventBus.player_damaged.emit(10.0, enemy_node)
EventBus.level_completed.emit()
EventBus.item_collected.emit("coin", {"value": 100})

# Custom events for game-specific needs
EventBus.register_custom_event("boss_phase_changed")
EventBus.emit_custom_event("boss_phase_changed", {"phase": 2})
```

### SaveManager

```gdscript
# Save game to slot
var custom_data = {
    "player": {
        "position": player.position,
        "health": player.health,
        "inventory": player.inventory,
    },
    "game_state": {
        "current_level": current_level,
        "unlocked_abilities": unlocked_abilities,
    }
}
SaveManager.save_game(0, custom_data)

# Load game from slot
var save_data = SaveManager.load_game(0)
if not save_data.is_empty():
    player.position = save_data["player"]["position"]
    player.health = save_data["player"]["health"]

# Check if save exists
if SaveManager.save_exists(0):
    # Enable "Continue" button
    pass

# Get save metadata without loading
var metadata = SaveManager.get_save_metadata(0)
print("Save timestamp: ", metadata["timestamp"])

# Delete save
SaveManager.delete_save(0)

# Listen for save events
SaveManager.save_completed.connect(_on_save_completed)
SaveManager.load_completed.connect(_on_load_completed)
```

### SettingsManager

```gdscript
# Get settings
var master_volume = SettingsManager.get_setting("audio", "master_volume", 1.0)
var window_mode = SettingsManager.get_setting("display", "window_mode", 0)

# Set settings
SettingsManager.set_setting("audio", "music_volume", 0.7)
SettingsManager.set_setting("display", "window_mode", 1)  # Fullscreen

# Reset to defaults
SettingsManager.reset_to_defaults()

# Apply all settings (usually on startup or settings menu close)
SettingsManager.apply_all_settings()

# Rebind input
var new_jump_key = InputEventKey.new()
new_jump_key.keycode = KEY_SPACE
SettingsManager.rebind_input("jump", new_jump_key)

# Listen for changes
SettingsManager.setting_changed.connect(_on_setting_changed)
```

---

## Integration Tips

### Settings Menu UI

Create audio sliders that connect to `SettingsManager`:

```gdscript
extends HSlider

@export var bus_name: String = "Master"

func _ready():
    value = AudioManager.get_bus_volume(bus_name)
    value_changed.connect(_on_value_changed)

func _on_value_changed(new_value: float):
    AudioManager.set_bus_volume(bus_name, new_value)
```

### Pause Menu

```gdscript
extends Control

func _ready():
    hide()
    EventBus.game_paused.connect(_on_game_paused)
    EventBus.game_resumed.connect(_on_game_resumed)

func _on_game_paused():
    show()
    get_tree().paused = true

func _on_resume_pressed():
    EventBus.game_resumed.emit()

func _on_game_resumed():
    hide()
    get_tree().paused = false

func _on_quit_to_menu_pressed():
    get_tree().paused = false
    SceneManager.change_scene("res://ui/menus/main_menu.tscn")
```

### Level Completion

```gdscript
# In your level or player script
func _on_level_complete():
    EventBus.level_completed.emit()
    SaveManager.save_game(0)  # Auto-save on level complete
    await get_tree().create_timer(2.0).timeout
    SceneManager.change_scene("res://scenes/next_level.tscn")
```

---

## Configuration

### AudioManager Inspector Settings
- `music_crossfade_duration`: Fade time between tracks (default: 1.5s)
- `sfx_pitch_variance`: Random pitch range for variety (default: 0.1)
- `sfx_volume_variance_db`: Random volume range (default: 2dB)
- `sfx_player_pool_size`: Number of simultaneous SFX (default: 16)
- `music_playlist`: Array of music tracks for auto-play

### SceneManager Inspector Settings
- `default_transition`: Default effect (FADE, SLIDE_LEFT, etc.)
- `transition_duration`: Transition speed in seconds (default: 0.5s)
- `loading_screen_scene`: Path to loading screen (optional)
- `min_loading_time`: Minimum loading screen display time (default: 0.5s)
- `scenes_to_preload`: Array of scenes to preload at startup

### SaveManager Inspector Settings
- `save_directory`: Where saves are stored (default: "user://saves/")
- `save_file_template`: Filename pattern (default: "save_{slot}.dat")
- `use_binary_format`: Binary vs JSON (default: false)
- `encrypt_saves`: XOR encryption (default: false)
- `encryption_password`: Change this for your game!
- `max_save_slots`: Number of save slots (default: 3)
- `auto_save_enabled`: Enable auto-save (default: false)
- `auto_save_interval`: Auto-save frequency in seconds (default: 300)

### SettingsManager Inspector Settings
- `settings_file_path`: Config file location (default: "user://settings.cfg")
- `default_window_mode`: 0=Windowed, 1=Fullscreen, 2=Borderless
- `default_resolution_width/height`: Default window size
- `default_vsync_mode`: 0=Off, 1=On, 2=Adaptive
- `default_master/music/sfx/ui_volume`: Default audio levels (0.0-1.0)

### GameManager Inspector Settings
- `initial_scene`: Scene to load on startup (usually main menu)
- `pause_menu_enabled`: Auto-show pause menu when pausing
- `pause_menu_scene`: Path to pause menu scene
- `quit_confirmation_enabled`: Show dialog before quitting from gameplay
- `escape_quits_in_menu`: Allow ESC to quit in menu state
- `debug_mode_enabled`: Enable F3 debug toggle

### InputHelper Inspector Settings
- `input_buffer_time`: How long to remember inputs (default: 0.15s)
- `coyote_time`: Grace period for late jumps (default: 0.1s)

---

## Dependencies

- **Constants** → None (should load first)
- **SettingsManager** → None (should load first)
- **AudioManager** → SettingsManager (for volume persistence)
- **SaveManager** → EventBus (for save/load events)
- **SceneManager** → None
- **EventBus** → None
- **GameManager** → SceneManager, EventBus, SettingsManager, Constants (coordinates between managers)
- **InputHelper** → None

---

## Additional Guides

- **CONSTANTS_GUIDE.md** - Best practices for global vs local constants
- **TRANSITIONS_AND_GAMEMANAGER_GUIDE.md** - Scene transitions, game flow, input setup

---

## Notes

- All managers use signals for loose coupling
- Settings persist automatically via ConfigFile
- Audio volumes sync between AudioManager and SettingsManager
- Scene transitions handle mouse blocking during transitions
- SaveManager's `_gather_save_data()` and `_apply_save_data()` are meant to be extended per-game
- EventBus supports custom events for game-specific needs
- All exports are inspector-configurable for quick iteration

---

## Next Steps

1. Create your audio bus layout with the required buses
2. Build UI menus (main menu, pause menu, settings menu)
3. Extend SaveManager's gather/apply functions with your game data
4. Add UI components (audio sliders, rebind buttons, etc.)
5. Hook up EventBus signals throughout your game systems