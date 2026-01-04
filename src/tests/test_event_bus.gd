extends GdUnitTestSuite
## Unit tests for EventBus

var event_bus: Node

func before_test():
    event_bus = load("res://src/core/managers/event_bus.gd").new()
    add_child(event_bus)

func _clear_signal_monitors() -> void:
    var context := GdUnitThreadManager.get_current_context()
    if context:
        var collector := context.get_signal_collector()
        if collector:
            collector.clear()


func after_test():
    _clear_signal_monitors()
    if is_instance_valid(event_bus):
        event_bus.queue_free()
        await get_tree().process_frame
    event_bus = null

func test_event_bus_has_game_state_signals():
    assert_that(event_bus.has_signal("game_started")).is_true()
    assert_that(event_bus.has_signal("game_paused")).is_true()
    assert_that(event_bus.has_signal("game_resumed")).is_true()
    assert_that(event_bus.has_signal("game_ended")).is_true()

func test_event_bus_has_player_signals():
    assert_that(event_bus.has_signal("player_damaged")).is_true()
    assert_that(event_bus.has_signal("player_healed")).is_true()
    assert_that(event_bus.has_signal("player_died")).is_true()
    assert_that(event_bus.has_signal("player_respawned")).is_true()

func test_event_bus_has_ui_signals():
    assert_that(event_bus.has_signal("ui_screen_opened")).is_true()
    assert_that(event_bus.has_signal("ui_screen_closed")).is_true()
    assert_that(event_bus.has_signal("ui_button_pressed")).is_true()

func test_event_bus_has_combat_signals():
    assert_that(event_bus.has_signal("player_attacked")).is_true()
    assert_that(event_bus.has_signal("enemy_damaged")).is_true()
    assert_that(event_bus.has_signal("enemy_died")).is_true()

func test_event_bus_has_environment_signals():
    assert_that(event_bus.has_signal("area_entered")).is_true()
    assert_that(event_bus.has_signal("area_exited")).is_true()
    assert_that(event_bus.has_signal("checkpoint_reached")).is_true()

func test_game_started_signal():
    var monitor := monitor_signals(event_bus)
    event_bus.game_started.emit()
    assert_signal(monitor).is_emitted("game_started")

func test_player_damaged_signal():
    var monitor := monitor_signals(event_bus)
    event_bus.player_damaged.emit(10.0, null)
    assert_signal(monitor).is_emitted("player_damaged", [10.0, null])

func test_score_changed_signal():
    var monitor := monitor_signals(event_bus)
    event_bus.score_changed.emit(100, 10)
    assert_signal(monitor).is_emitted("score_changed", [100, 10])

func test_custom_event_registration():
    event_bus.register_custom_event("test_event")
    assert_bool(event_bus.has_custom_event("test_event")).is_true()

func test_custom_event_emission():
    event_bus.register_custom_event("test_event")
    var monitor := monitor_signals(event_bus)
    event_bus.emit_custom_event("test_event", {"key":"value"})
    assert_signal(monitor).is_emitted("test_event", [{"key":"value"}])

func test_custom_event_auto_registration():
    assert_bool(event_bus.has_custom_event("auto_event")).is_false()
    event_bus.emit_custom_event("auto_event", {})
    assert_bool(event_bus.has_custom_event("auto_event")).is_true()

func test_custom_event_duplicate_registration():
    event_bus.register_custom_event("duplicate")
    event_bus.register_custom_event("duplicate")

func test_signal_connection():
    var received := {"value": false}
    event_bus.game_started.connect(func(): received.value = true)
    event_bus.game_started.emit()
    assert_bool(received.value).is_true()

func test_signal_with_parameters():
    var amount := {"value": 0.0}
    event_bus.player_damaged.connect(func(v, _source): amount.value = v)
    event_bus.player_damaged.emit(25.5, null)
    assert_float(amount.value).is_equal(25.5)

func test_multiple_signal_handlers():
    var a := {"value": 0}
    var b := {"value": 0}
    event_bus.game_started.connect(func(): a.value += 1)
    event_bus.game_started.connect(func(): b.value += 1)
    event_bus.game_started.emit()
    assert_int(a.value).is_equal(1)
    assert_int(b.value).is_equal(1)

func test_settings_changed_signal():
    var section := {"value": ""}
    var key := {"value": ""}
    var value := {"value": null}
    event_bus.settings_changed.connect(func(s,k,v): section.value=s; key.value=k; value.value=v)
    event_bus.settings_changed.emit("audio", "master_volume", 0.8)
    assert_str(section.value).is_equal("audio")
    assert_str(key.value).is_equal("master_volume")
    assert_float(value.value).is_equal(0.8)

func test_game_saved_signal():
    var monitor := monitor_signals(event_bus)
    event_bus.game_saved.emit()
    assert_signal(monitor).is_emitted("game_saved")

func test_game_loaded_signal():
    var monitor := monitor_signals(event_bus)
    event_bus.game_loaded.emit()
    assert_signal(monitor).is_emitted("game_loaded")

func test_item_collected_signal():
    var t := {"value": ""}
    var d := {"value": {}}
    event_bus.item_collected.connect(func(type,data): t.value=type; d.value=data)
    event_bus.item_collected.emit("coin", {"value":10})
    assert_str(t.value).is_equal("coin")
    assert_int(d.value.get("value",0)).is_equal(10)

func test_enemy_died_signal():
    var received := {"value": null}
    var test_node := Node.new()
    event_bus.enemy_died.connect(func(e): received.value = e)
    event_bus.enemy_died.emit(test_node)
    assert_that(received.value).is_equal(test_node)
    test_node.free()

func test_level_completed_signal():
    var monitor := monitor_signals(event_bus)
    event_bus.level_completed.emit()
    assert_signal(monitor).is_emitted("level_completed")
