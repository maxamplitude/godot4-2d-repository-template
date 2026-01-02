# UI Menus Guide

## Overview

Three ready-to-use menu scenes with full integration to the template systems:

- **MainMenu** - Entry point with Play, Settings, Quit
- **PauseMenu** - In-game pause with Resume, Settings, Main Menu
- **SettingsMenu** - Tabbed settings for Audio, Display, Controls

Plus a reusable **AudioSlider** component for any custom UI.

---

## File Locations

```
res://src/ui/
├── menus/
│   ├── main_menu.tscn/.gd
│   ├── pause_menu.tscn/.gd
│   └── settings_menu.tscn/.gd
└── components/
    └── audio_slider.tscn/.gd
```

---

## Quick Setup

### 1. Configure GameManager

In GameManager's inspector:
- **Initial Scene**: `res://src/ui/menus/main_menu.tscn`
- **Pause Menu Scene**: `res://src/ui/menus/pause_menu.tscn`
- **Pause Menu Enabled**: ✓ Check this

### 2. Configure MainMenu

Open `main_menu.tscn`, select the root node:
- **First Level Scene**: Path to your first playable level (e.g., `res://scenes/level_1.tscn`)
- **Transition**: Drag a transition resource here (optional)

### 3. Update Title

Edit the "Title" Label in MainMenu to your game's name.

### 4. Optional: Add UI Click Sound

If you have a UI click sound at `res://audio/sfx/ui_click.wav`, the menus will automatically play it on button presses.

---

## Menu Features

### Main Menu

**Buttons:**
- **Play** - Loads first_level_scene with transition
- **Settings** - Opens settings menu (pushed on stack)
- **Quit** - Exits game

**Exports:**
- `first_level_scene` - Scene to load when Play is pressed
- `transition` - Optional transition effect

**Customization:**
- Change "YOUR GAME TITLE" label
- Adjust button sizes in Inspector
- Add background image/animation
- Apply custom theme

### Pause Menu

**Buttons:**
- **Resume** - Pops menu and resumes game
- **Settings** - Opens settings (pushed on stack)
- **Main Menu** - Returns to main menu

**Features:**
- Process mode set to ALWAYS (works while paused)
- Semi-transparent dimmer overlay
- Centered panel with padding

**Exports:**
- `transition` - Optional transition when resuming

**Integration:**
GameManager automatically shows this when you press ESC/Pause during gameplay.

### Settings Menu

**Three Tabs:**

**Audio Tab:**
- Master, Music, SFX, UI volume sliders
- Real-time preview when adjusting
- Auto-saves to SettingsManager

**Display Tab:**
- Window Mode (Windowed/Fullscreen/Borderless)
- VSync (Disabled/Enabled/Adaptive)
- Resolution (1280x720 to 3840x2160)
- Changes apply immediately

**Controls Tab:**
- Lists common input actions
- Rebind button - click and press new key
- Reset button - restores default
- Dynamically generated from InputMap

**Features:**
- Process mode ALWAYS (works while paused)
- Tabbed interface for organization
- All settings persist via SettingsManager
- Back button applies settings

---

## AudioSlider Component

Reusable volume slider you can add to any UI.

**Usage:**

1. In your UI scene, add a node: **+ → Instance Child Scene**
2. Select `res://src/ui/components/audio_slider.tscn`
3. In Inspector, set `bus_name` to: Master, Music, SFX, UI, or Ambience

**Features:**
- Auto-loads current volume from AudioManager
- Updates AudioManager and SettingsManager on change
- Shows percentage value
- Plays SFX when adjusting SFX volume (for preview)

**Script Access:**
```gdscript
@onready var master_slider: AudioSlider = %MasterSlider
# Slider automatically handles everything
```

---

## Customization

### Styling Menus

**Apply a Theme:**
1. Create a Theme resource
2. In each menu's root Control node, set the Theme property
3. Configure fonts, colors, button styles, etc.

**Background:**
```gdscript
# Replace the ColorRect background in main_menu.tscn
# with a TextureRect or AnimatedSprite2D
```

**Animations:**
```gdscript
# Add AnimationPlayer to menus
# Animate buttons sliding in, fading, etc.
# Example: Animate VBoxContainer position/modulate on _ready()
```

### Adding Menu Buttons

**Example: Add "Credits" button to MainMenu:**

1. Open `main_menu.tscn`
2. Select VBoxContainer
3. Add child → Button
4. Name it "CreditsButton", set unique name
5. In `main_menu.gd`:

```gdscript
@onready var credits_button: Button = %CreditsButton

func _ready():
    # ... existing code ...
    credits_button.pressed.connect(_on_credits_pressed)

func _on_credits_pressed():
    AudioManager.play_sfx(...)
    SceneManager.push_scene("res://ui/screens/credits.tscn")
```

### Custom Settings Sections

**Add a "Gameplay" tab:**

1. Open `settings_menu.tscn`
2. Select TabContainer
3. Add child → MarginContainer
4. Set metadata `_tab_index` to 3 (next available)
5. Add your custom controls inside
6. Connect signals in `settings_menu.gd`

---

## Integration Examples

### Starting Game Flow

```gdscript
# GameManager automatically loads main_menu.tscn on startup
# User clicks Play
# → main_menu.gd calls SceneManager.change_scene(first_level_scene)
# → Game scene loads
# → Game emits EventBus.game_started
# → GameManager sets state to PLAYING
```

### Pause Flow

```gdscript
# User presses ESC during gameplay
# → GameManager._handle_pause_input() detects PLAYING state
# → GameManager.pause_game() called
# → SceneManager.push_scene(pause_menu_scene)
# → Game paused, pause menu shows

# User clicks Resume
# → pause_menu.gd calls SceneManager.pop_scene()
# → pause_menu.gd calls GameManager.resume_game()
# → Game continues
```

### Settings Flow

```gdscript
# From any menu, user clicks Settings
# → SceneManager.push_scene(settings_menu)
# → User adjusts volumes, changes display mode
# → AudioSliders auto-update AudioManager & SettingsManager
# → User clicks Back
# → SettingsManager.apply_all_settings()
# → SceneManager.pop_scene()
# → Returns to previous menu
```

---

## Scene Paths in Constants

The menus use these constants for scene loading:

```gdscript
Constants.SCENE_MAIN_MENU     # Main menu path
Constants.SCENE_PAUSE_MENU    # Pause menu path  
Constants.SCENE_SETTINGS_MENU # Settings menu path
```

Update these in `constants.gd` if you move the scenes.

---

## Audio Integration

Menus attempt to play `res://audio/sfx/ui_click.wav` on button presses.

**To add UI sounds:**

1. Create `res://audio/sfx/ui_click.wav`
2. Menus will auto-play it
3. Or replace the path in each menu script:
   ```gdscript
   AudioManager.play_sfx(preload("res://audio/sfx/your_sound.wav"))
   ```

**To add menu music:**

In `main_menu.gd`, uncomment and configure:
```gdscript
func _ready():
    # ...
    AudioManager.play_music(preload("res://audio/music/menu_theme.ogg"))
```

---

## Process Modes

**MainMenu:** Default (INHERIT)
- Normal processing, game isn't paused yet

**PauseMenu & SettingsMenu:** ALWAYS (3)
- Continue processing even when game is paused
- Allows UI to respond while game tree is paused
- Dimmer prevents clicking through to game

---

## Keyboard Navigation

All menus support keyboard/gamepad navigation:
- Arrow keys / D-pad to navigate
- Enter / A button to select
- ESC / B button to go back (in pause/settings)

First button auto-focused on _ready().

---

## Common Customizations

### Change Button Appearance

1. Select any button in a menu
2. Inspector → Theme Overrides
3. Add fonts, colors, styleboxes
4. Or apply a theme resource to the whole menu

### Add Logo

```gdscript
# In main_menu.tscn
[node name="Logo" type="TextureRect" parent="CenterContainer/VBoxContainer"]
# Place above Title
texture = preload("res://assets/logo.png")
```

### Loading Screen Between Menu and Game

In `main_menu.gd`:
```gdscript
func _on_play_pressed():
    SceneManager.change_scene(
        first_level_scene, 
        transition,
        true  # use_loading_screen
    )
```

Requires `loading_screen_scene` set in SceneManager.

### Confirmation Dialogs

```gdscript
# In main_menu.gd for quit confirmation
func _on_quit_pressed():
    var dialog = AcceptDialog.new()
    dialog.dialog_text = "Are you sure you want to quit?"
    dialog.confirmed.connect(get_tree().quit)
    add_child(dialog)
    dialog.popup_centered()
```

---

## Troubleshooting

**"AudioSlider not found" error:**
- Check that audio_slider.tscn has uid="uid://audio_slider_001"
- Re-save the scene to generate a UID
- Or use relative path in settings_menu.tscn

**Settings not persisting:**
- Verify SettingsManager is in autoloads
- Check user://settings.cfg is being created
- Call SettingsManager.save_settings() if needed

**Pause menu doesn't show:**
- Verify pause_menu_scene path in GameManager
- Check pause input action exists ("pause" or "ui_cancel")
- Ensure GameManager is in autoloads

**Transitions not working:**
- Create at least one transition resource (.tres file)
- Set it in SceneManager or pass to change_scene()
- Check SceneTransition classes are in res://src/systems/

---

## Next Steps

1. ✓ Menus are ready to use
2. Create your first game scene/level
3. Test the full flow: Main Menu → Play → Pause → Settings → Resume
4. Customize menu appearance with themes
5. Add game-specific settings to Settings menu
6. Create credits/how-to-play screens if needed