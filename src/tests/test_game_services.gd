extends GdUnitTestSuite
## Unit tests for GameServices
##
## Tests service loading, lazy initialization, and dependency management

var game_services: Node


func before_test():
	# Load the GameServices script
	var script = load("res://src/autoloads/game_services.gd")
	game_services = script.new()
	add_child(game_services)
	
	# Wait for initialization
	await get_tree().process_frame
	await get_tree().process_frame


func after_test():
	if is_instance_valid(game_services):
		game_services.queue_free()
		await get_tree().process_frame
	game_services = null


func test_core_services_always_loaded():
	# EventBus and InputHelper should be loaded immediately
	assert_that(game_services.events).is_not_null()
	assert_that(game_services.input).is_not_null()
	
	assert_bool(game_services.is_service_loaded("events")).is_true()
	assert_bool(game_services.is_service_loaded("input")).is_true()


func test_lazy_services_not_loaded_initially():
	# These should not be loaded until accessed
	assert_bool(game_services._audio).is_null()
	assert_bool(game_services._settings).is_null()
	assert_bool(game_services._save).is_null()
	assert_bool(game_services._scenes).is_null()
	assert_bool(game_services._game).is_null()


func test_audio_lazy_loading():
	assert_bool(game_services.is_service_loaded("audio")).is_false()
	
	# Access audio - should trigger loading
	var audio = game_services.audio
	
	assert_that(audio).is_not_null()
	assert_bool(game_services.is_service_loaded("audio")).is_true()


func test_settings_lazy_loading():
	assert_bool(game_services.is_service_loaded("settings")).is_false()
	
	var settings = game_services.settings
	
	assert_that(settings).is_not_null()
	assert_bool(game_services.is_service_loaded("settings")).is_true()


func test_save_lazy_loading():
	assert_bool(game_services.is_service_loaded("save")).is_false()
	
	var save = game_services.save
	
	assert_that(save).is_not_null()
	assert_bool(game_services.is_service_loaded("save")).is_true()


func test_scenes_lazy_loading():
	assert_bool(game_services.is_service_loaded("scenes")).is_false()
	
	var scenes = game_services.scenes
	
	assert_that(scenes).is_not_null()
	assert_bool(game_services.is_service_loaded("scenes")).is_true()


func test_game_lazy_loading():
	assert_bool(game_services.is_service_loaded("game")).is_false()
	
	var game = game_services.game
	
	assert_that(game).is_not_null()
	assert_bool(game_services.is_service_loaded("game")).is_true()


func test_dependency_order_settings_before_audio():
	# When audio is accessed, settings should be loaded first
	var _dummy_audio = game_services.audio
	
	assert_bool(game_services.is_service_loaded("settings")).is_true()
	assert_bool(game_services.is_service_loaded("audio")).is_true()


func test_dependency_order_scenes_before_game():
	# When game is accessed, scenes should be loaded first
	var _dummy_game = game_services.game
	
	assert_bool(game_services.is_service_loaded("scenes")).is_true()
	assert_bool(game_services.is_service_loaded("game")).is_true()


func test_multiple_accesses_dont_recreate():
	var audio1 = game_services.audio
	var audio2 = game_services.audio
	
	# Should be the same instance
	assert_that(audio1).is_same(audio2)


func test_get_loaded_services():
	var loaded = game_services.get_loaded_services()
	
	# Initially should have events and input
	assert_that(loaded.has("events")).is_true()
	assert_that(loaded.has("input")).is_true()
	
	# Load audio
	var _audio = game_services.audio
	loaded = game_services.get_loaded_services()
	
	assert_that(loaded.has("audio")).is_true()


func test_preload_all_services():
	# Initially only core services loaded
	assert_bool(game_services.is_service_loaded("audio")).is_false()
	assert_bool(game_services.is_service_loaded("save")).is_false()
	
	game_services.preload_all_services()
	
	# Now all should be loaded
	assert_bool(game_services.is_service_loaded("audio")).is_true()
	assert_bool(game_services.is_service_loaded("settings")).is_true()
	assert_bool(game_services.is_service_loaded("save")).is_true()
	assert_bool(game_services.is_service_loaded("scenes")).is_true()
	assert_bool(game_services.is_service_loaded("game")).is_true()


func test_is_service_loaded_invalid_name():
	var result = game_services.is_service_loaded("invalid_service")
	assert_bool(result).is_false()


func test_services_are_children():
	var _audio = game_services.audio
	var _settings = game_services.settings
	
	# Services should be children of GameServices
	assert_bool(game_services.audio.get_parent() == game_services).is_true()
	assert_bool(game_services.settings.get_parent() == game_services).is_true()


func test_events_has_signals():
	# EventBus should have proper signals
	assert_that(game_services.events.has_signal("game_started")).is_true()
	assert_that(game_services.events.has_signal("player_damaged")).is_true()


func test_input_has_methods():
	# InputHelper should have proper methods
	assert_that(game_services.input.has_method("get_movement_vector")).is_true()
	assert_that(game_services.input.has_method("is_action_buffered")).is_true()


func test_audio_has_methods():
	var audio = game_services.audio
	
	assert_that(audio.has_method("play_sfx")).is_true()
	assert_that(audio.has_method("play_music")).is_true()
	assert_that(audio.has_method("set_bus_volume")).is_true()


func test_settings_has_methods():
	var settings = game_services.settings
	
	assert_that(settings.has_method("get_setting")).is_true()
	assert_that(settings.has_method("set_setting")).is_true()
	assert_that(settings.has_method("save_settings")).is_true()


func test_save_has_methods():
	var save = game_services.save
	
	assert_that(save.has_method("save_game")).is_true()
	assert_that(save.has_method("load_game")).is_true()
	assert_that(save.has_method("delete_save")).is_true()


func test_scenes_has_methods():
	var scenes = game_services.scenes
	
	assert_that(scenes.has_method("change_scene")).is_true()
	assert_that(scenes.has_method("push_scene")).is_true()
	assert_that(scenes.has_method("pop_scene")).is_true()


func test_game_has_methods():
	var game = game_services.game
	
	assert_that(game.has_method("pause_game")).is_true()
	assert_that(game.has_method("resume_game")).is_true()
	assert_that(game.has_method("set_state")).is_true()


func test_service_names_correct():
	var loaded = game_services.get_loaded_services()
	
	# Should only contain valid service names
	for service_name in loaded:
		assert_bool(["events", "input", "audio", "settings", "save", "scenes", "game"].has(service_name)).is_true()


func test_service_lifecycle():
	# Initially not loaded
	assert_bool(game_services.is_service_loaded("audio")).is_false()
	
	# Load it
	var audio = game_services.audio
	assert_bool(game_services.is_service_loaded("audio")).is_true()
	assert_that(audio.get_parent()).is_not_null()
	
	# Should persist
	var audio2 = game_services.audio
	assert_that(audio2).is_same(audio)