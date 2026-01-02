extends Node
## Manages audio playback, bus volumes, and music crossfading
##
## Handles SFX with pitch/volume variance, music transitions, and 
## persistent volume settings via SettingsManager integration.

## Default music crossfade duration in seconds
@export var music_crossfade_duration: float = 1.5

## SFX pitch randomization range (1.0 = no randomization)
@export_range(0.0, 1.0) var sfx_pitch_variance: float = 0.1

## SFX volume randomization range in dB
@export_range(0.0, 6.0) var sfx_volume_variance_db: float = 2.0

## Number of AudioStreamPlayer nodes to pool for SFX
@export var sfx_player_pool_size: int = 16

## Music playlist for sequential/random playback
@export var music_playlist: Array[AudioStream] = []

## Whether to loop through the playlist
@export var loop_playlist: bool = true

## Bus name constants
const BUS_MASTER = "Master"
const BUS_MUSIC = "Music"
const BUS_SFX = "SFX"
const BUS_UI = "UI"
const BUS_AMBIENCE = "Ambience"
const BUS_VOICE = "Voice"


var _sfx_players: Array[AudioStreamPlayer] = []
var _current_music_player: AudioStreamPlayer
var _next_music_player: AudioStreamPlayer
var _music_tween: Tween
var _current_playlist_index: int = -1


func _ready() -> void:
	_setup_music_players()
	_setup_sfx_pool()
	_load_volumes_from_settings()


func _setup_music_players() -> void:
	_current_music_player = AudioStreamPlayer.new()
	_current_music_player.bus = BUS_MUSIC
	add_child(_current_music_player)
	
	_next_music_player = AudioStreamPlayer.new()
	_next_music_player.bus = BUS_MUSIC
	add_child(_next_music_player)


func _setup_sfx_pool() -> void:
	for i in sfx_player_pool_size:
		var player = AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		_sfx_players.append(player)


## Play a sound effect with optional pitch/volume variance
func play_sfx(stream: AudioStream, variance: bool = true, bus: String = BUS_SFX) -> void:
	if not stream:
		push_warning("AudioManager: Attempted to play null SFX stream")
		return
	
	var player = _get_available_sfx_player()
	if not player:
		push_warning("AudioManager: No available SFX players in pool")
		return
	
	player.stream = stream
	player.bus = bus
	
	if variance:
		player.pitch_scale = 1.0 + randf_range(-sfx_pitch_variance, sfx_pitch_variance)
		player.volume_db = randf_range(-sfx_volume_variance_db, sfx_volume_variance_db)
	else:
		player.pitch_scale = 1.0
		player.volume_db = 0.0
	
	player.play()


## Play music with optional crossfade from current track
func play_music(stream: AudioStream, crossfade: bool = true) -> void:
	if not stream:
		push_warning("AudioManager: Attempted to play null music stream")
		return
	
	if _current_music_player.playing and crossfade:
		_crossfade_to_music(stream)
	else:
		_current_music_player.stream = stream
		_current_music_player.play()


## Stop music with optional fadeout
func stop_music(fadeout: bool = true) -> void:
	if fadeout and _current_music_player.playing:
		if _music_tween:
			_music_tween.kill()
		_music_tween = create_tween()
		_music_tween.tween_property(_current_music_player, "volume_db", -80, music_crossfade_duration)
		_music_tween.tween_callback(_current_music_player.stop)
		_music_tween.tween_callback(func(): _current_music_player.volume_db = 0)
	else:
		_current_music_player.stop()


## Play next track in playlist
func play_next_in_playlist() -> void:
	if music_playlist.is_empty():
		push_warning("AudioManager: Music playlist is empty")
		return
	
	_current_playlist_index = (_current_playlist_index + 1) % music_playlist.size()
	play_music(music_playlist[_current_playlist_index])


## Play previous track in playlist
func play_previous_in_playlist() -> void:
	if music_playlist.is_empty():
		push_warning("AudioManager: Music playlist is empty")
		return
	
	_current_playlist_index = (_current_playlist_index - 1) % music_playlist.size()
	if _current_playlist_index < 0:
		_current_playlist_index = music_playlist.size() - 1
	play_music(music_playlist[_current_playlist_index])


## Set volume for a specific bus (0.0 to 1.0)
func set_bus_volume(bus_name: String, volume: float) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("AudioManager: Bus '%s' not found" % bus_name)
		return
	
	var db = linear_to_db(clamp(volume, 0.0, 1.0))
	AudioServer.set_bus_volume_db(bus_index, db)
	
	# Save to settings
	if SettingsManager:
		SettingsManager.set_setting("audio", bus_name.to_lower() + "_volume", volume)


## Get volume for a specific bus (0.0 to 1.0)
func get_bus_volume(bus_name: String) -> float:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("AudioManager: Bus '%s' not found" % bus_name)
		return 0.0
	
	var db = AudioServer.get_bus_volume_db(bus_index)
	return db_to_linear(db)


## Mute/unmute a specific bus
func set_bus_mute(bus_name: String, muted: bool) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("AudioManager: Bus '%s' not found" % bus_name)
		return
	
	AudioServer.set_bus_mute(bus_index, muted)


func _crossfade_to_music(new_stream: AudioStream) -> void:
	# Swap players
	var temp = _current_music_player
	_current_music_player = _next_music_player
	_next_music_player = temp
	
	# Setup new track
	_current_music_player.stream = new_stream
	_current_music_player.volume_db = -80
	_current_music_player.play()
	
	# Crossfade
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.set_parallel(true)
	_music_tween.tween_property(_current_music_player, "volume_db", 0, music_crossfade_duration)
	_music_tween.tween_property(_next_music_player, "volume_db", -80, music_crossfade_duration)
	_music_tween.chain().tween_callback(_next_music_player.stop)
	_music_tween.tween_callback(func(): _next_music_player.volume_db = 0)


func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			return player
	return null


func _load_volumes_from_settings() -> void:
	if not SettingsManager:
		return
	
	var buses = [BUS_MASTER, BUS_MUSIC, BUS_SFX, BUS_UI, BUS_AMBIENCE, BUS_VOICE]
	for bus in buses:
		var volume = SettingsManager.get_setting("audio", bus.to_lower() + "_volume", 1.0)
		set_bus_volume(bus, volume)