# Scene Transitions and Game Management Guide

## Scene Transition System

The transition system is now **resource-based** for maximum flexibility. Instead of an enum, you select transition resources in the inspector.

### Built-in Transition Types

**FadeTransition** (`fade_transition.gd`)
- Simple fade to/from a color
- Exports: `fade_color`, `duration`, `ease_type`, `trans_type`

**SlideTransition** (`slide_transition.gd`)
- Slide from any direction (LEFT, RIGHT, UP, DOWN)
- Exports: `direction`, `slide_color`, `duration`, `ease_type`, `trans_type`

**CircularWipeTransition** (`circular_wipe_transition.gd`)
- Circular iris in/out effect with shader
- Exports: `wipe_color`, `center_position`, `invert`, `duration`, `ease_type`, `trans_type`

### Creating Transition Resources

1. In FileSystem, right-click → **New Resource**
2. Select the transition type (FadeTransition, SlideTransition, etc.)
3. Configure properties in Inspector
4. Save as `.tres` file in `res://resources/transitions/`

Example resources to create:

```
res://resources/transitions/
├── fade_black.tres          # FadeTransition with black
├── fade_white.tres          # FadeTransition with white
├── slide_left.tres          # SlideTransition with LEFT
├── slide_right.tres         # SlideTransition with RIGHT
├── iris_center.tres         # CircularWipeTransition centered
└── iris_top_left.tres       # CircularWipeTransition from corner
```

### Using Transitions

```gdscript
# Load a transition resource
var fade_transition = preload("res://resources/transitions/fade_black.tres")

# Use in scene change
SceneManager.change_scene("res://scenes/level_1.tscn", fade_transition)

# Or use the default transition set in SceneManager's inspector
SceneManager.change_scene("res://scenes/level_1.tscn")

# Instant transition (no effect)
SceneManager.change_scene("res://scenes/level_1.tscn", null)
```

### SceneManager Configuration

In SceneManager's inspector:

- **Default Transition**: Drag your `.tres` transition resource here
- **Instant When Null**: If true, null transitions are instant; if false, uses default

### Creating Custom Transitions

Extend `SceneTransition` base class:

```gdscript
extends SceneTransition
class_name MyCustomTransition

@export var my_property: float = 1.0

func _perform_transition_out(tween: Tween, overlay: ColorRect) -> void:
    # Animate the overlay coming in
    # overlay is a full-screen ColorRect
    tween.tween_property(overlay, "modulate:a", 1.0, duration)

func _perform_transition_in(tween: Tween, overlay: ColorRect) -> void:
    # Animate the overlay going out
    tween.tween_property(overlay, "modulate:a", 0.0, duration)

func reset_overlay(overlay: ColorRect) -> void:
    super.reset_overlay(overlay)
    # Reset any custom properties
```

Transitions can use:
- Tweens for animation
- Shaders (see CircularWipeTransition for example)
- Particle effects
- Custom nodes (add children to overlay)

---

## GameManager

Handles high-level game flow, state management, and system-level input.

### Inspector Configuration

- **Initial Scene**: Scene to load on game start (usually main menu)
- **Pause Menu Enabled**: Auto-show pause menu when pausing
- **Pause Menu Scene**: Path to pause menu scene
- **Quit Confirmation Enabled**: Show dialog before quitting from gameplay
- **Escape Quits In Menu**: Allow ESC to quit when in menu
- **Debug Mode Enabled**: Enable F3 debug toggle

### Game States

Uses `Constants.GameState` enum:
- MENU
- PLAYING
- PAUSED
- GAME_OVER
- CUTSCENE

### Usage

```gdscript
# Change game state
GameManager.set_state(Constants.GameState.PLAYING)

# Get current state
var state = GameManager.get_state()

# Pause/resume
GameManager.pause_game()
GameManager.resume_game()

# Return to menu
GameManager.return_to_menu()

# Quit game
GameManager.quit_game()

# Listen for state changes
GameManager.state_changed.connect(_on_state_changed)

func _on_state_changed(old_state, new_state):
    print("State: ", old_state, " -> ", new_state)
```

### Built-in Input Handling

GameManager handles these inputs automatically:

- **ui_cancel / pause**: Pause in gameplay, resume when paused, quit in menu
- **toggle_fullscreen** (F11): Toggle fullscreen
- **toggle_debug** (F3): Emit debug toggle event

### Integration with EventBus

GameManager listens to these EventBus signals:
- `game_started` → Sets state to PLAYING
- `game_ended` → Sets state to GAME_OVER
- `returned_to_menu` → Sets state to MENU

**Example level flow:**

```gdscript
# In your level/game script
func start_game():
    EventBus.game_started.emit()  # GameManager auto-sets state to PLAYING

func on_player_death():
    EventBus.game_ended.emit(false)  # false = not victory

func on_level_complete():
    EventBus.game_ended.emit(true)  # true = victory
```

---

## InputHelper

Provides common input patterns to avoid repetitive code.

### Movement Vectors

```gdscript
# Get normalized movement (length 0-1)
var move = InputHelper.get_movement_vector()
velocity = move * speed

# Get raw movement (allows faster diagonals)
var move = InputHelper.get_movement_vector_raw()
velocity.x = move.x * speed
velocity.y = move.y * speed

# Get single direction
var h_dir = InputHelper.get_horizontal_direction()  # -1, 0, or 1
var v_dir = InputHelper.get_vertical_direction()

# Check if moving
if InputHelper.is_moving():
    play_walk_animation()
```

### Input Buffering

Solves the "I pressed jump just before landing" problem:

```gdscript
func _physics_process(delta):
    # Player presses jump slightly before landing
    # Normal: Input is lost
    # With buffering: Input is remembered for 0.15s
    
    if is_on_floor() and InputHelper.is_action_buffered("jump"):
        velocity.y = JUMP_VELOCITY
        InputHelper.consume_buffered_action("jump")
```

### Combo Detection

```gdscript
# Check if player did: attack, attack, special (within 0.5s between inputs)
if InputHelper.check_combo_sequence(["attack", "attack", "special"], 0.5):
    perform_special_combo()
    InputHelper.clear_combo_history()
```

### Gamepad Support

```gdscript
# Get analog stick as Vector2
var stick = InputHelper.get_gamepad_stick(JOY_AXIS_LEFT_X)
velocity = stick * speed

# Convert analog to digital
var stick_x = InputHelper.get_gamepad_stick(JOY_AXIS_LEFT_X).x
var digital = InputHelper.analog_to_digital(stick_x, 0.5)  # -1, 0, or 1
```

### Configuration

Inspector exports:
- **Input Buffer Time**: How long to remember inputs (default: 0.15s)
- **Coyote Time**: Grace period for late jumps (default: 0.1s)

---

## Input Map Setup

### Quick Setup

1. Copy `default_input_map.gd` functions into a `@tool` script
2. Call `setup_movement_inputs()`, `setup_action_inputs()`, `setup_ui_inputs()`
3. Or manually configure using the reference below

### Recommended Input Actions

**Project Settings → Input Map**

Add these actions:

**Movement:**
```
move_left: A, Left Arrow, D-pad Left, Left Stick Left
move_right: D, Right Arrow, D-pad Right, Left Stick Right
move_up: W, Up Arrow, D-pad Up, Left Stick Up
move_down: S, Down Arrow, D-pad Down, Left Stick Down
```

**Actions:**
```
jump: Space, Gamepad A
attack: J, Z, Left Mouse, Gamepad X
special: K, X, Right Mouse, Gamepad B
dodge: Shift, Gamepad Y
interact: E, Gamepad A
```

**UI/System:**
```
pause: Escape, P, Gamepad Start
toggle_fullscreen: F11
toggle_debug: F3
screenshot: F12
```

**Note:** `ui_cancel` already exists in Godot and is used by GameManager for pause handling.

---

## Complete Flow Example

### Main Menu → Gameplay → Pause → Menu

```gdscript
# main_menu.gd
func _on_play_button_pressed():
    var fade = preload("res://resources/transitions/fade_black.tres")
    SceneManager.change_scene("res://scenes/game_level.tscn", fade)

# game_level.gd
func _ready():
    EventBus.game_started.emit()  # GameManager sets state to PLAYING

func _process(delta):
    # GameManager handles pause automatically with ui_cancel/pause input
    pass

func _on_player_died():
    EventBus.player_died.emit()
    EventBus.game_ended.emit(false)
    # Show game over screen, allow retry or return to menu

# pause_menu.gd
func _on_resume_pressed():
    SceneManager.pop_scene()  # Return to game
    GameManager.resume_game()

func _on_quit_to_menu_pressed():
    SceneManager.pop_scene()  # Remove pause menu
    GameManager.return_to_menu()  # Loads initial scene with transition
```

---

## Autoload Order

Critical order in Project Settings → Autoload:

1. Constants
2. SettingsManager
3. AudioManager
4. SaveManager
5. SceneManager
6. EventBus
7. **GameManager** (new)
8. **InputHelper** (new)

---

## Best Practices

### Transitions
- Create a small library of transition resources you like
- Set one as default in SceneManager for consistency
- Use instant (null) transitions for rapid iteration during development
- Match transition duration to your game's pacing

### Game State
- Always emit EventBus signals for state changes
- Let GameManager handle the state, don't fight it
- Use `GameManager.get_state()` for conditional logic
- Pause menus should use `SceneManager.push_scene/pop_scene`

### Input
- Use InputHelper for movement to avoid boilerplate
- Enable input buffering for responsive feel
- Test with gamepad early and often
- Consider accessibility: make inputs rebindable via SettingsManager

### Debugging
- F3 debug toggle is built-in, hook into it:
  ```gdscript
  EventBus.connect("debug_toggled", _on_debug_toggled)
  ```
- Use `if GameManager.debug_mode_enabled:` for debug features