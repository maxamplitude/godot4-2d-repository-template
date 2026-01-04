# Quick Input Setup Guide

## Required Actions for Template to Work

Follow these steps to add the minimum required input actions:

### Step-by-Step Instructions

1. **Open Project Settings**
   - Menu: Project → Project Settings
   - Select the "Input Map" tab

2. **Add "pause" action**
   - At the top, type `pause` in the "Action" field
   - Click "Add" button
   - Click the + button next to "pause" in the list
   - Select "Key" from dropdown
   - Press `Escape` on your keyboard
   - Click OK
   - Click the + again, add another Key, press `P`
   - (Optional) Add Joypad Button → Start (button index 6)

3. **Add "toggle_fullscreen" action**
   - Type `toggle_fullscreen` in the "Action" field
   - Click "Add"
   - Click the + button
   - Select "Key"
   - Press `F11`
   - Click OK

4. **Add "toggle_debug" action**
   - Type `toggle_debug` in the "Action" field
   - Click "Add"
   - Click the + button
   - Select "Key"
   - Press `F3`
   - Click OK

5. **Close Project Settings**
   - Click "Close" button
   - Run your project (F5) - errors should be gone!

---

## Recommended: Add Gameplay Actions

For a complete setup, also add these:

### Movement Actions

**move_left:**
- Key: A
- Key: Left Arrow
- Joypad Button: D-pad Left (button 13)
- Joypad Motion: Left Stick X, value -1.0

**move_right:**
- Key: D
- Key: Right Arrow
- Joypad Button: D-pad Right (button 14)
- Joypad Motion: Left Stick X, value 1.0

**move_up:**
- Key: W
- Key: Up Arrow
- Joypad Button: D-pad Up (button 11)
- Joypad Motion: Left Stick Y, value -1.0

**move_down:**
- Key: S
- Key: Down Arrow
- Joypad Button: D-pad Down (button 12)
- Joypad Motion: Left Stick Y, value 1.0

### Action Buttons

**jump:**
- Key: Space
- Joypad Button: A / Cross (button 0)

**attack:**
- Key: J or Z
- Mouse Button: Left
- Joypad Button: X / Square (button 2)

**interact:**
- Key: E
- Joypad Button: A / Cross (button 0)

---

### InputHelper (GameServices.input)

`GameServices.input` depends on these action names for movement vectors, buffering, and combo detection. Use helpers like `GameServices.input.get_movement_vector()`, `GameServices.input.consume_buffered_action("jump")`, and `GameServices.input.check_combo_sequence(...)` so your gameplay code matches the template's input feel.

## Using default_input_map.gd

Alternatively, you can use the reference script to set these up programmatically:

1. Create a new tool script in your project
2. Copy the functions from `default_input_map.gd`
3. Call them in a tool script's `_ready()` or via @tool and editor button
4. Or just use the script as a reference when adding manually

---

## Verification

After setup, your Input Map should show:
- ✓ pause (Escape, P)
- ✓ toggle_fullscreen (F11)
- ✓ toggle_debug (F3)
- ✓ ui_cancel (already exists - Godot default)

Plus any gameplay actions you added.

---

## Common Issues

**"Action doesn't exist" errors:**
- Make sure you clicked "Add" after typing the action name
- Check spelling matches exactly (case-sensitive)
- Close and reopen project if actions don't appear

**Gamepad not working:**
- Connect gamepad before starting Godot
- Test in Input Map - press gamepad button, it should show up
- Button indices may vary by controller type

**Keys not responding:**
- Ensure you selected "Key" not "Button" when adding keyboard inputs
- Make sure you pressed the actual key during setup
- Try removing and re-adding the input event