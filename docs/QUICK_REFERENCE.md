# Godot 2D Template - Quick Reference

## File Structure

```
res://src/
├── autoloads/
│   ├── constants.gd              # Cross-cutting constants (physics layers, groups, etc.)
│   ├── settings_manager.gd       # User preferences, display/audio settings
│   ├── audio_manager.gd          # SFX, music, bus volumes
│   ├── save_manager.gd           # Save/load game data
│   ├── scene_manager.gd          # Scene transitions and loading
│   ├── event_bus.gd              # Decoupled signal communication
│   ├── game_manager.gd           # Game state, pause, high-level flow
│   └── input_helper.gd           # Common input patterns
├── systems/
│   ├── scene_transition.gd       # Base transition class
│   ├── fade_transition.gd        # Fade effect
│   ├── slide_transition.gd       # Slide effect
│   └── circular_wipe_transition.gd  # Iris effect
└── resources/
    ├── default_audio_bus_layout.tres
    └── transitions/
        ├── fade_black.tres       # Create these yourself
        ├── slide_left.tres
        └── iris_center.tres
```

---

## Autoload Initialization Order

**Critical:** This order ensures dependencies are met:

1. Constants
2. SettingsManager
3. AudioManager
4. SaveManager
5. SceneManager
6. EventBus
7. GameManager
8. InputHelper

---

## Common Workflows

### Starting a New Game

```gdscript
# main_menu.gd
func _on_play_pressed():
    var fade = preload("res://resources/transitions/fade_black.tres")
    SceneManager.change_scene("res://scenes/level_1.tscn", fade)

# level_1.gd
func _ready():
    EventBus.game_started.emit()  # GameManager handles state
```

### Player Movement

```gdscript
# player.gd
const SPEED = 200.0

func _physics_process(delta):
    var move = InputHelper.get_movement_vector()
    velocity = move * SPEED
    move_and_slide()
```

### Pause Menu

```gdscript
# pause_menu.gd
func _on_resume_pressed():
    SceneManager.pop_scene()
    GameManager.resume_game()

func _on_quit_pressed():
    SceneManager.pop_scene()
    GameManager.return_to_menu()
```

### Playing Audio

```gdscript
# Anywhere
AudioManager.play_sfx(preload("res://audio/jump.wav"))
AudioManager.play_music(preload("res://audio/music/level_theme.ogg"))
```

### Saving Game

```gdscript
# game.gd
func save_progress():
    var data = {
        "player": {
            "position": player.position,
            "health": player.health,
        },
        "game_state": {
            "level": current_level,
            "score": score,
        }
    }
    SaveManager.save_game(0, data)

func load_progress():
    var data = SaveManager.load_game(0)
    if not data.is_empty():
        player.position = data["player"]["position"]
        player.health = data["player"]["health"]
```

---

## EventBus Signals Cheat Sheet

**Game Flow:**
- `game_started` - When gameplay begins
- `game_paused` - When game is paused
- `game_resumed` - When game resumes
- `game_ended(victory: bool)` - When game ends
- `level_completed` - When level is finished
- `returned_to_menu` - When returning to main menu

**Player:**
- `player_damaged(amount, source)` - Player takes damage
- `player_healed(amount)` - Player heals
- `player_died` - Player death
- `player_health_changed(current, max)` - Health changes
- `score_changed(new_score, delta)` - Score updates

**Items:**
- `item_collected(type, data)` - Item pickup
- `powerup_activated(type, duration)` - Powerup start
- `powerup_expired(type)` - Powerup end

**UI:**
- `ui_screen_opened(screen_name)` - Menu/screen opens
- `ui_screen_closed(screen_name)` - Menu/screen closes

---

## Input Actions Setup

**Recommended Input Map:**

Movement: `move_left`, `move_right`, `move_up`, `move_down`
Actions: `jump`, `attack`, `special`, `dodge`, `interact`
System: `pause`, `toggle_fullscreen`, `toggle_debug`

See `default_input_map.gd` for keyboard, mouse, and gamepad bindings.

---

## Constants Usage

**Use Constants.gd for:**
- Physics layers: `Constants.LAYER_PLAYER`
- Node groups: `Constants.GROUP_ENEMIES`
- Scene paths: `Constants.SCENE_MAIN_MENU`
- Game states: `Constants.GameState.PLAYING`

**Don't use Constants.gd for:**
- Component-specific values (player speed, enemy health)
- UI constants (button sizes, margins)
- Animation timings (tween durations)

See `constants_guide.md` for detailed best practices.

---

## Inspector Quick Config

**AudioManager:**
- Set `music_crossfade_duration` (1-3s typical)
- Configure `music_playlist` if using auto-play
- Adjust `sfx_pitch_variance` for variety (0.1 default)

**SceneManager:**
- Drag a transition resource to `default_transition`
- Set `transition_duration` if needed
- Configure `loading_screen_scene` for heavy scenes

**GameManager:**
- Set `initial_scene` to your main menu
- Configure `pause_menu_scene` path
- Enable/disable `debug_mode_enabled`

**SaveManager:**
- Change `encryption_password` for your game!
- Set `max_save_slots` as needed
- Enable `auto_save_enabled` if desired

**SettingsManager:**
- Set default volumes and resolution
- Configure `default_window_mode`

---

## Creating Custom Transitions

```gdscript
# res://systems/my_transition.gd
extends SceneTransition
class_name MyTransition

@export var my_setting: float = 1.0

func _perform_transition_out(tween: Tween, overlay: ColorRect):
    # Animate overlay coming in
    tween.tween_property(overlay, "modulate:a", 1.0, duration)

func _perform_transition_in(tween: Tween, overlay: ColorRect):
    # Animate overlay going out
    tween.tween_property(overlay, "modulate:a", 0.0, duration)
```

Then: Right-click → New Resource → MyTransition → Save as .tres

---

## Debug Tips

- F3 toggles debug mode (if enabled in GameManager)
- F11 toggles fullscreen
- Hook into debug toggle: `EventBus.connect("debug_toggled", _on_debug)`
- Use `if GameManager.debug_mode_enabled:` for debug-only features

---

## Next Steps

1. ✅ Install autoloads in correct order
2. ✅ Create audio bus layout
3. ✅ Set up input actions
4. ✅ Create 2-3 transition resources
5. ✅ Configure GameManager's initial scene
6. 📝 Build your main menu scene
7. 📝 Build your pause menu scene
8. 📝 Create your first game scene
9. 📝 Extend SaveManager's gather/apply functions for your game data
10. 🎮 Start building!

---

## Full Documentation

- **SETUP_GUIDE.md** - Complete installation and usage
- **CONSTANTS_GUIDE.md** - Global vs local constants best practices
- **TRANSITIONS_AND_GAMEMANAGER_GUIDE.md** - Transitions, game flow, input