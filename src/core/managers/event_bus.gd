## Global event bus for decoupled communication between systems
##
## Provides common game signals to avoid direct node references.
## Connect to these signals instead of coupling systems together.

extends Node
class_name EventBus

# ============================================================================
# GAME STATE SIGNALS
# ============================================================================

@warning_ignore("unused_signal") ## Emitted when the game starts (from main menu to gameplay)
signal game_started

@warning_ignore("unused_signal") ## Emitted when the game is paused
signal game_paused

@warning_ignore("unused_signal") ## Emitted when the game is resumed from pause
signal game_resumed

@warning_ignore("unused_signal") ## Emitted when the game ends (victory or defeat)
signal game_ended(victory: bool)

@warning_ignore("unused_signal") ## Emitted when returning to main menu
signal returned_to_menu

@warning_ignore("unused_signal") ## Emitted when the current level/stage is completed
signal level_completed

@warning_ignore("unused_signal") ## Emitted when the player fails the level
signal level_failed

@warning_ignore("unused_signal") ## Emitted when restarting the current level
signal level_restarted


# ============================================================================
# PLAYER SIGNALS
# ============================================================================

@warning_ignore("unused_signal") ## Emitted when player takes damage
signal player_damaged(amount: float, source: Node)

@warning_ignore("unused_signal") ## Emitted when player is healed
signal player_healed(amount: float)

@warning_ignore("unused_signal") ## Emitted when player dies
signal player_died

@warning_ignore("unused_signal") ## Emitted when player respawns
signal player_respawned

@warning_ignore("unused_signal") ## Emitted when player health changes
signal player_health_changed(current_health: float, max_health: float)

@warning_ignore("unused_signal") ## Emitted when player gains score/points
signal score_changed(new_score: int, delta: int)


# ============================================================================
# COLLECTIBLES & POWERUPS
# ============================================================================

@warning_ignore("unused_signal") ## Emitted when player collects an item
signal item_collected(item_type: String, item_data: Dictionary)

@warning_ignore("unused_signal") ## Emitted when a powerup is activated
signal powerup_activated(powerup_type: String, duration: float)

@warning_ignore("unused_signal") ## Emitted when a powerup expires
signal powerup_expired(powerup_type: String)

@warning_ignore("unused_signal") ## Emitted when currency/coins are collected
signal currency_collected(amount: int)


# ============================================================================
# UI SIGNALS
# ============================================================================

@warning_ignore("unused_signal") ## Emitted when a UI screen/menu is opened
signal ui_screen_opened(screen_name: String)

@warning_ignore("unused_signal") ## Emitted when a UI screen/menu is closed
signal ui_screen_closed(screen_name: String)

@warning_ignore("unused_signal") ## Emitted when a button in the UI is pressed
signal ui_button_pressed(button_name: String)

@warning_ignore("unused_signal") ## Emitted when a dialogue box appears
signal dialogue_started(dialogue_id: String)

@warning_ignore("unused_signal") ## Emitted when a dialogue box is closed
signal dialogue_ended(dialogue_id: String)


# ============================================================================
# COMBAT/ACTION SIGNALS
# ============================================================================

@warning_ignore("unused_signal") ## Emitted when player attacks
signal player_attacked(target: Node)

@warning_ignore("unused_signal") ## Emitted when an enemy is damaged
signal enemy_damaged(enemy: Node, damage: float)

@warning_ignore("unused_signal") ## Emitted when an enemy dies
signal enemy_died(enemy: Node)

@warning_ignore("unused_signal") ## Emitted when an enemy spawns
signal enemy_spawned(enemy: Node)


# ============================================================================
# ENVIRONMENT SIGNALS
# ============================================================================

@warning_ignore("unused_signal") ## Emitted when entering a new area/zone
signal area_entered(area_name: String)

@warning_ignore("unused_signal") ## Emitted when leaving an area/zone
signal area_exited(area_name: String)

@warning_ignore("unused_signal") ## Emitted when a checkpoint is reached
signal checkpoint_reached(checkpoint_id: String)

@warning_ignore("unused_signal") ## Emitted when an object is destroyed in the environment
signal object_destroyed(object: Node)


# ============================================================================
# ACHIEVEMENT/PROGRESSION SIGNALS
# ============================================================================

@warning_ignore("unused_signal") ## Emitted when an achievement is unlocked
signal achievement_unlocked(achievement_id: String)

@warning_ignore("unused_signal") ## Emitted when a quest/objective is started
signal quest_started(quest_id: String)

@warning_ignore("unused_signal") ## Emitted when a quest/objective is updated
signal quest_updated(quest_id: String, progress: float)

@warning_ignore("unused_signal") ## Emitted when a quest/objective is completed
signal quest_completed(quest_id: String)


# ============================================================================
# SAVE/SETTINGS SIGNALS
# ============================================================================

@warning_ignore("unused_signal") ## Emitted when game is saved
signal game_saved

@warning_ignore("unused_signal") ## Emitted when game is loaded
signal game_loaded

@warning_ignore("unused_signal") ## Emitted when settings are changed
signal settings_changed(category: String, key: String, value: Variant)



## Emit a custom event with optional data
## Useful for game-specific events not covered by default signals
func emit_custom_event(event_name: String, data: Dictionary = {}) -> void:
	if not has_user_signal(event_name):
		add_user_signal(event_name)
	emit_signal(event_name, data)


## Check if a custom event exists
func has_custom_event(event_name: String) -> bool:
	return has_user_signal(event_name)


## Register a new custom event signal
func register_custom_event(event_name: String) -> void:
	if not has_user_signal(event_name):
		add_user_signal(event_name)
	else:
		push_warning("EventBus: Signal '%s' already exists" % event_name)
