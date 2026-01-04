extends GdUnitTestSuite
## Unit tests for AudioManager
##
## Tests SFX playback, music transitions, volume control, and pool management

var audio_manager: Node
var test_stream: AudioStream


func before_test():
	# Create a test audio stream (minimal silent stream)
	test_stream = AudioStreamGenerator.new()
	test_stream.mix_rate = 44100.0
	test_stream.buffer_length = 0.1
	
	# Create AudioManager instance
	audio_manager = load("res://src/core/managers/audio_manager.gd").new()
	add_child(audio_manager)
	
	# Wait for ready
	await get_tree().process_frame


func after_test():
	if is_instance_valid(audio_manager):
		audio_manager.queue_free()
		await get_tree().process_frame
	audio_manager = null
	test_stream = null


func test_sfx_player_pool_initialization():
	# Pool should have 16 players by default
	assert_int(audio_manager._sfx_players.size()).is_equal(16)
	
	# All should be AudioStreamPlayer
	for player in audio_manager._sfx_players:
		assert_that(player).is_instanceof(AudioStreamPlayer)
		assert_str(player.bus).is_equal("SFX")


func test_play_sfx():
	# Should play without errors
	audio_manager.play_sfx(test_stream, false)
	
	# At least one player should be playing
	var playing_count = 0
	for player in audio_manager._sfx_players:
		if player.playing:
			playing_count += 1
	
	assert_int(playing_count).is_greater(0)


func test_play_sfx_with_variance():
	audio_manager.play_sfx(test_stream, true)
	
	# Find the playing player
	var playing_player = null
	for player in audio_manager._sfx_players:
		if player.playing:
			playing_player = player
			break
	
	assert_that(playing_player).is_not_null()
	# Pitch should be varied (not exactly 1.0)
	assert_float(playing_player.pitch_scale).is_not_equal(1.0)


func test_play_sfx_pool_exhaustion():
	# Fill up the entire pool
	for i in 16:
		audio_manager.play_sfx(test_stream, false)
	
	# All players should be in use
	var available = audio_manager._get_available_sfx_player()
	assert_that(available).is_null()


func test_play_sfx_null_stream():
	# Should not crash, just warn
	audio_manager.play_sfx(null)
	
	# No players should be playing
	for player in audio_manager._sfx_players:
		assert_bool(player.playing).is_false()


func test_music_players_initialized():
	assert_that(audio_manager._current_music_player).is_not_null()
	assert_that(audio_manager._next_music_player).is_not_null()
	assert_str(audio_manager._current_music_player.bus).is_equal("Music")
	assert_str(audio_manager._next_music_player.bus).is_equal("Music")


func test_play_music():
	audio_manager.play_music(test_stream, false)
	
	assert_bool(audio_manager._current_music_player.playing).is_true()
	assert_that(audio_manager._current_music_player.stream).is_equal(test_stream)


func test_stop_music():
	audio_manager.play_music(test_stream, false)
	audio_manager.stop_music(false)
	
	assert_bool(audio_manager._current_music_player.playing).is_false()


func test_music_crossfade():
	var stream1 = AudioStreamGenerator.new()
	stream1.mix_rate = 44100.0
	stream1.buffer_length = 0.1
	
	var stream2 = AudioStreamGenerator.new()
	stream2.mix_rate = 44100.0
	stream2.buffer_length = 0.1
	
	# Play first track
	audio_manager.play_music(stream1, false)
	await get_tree().process_frame
	
	# Crossfade to second track
	audio_manager.play_music(stream2, true)
	await get_tree().process_frame
	
	# Current player should now have stream2
	assert_that(audio_manager._current_music_player.stream).is_equal(stream2)


func test_set_bus_volume():
	audio_manager.set_bus_volume("Master", 0.5)
	
	var retrieved_volume = audio_manager.get_bus_volume("Master")
	assert_float(retrieved_volume).is_between(0.4, 0.6)


func test_get_bus_volume():
	# Set a specific volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(0.7))
	
	var volume = audio_manager.get_bus_volume("Master")
	assert_float(volume).is_between(0.6, 0.8)


func test_set_bus_volume_invalid_bus():
	# Should not crash, just warn
	audio_manager.set_bus_volume("InvalidBus", 0.5)
	
	# Should return 0.0 for invalid bus
	var volume = audio_manager.get_bus_volume("InvalidBus")
	assert_float(volume).is_equal(0.0)


func test_mute_bus():
	audio_manager.set_bus_mute("Master", true)
	
	var bus_index = AudioServer.get_bus_index("Master")
	assert_bool(AudioServer.is_bus_mute(bus_index)).is_true()
	
	audio_manager.set_bus_mute("Master", false)
	assert_bool(AudioServer.is_bus_mute(bus_index)).is_false()


func test_playlist_next():
	var stream1 = AudioStreamGenerator.new()
	var stream2 = AudioStreamGenerator.new()
	var stream3 = AudioStreamGenerator.new()

	var playlist: Array[AudioStream] = []
	playlist.append(stream1)
	playlist.append(stream2)
	playlist.append(stream3)

	audio_manager.music_playlist = playlist
	
	audio_manager.play_next_in_playlist()
	assert_that(audio_manager._current_music_player.stream).is_equal(stream1)
	
	audio_manager.play_next_in_playlist()
	assert_that(audio_manager._current_music_player.stream).is_equal(stream2)
	
	audio_manager.play_next_in_playlist()
	assert_that(audio_manager._current_music_player.stream).is_equal(stream3)
	
	# Should loop back
	audio_manager.play_next_in_playlist()
	assert_that(audio_manager._current_music_player.stream).is_equal(stream1)


func test_playlist_previous():
	var stream1 = AudioStreamGenerator.new()
	var stream2 = AudioStreamGenerator.new()
	var stream3 = AudioStreamGenerator.new()

	var playlist: Array[AudioStream] = []
	playlist.append(stream1)
	playlist.append(stream2)
	playlist.append(stream3)
	audio_manager.music_playlist = playlist
	audio_manager._current_playlist_index = 1
	
	audio_manager.play_previous_in_playlist()
	assert_that(audio_manager._current_music_player.stream).is_equal(stream1)
	
	# Should wrap around
	audio_manager.play_previous_in_playlist()
	assert_that(audio_manager._current_music_player.stream).is_equal(stream3)


func test_exit_tree_cleanup():
	audio_manager.play_music(test_stream)
	audio_manager.play_sfx(test_stream)
	
	# Should not crash
	audio_manager._exit_tree()