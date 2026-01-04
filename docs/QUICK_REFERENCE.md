# Godot 2D Template - Quick Reference

## File Structure

```
res://src/
├── autoloads/
│   └── game_services.gd          # Single autoload that owns every manager
├── core/
│   ├── constants/
│   │   └── constants.gd           # Registers `GameConstants`
│   ├── managers/
│   |   ├── audio_manager.gd       # SFX, music, bus volumes
│   |   ├── event_bus.gd           # Decoupled signal communication
│   |   ├── game_manager.gd        # Game state, pause, high-level flow
│   |   ├── input_helper.gd        # Common input patterns
│   |   ├── save_manager.gd        # Save/load game data
│   |   └── scene_manager.gd       # Scene transitions and loading
|   └── systems/
│       ├── scene_transition.gd       # Base transition class
│       ├── fade_transition.gd        # Fade effect
│       ├── slide_transition.gd       # Slide effect
│       └── circular_wipe_transition.gd  # Iris effect
└── resources/
    ├── default_audio_bus_layout.tres
    └── transitions/
        ├── fade_black.tres       # Create these yourself
        ├── slide_left.tres
        └── iris_center.tres
```

`GameServices` is the only autoload that ships with the template; it instantiates `EventBus` and `InputHelper` immediately and lazily creates the other manager nodes so you can call them via `GameServices.audio`, `GameServices.settings`, `GameServices.save`, `GameServices.scenes`, and `GameServices.game`.

---

## Autoload Initialization Order

**Critical:** Add only `GameServices` under **Project → Autoload**. `GameServices` creates `EventBus` and `InputHelper` immediately and lazy-loads `SettingsManager`, `AudioManager`, `SaveManager`, `SceneManager`, and `GameManager` in the correct order (e.g., Settings before Audio, Scenes before Game). You do not need to register the individual managers or constants as autoloads.

---

## Common Workflows

### Starting a New Game

```gdscript
# main_menu.gd
func _on_play_pressed():
    var fade = preload("res://resources/transitions/fade_black.tres")
    GameServices.scenes.change_scene("res://scenes/level_1.tscn", fade)

# level_1.gd
func _ready():
    GameServices.events.game_started.emit()  # GameManager handles state
```

### Player Movement

```gdscript
# player.gd
const SPEED = 200.0

func _physics_process(delta):
    var move = GameServices.input.get_movement_vector()
    velocity = move * SPEED
    move_and_slide()
```

### Pause Menu

```gdscript
# pause_menu.gd
func _on_resume_pressed():
    GameServices.scenes.pop_scene()
    GameServices.game.resume_game()

func _on_quit_pressed():
    GameServices.scenes.pop_scene()
    GameServices.game.return_to_menu()
```

### Playing Audio

```gdscript
# Anywhere
GameServices.audio.play_sfx(preload("res://audio/jump.wav"))
GameServices.audio.play_music(preload("res://audio/music/level_theme.ogg"))
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
    GameServices.save.save_game(0, data)

func load_progress():
    var data = GameServices.save.load_game(0)
    if not data.is_empty():
        player.position = data["player"]["position"]
        player.health = data["player"]["health"]
```

---

## EventBus Signals Cheat Sheet

Use `GameServices.events` to emit or connect to these signals.

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

These actions power `InputHelper` (exposed at `GameServices.input`) for movement vectors, buffers, and combo detection.

See `default_input_map.gd` for keyboard, mouse, and gamepad bindings.

---

## Constants Usage

**Use `GameConstants` for:**
- Physics layers: `GameConstants.LAYER_PLAYER`
- Node groups: `GameConstants.GROUP_ENEMIES`
- Scene paths: `GameConstants.SCENE_MAIN_MENU`
- Game states: `GameConstants.GameState.PLAYING`

**Don't use Constants.gd for:**
- Component-specific values (player speed, enemy health)
- UI constants (button sizes, margins)
- Animation timings (tween durations)

See `constants_guide.md` for detailed best practices.

---

## Inspector Quick Config

**AudioManager (GameServices.audio):**
- Set `music_crossfade_duration` (1-3s typical)
- Configure `music_playlist` if using auto-play
- Adjust `sfx_pitch_variance` for variety (0.1 default)

**SceneManager (GameServices.scenes):**
- Drag a transition resource to `default_transition`
- Set `transition_duration` if needed
- Configure `loading_screen_scene` for heavy scenes

**GameManager (GameServices.game):**
- Set `initial_scene` to your main menu
- Configure `pause_menu_scene` path
- Enable/disable `debug_mode_enabled`

**SaveManager (GameServices.save):**
- Change `encryption_password` for your game!
- Set `max_save_slots` as needed
- Enable `auto_save_enabled` if desired

**SettingsManager (GameServices.settings):**
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

- F3 toggles debug mode (if enabled in GameServices.game)
- F11 toggles fullscreen
- Hook into debug toggle: `GameServices.events.connect("debug_toggled", _on_debug)`
- Use `if GameServices.game.debug_mode_enabled:` for debug-only features

---

## Next Steps

1. ✅ Add `GameServices` as the sole autoload entry
2. ✅ Create audio bus layout
3. ✅ Set up input actions
4. ✅ Create 2-3 transition resources
5. ✅ Configure GameManager defaults via `GameServices.game` exports
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