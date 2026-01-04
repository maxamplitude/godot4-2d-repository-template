extends GdUnitTestSuite
## Unit tests for SaveManager
##
## Tests save/load operations, encryption, slots, and error handling

var save_manager: Node
var event_bus: Node
var test_save_dir: String


func before_test():
	# Use a temporary directory for tests
	test_save_dir = "user://test_saves/"
	
	# Create SaveManager instance
	save_manager = load("res://src/core/managers/save_manager.gd").new()
	save_manager.save_directory = test_save_dir
	save_manager.auto_save_enabled = false  # Disable auto-save for tests
	add_child(save_manager)

	event_bus = load("res://src/core/managers/event_bus.gd").new()
	add_child(event_bus)
	
	await get_tree().process_frame


func after_test():
	_clear_signal_monitors()
	# Clean up test saves
	_cleanup_test_directory()
	
	if is_instance_valid(save_manager):
		save_manager.queue_free()
		await get_tree().process_frame
	save_manager = null
	if is_instance_valid(event_bus):
		event_bus.queue_free()
		await get_tree().process_frame
	event_bus = null

func _clear_signal_monitors() -> void:
	var context := GdUnitThreadManager.get_current_context()
	if context:
		var collector := context.get_signal_collector()
		if collector:
			collector.clear()


func _cleanup_test_directory():
	var dir = DirAccess.open("user://")
	if dir and dir.dir_exists("test_saves"):
		_remove_directory_recursive("user://test_saves/")


func _remove_directory_recursive(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var file_path = path + "/" + file_name
			if dir.current_is_dir():
				_remove_directory_recursive(file_path)
			else:
				dir.remove(file_path)
			file_name = dir.get_next()
		dir.list_dir_end()
		dir.remove(path)


func test_save_directory_creation():
	# Directory should be created automatically
	assert_bool(DirAccess.dir_exists_absolute(test_save_dir)).is_true()


func test_save_game_basic():
	var save_data = {"test_key": "test_value", "player_health": 100}
	var result = save_manager.save_game(0, save_data)
	
	assert_bool(result).is_true()
	assert_bool(save_manager.save_exists(0)).is_true()


func test_load_game_basic():
	# Save first
	var original_data = {"test_key": "test_value", "player_health": 100}
	save_manager.save_game(0, original_data)
	
	# Load it back
	var loaded_data = save_manager.load_game(0)
	
	assert_that(loaded_data).is_not_empty()
	assert_str(loaded_data.get("test_key", "")).is_equal("test_value")
	assert_float(loaded_data.get("player_health", 0.0)).is_equal(100.0)


func test_save_multiple_slots():
	save_manager.save_game(0, {"slot": 0})
	save_manager.save_game(1, {"slot": 1})
	save_manager.save_game(2, {"slot": 2})
	
	assert_bool(save_manager.save_exists(0)).is_true()
	assert_bool(save_manager.save_exists(1)).is_true()
	assert_bool(save_manager.save_exists(2)).is_true()
	
	var data0 = save_manager.load_game(0)
	var data1 = save_manager.load_game(1)
	var data2 = save_manager.load_game(2)
	
	assert_float(data0.get("slot", -1.0)).is_equal(0.0)
	assert_float(data1.get("slot", -1.0)).is_equal(1.0)
	assert_float(data2.get("slot", -1.0)).is_equal(2.0)


func test_delete_save():
	save_manager.save_game(0, {"test": "data"})
	assert_bool(save_manager.save_exists(0)).is_true()
	
	var deleted = save_manager.delete_save(0)
	assert_bool(deleted).is_true()
	assert_bool(save_manager.save_exists(0)).is_false()


func test_save_invalid_slot():
	# Negative slot
	var result = save_manager.save_game(-1, {})
	assert_bool(result).is_false()
	
	# Slot beyond max
	result = save_manager.save_game(99, {})
	assert_bool(result).is_true()


func test_load_nonexistent_save():
	var data = save_manager.load_game(5)
	assert_that(data).is_empty()


func test_save_with_encryption():
	save_manager.encrypt_saves = true
	save_manager.encryption_password = "test_password_123"
	
	var original_data = {"secret": "encrypted_data"}
	save_manager.save_game(0, original_data)
	
	var loaded_data = save_manager.load_game(0)
	assert_str(loaded_data.get("secret", "")).is_equal("encrypted_data")


func test_binary_format():
	save_manager.use_binary_format = true
	
	var original_data = {"test": "binary_format", "value": 42}
	save_manager.save_game(0, original_data)
	
	var loaded_data = save_manager.load_game(0)
	assert_str(loaded_data.get("test", "")).is_equal("binary_format")
	assert_int(loaded_data.get("value", 0)).is_equal(42)


func test_get_save_metadata():
	var custom_data = {"player_name": "Hero"}
	save_manager.save_game(0, custom_data)
	
	var metadata = save_manager.get_save_metadata(0)
	assert_that(metadata).is_not_empty()
	assert_that(metadata.has("timestamp")).is_true()
	assert_that(metadata.has("game_version")).is_true()


func test_save_completed_signal():
	var signal_monitor = monitor_signals(save_manager)
	var slot := {"value": 0}

	save_manager.save_game(slot.value, {"test": "signal"})

	assert_signal(signal_monitor).is_emitted("save_completed", [slot.value])


func test_load_completed_signal():
	var slot := {"value": 0}
	save_manager.save_game(slot.value, {"test": "signal"})
	
	var signal_monitor = monitor_signals(save_manager)
	save_manager.load_game(slot.value)
	
	assert_signal(signal_monitor).is_emitted("load_completed", [slot.value])


func test_auto_save_slot():
	# Auto-save slot (99) should work
	var result = save_manager.save_game(99, {"autosave": true})
	assert_bool(result).is_true()
	assert_bool(save_manager.save_exists(99)).is_true()


func test_get_current_save_data():
	var original_data = {"current": "data"}
	save_manager.save_game(0, original_data)
	
	var current = save_manager.get_current_save_data()
	assert_that(current).is_not_empty()


func test_set_current_save_data():
	var new_data = {"custom": "data"}
	save_manager.set_current_save_data(new_data)
	
	var retrieved = save_manager.get_current_save_data()
	assert_str(retrieved.get("custom", "")).is_equal("data")


func test_save_large_data():
	# Test with larger dataset
	var large_data = {}
	for i in 1000:
		large_data["key_%d" % i] = "value_%d" % i
	
	var result = save_manager.save_game(0, large_data)
	assert_bool(result).is_true()
	
	var loaded = save_manager.load_game(0)
	assert_int(loaded.keys().size()).is_greater_equal(1000)


func test_save_nested_data():
	var nested_data = {
		"player": {
			"name": "Hero",
			"stats": {
				"health": 100,
				"mana": 50
			}
		},
		"inventory": ["sword", "shield", "potion"]
	}
	
	save_manager.save_game(0, nested_data)
	var loaded = save_manager.load_game(0)
	
	assert_that(loaded.has("player")).is_true()
	assert_str(loaded["player"]["name"]).is_equal("Hero")
	assert_float(loaded["player"]["stats"]["health"]).is_equal(100.0)
	assert_that(loaded["inventory"]).is_equal(["sword", "shield", "potion"])