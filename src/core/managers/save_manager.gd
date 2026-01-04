extends Node
class_name SaveManager

## Manages game save and load operations
##
## Supports multiple save slots, JSON or binary formats, optional encryption,
## and auto-save functionality.

signal save_completed(slot: int)
signal load_completed(slot: int)
signal save_failed(slot: int, error: String)
signal load_failed(slot: int, error: String)

## Base directory for save files (user:// is platform-specific user data)
@export var save_directory: String = "user://saves/"

## File name template (use {slot} for slot number)
@export var save_file_template: String = "save_{slot}.dat"

## Use binary format instead of JSON (smaller, faster, not human-readable)
@export var use_binary_format: bool = false

## Encrypt save files (basic XOR encryption)
@export var encrypt_saves: bool = false

## Encryption password (change this for your game!)
@export var encryption_password: String = "your_game_encryption_key_here"

## Number of save slots available
@export var max_save_slots: int = 3

## Auto-save enabled
@export var auto_save_enabled: bool = false

## Auto-save interval in seconds
@export var auto_save_interval: float = 300.0

## Auto-save slot (separate from manual saves)
@export var auto_save_slot: int = 99

var _auto_save_timer: Timer
var _current_save_data: Dictionary = {}


func _ready() -> void:
	_ensure_save_directory_exists()
	
	if auto_save_enabled:
		_setup_auto_save()


func _setup_auto_save() -> void:
	_auto_save_timer = Timer.new()
	_auto_save_timer.wait_time = auto_save_interval
	_auto_save_timer.timeout.connect(_on_auto_save_timeout)
	_auto_save_timer.autostart = true
	add_child(_auto_save_timer)


func _on_auto_save_timeout() -> void:
	save_game(auto_save_slot)


## Save game data to a specific slot
func save_game(slot: int, custom_data: Dictionary = {}) -> bool:
	if slot < 0 or (slot != auto_save_slot and slot >= max_save_slots):
		push_error("SaveManager: Invalid save slot %d" % slot)
		save_failed.emit(slot, "Invalid slot number")
		return false
	
	var save_data = _gather_save_data()
	save_data.merge(custom_data, true)  # Custom data overrides gathered data
	
	var file_path = _get_save_file_path(slot)
	var success = _write_save_file(file_path, save_data)
	
	if success:
		_current_save_data = save_data
		save_completed.emit(slot)
		GameServices.events.game_saved.emit()
		return true
	else:
		save_failed.emit(slot, "Failed to write save file")
		return false


## Load game data from a specific slot
func load_game(slot: int) -> Dictionary:
	if slot < 0 or (slot != auto_save_slot and slot >= max_save_slots):
		push_error("SaveManager: Invalid save slot %d" % slot)
		load_failed.emit(slot, "Invalid slot number")
		return {}
	
	if not save_exists(slot):
		push_warning("SaveManager: No save file found in slot %d" % slot)
		load_failed.emit(slot, "Save file not found")
		return {}
	
	var file_path = _get_save_file_path(slot)
	var save_data = _read_save_file(file_path)
	
	if save_data.is_empty():
		load_failed.emit(slot, "Failed to read save file")
		return {}
	
	_current_save_data = save_data
	_apply_save_data(save_data)
	load_completed.emit(slot)
	GameServices.events.game_loaded.emit()
	
	return save_data


## Delete save file in a specific slot
func delete_save(slot: int) -> bool:
	if slot < 0 or (slot != auto_save_slot and slot >= max_save_slots):
		push_error("SaveManager: Invalid save slot %d" % slot)
		return false
	
	var file_path = _get_save_file_path(slot)
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
		return true
	return false


## Check if a save exists in a specific slot
func save_exists(slot: int) -> bool:
	var file_path = _get_save_file_path(slot)
	return FileAccess.file_exists(file_path)


## Get metadata about a save (timestamp, play time, etc.)
func get_save_metadata(slot: int) -> Dictionary:
	if not save_exists(slot):
		return {}
	
	var file_path = _get_save_file_path(slot)
	var save_data = _read_save_file(file_path)
	
	if save_data.has("metadata"):
		return save_data["metadata"]
	return {}


## Get current save data without loading
func get_current_save_data() -> Dictionary:
	return _current_save_data.duplicate(true)


## Manually set current save data
func set_current_save_data(data: Dictionary) -> void:
	_current_save_data = data


func _get_save_file_path(slot: int) -> String:
	var filename = save_file_template.replace("{slot}", str(slot))
	return save_directory + filename


func _ensure_save_directory_exists() -> void:
	if not DirAccess.dir_exists_absolute(save_directory):
		DirAccess.make_dir_recursive_absolute(save_directory)


func _gather_save_data() -> Dictionary:
	var save_data = {
		"metadata": {
			"timestamp": Time.get_unix_time_from_system(),
			"game_version": ProjectSettings.get_setting("application/config/version", "1.0.0"),
			"play_time": 0.0,  # Override this with your actual play time tracking
		},
		"player": {},
		"game_state": {},
		"settings": {},
	}
	
	# Add any custom save data here or let callers pass custom_data
	# Example: save_data["player"]["position"] = player.position
	
	return save_data


func _apply_save_data(save_data: Dictionary) -> void:
	# Apply loaded data to game state
	# This is where you'd restore player position, inventory, etc.
	# Override or extend this in your game-specific save manager
	
	if save_data.has("player"):
		pass  # Apply player data
	
	if save_data.has("game_state"):
		pass  # Apply game state data


func _write_save_file(file_path: String, data: Dictionary) -> bool:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		push_error("SaveManager: Failed to open file for writing: %s" % file_path)
		return false
	
	var content: String
	if use_binary_format:
		content = var_to_str(data)
	else:
		content = JSON.stringify(data, "\t")
	
	if encrypt_saves:
		content = _encrypt_string(content)
	
	file.store_string(content)
	file.close()
	return true


func _read_save_file(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("SaveManager: Failed to open file for reading: %s" % file_path)
		return {}
	
	var content = file.get_as_text()
	file.close()
	
	if encrypt_saves:
		content = _decrypt_string(content)
	
	var data: Dictionary
	if use_binary_format:
		data = str_to_var(content)
		if not data is Dictionary:
			push_error("SaveManager: Invalid save data format")
			return {}
	else:
		var json = JSON.new()
		var parse_result = json.parse(content)
		if parse_result != OK:
			push_error("SaveManager: Failed to parse JSON save file")
			return {}
		data = json.data
		if not data is Dictionary:
			push_error("SaveManager: Save file does not contain a Dictionary")
			return {}
	
	return data


func _encrypt_string(text: String) -> String:
	var key = encryption_password.to_utf8_buffer()
	var data = text.to_utf8_buffer()
	var encrypted = PackedByteArray()
	
	for i in range(data.size()):
		encrypted.append(data[i] ^ key[i % key.size()])
	
	return encrypted.hex_encode()


func _decrypt_string(encrypted_hex: String) -> String:
	var key = encryption_password.to_utf8_buffer()
	var encrypted = encrypted_hex.hex_decode()
	var decrypted = PackedByteArray()
	
	for i in range(encrypted.size()):
		decrypted.append(encrypted[i] ^ key[i % key.size()])
	
	return decrypted.get_string_from_utf8()