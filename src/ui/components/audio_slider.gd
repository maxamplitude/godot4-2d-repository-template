extends HBoxContainer
class_name AudioSlider
## Reusable audio slider component for controlling bus volume

@export var bus_name: String = "Master":
	set(value):
		bus_name = value
		_update_label()
		_load_volume()

@onready var label: Label = %Label
@onready var slider: HSlider = %Slider
@onready var value_label: Label = %ValueLabel


func _ready() -> void:
	# Set up slider
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value_changed.connect(_on_slider_value_changed)
	
	_update_label()
	_load_volume()


func _update_label() -> void:
	if label:
		label.text = bus_name + ":"


func _load_volume() -> void:
	if not AudioManager or not slider:
		return
	
	var volume = AudioManager.get_bus_volume(bus_name)
	slider.value = volume
	_update_value_label(volume)


func _on_slider_value_changed(value: float) -> void:
	AudioManager.set_bus_volume(bus_name, value)
	_update_value_label(value)
	
	# Play a quick sound when adjusting SFX volume
	if bus_name == "SFX":
		if ResourceLoader.exists(Constants.SFX_UI_CLICK):
			AudioManager.play_sfx(preload(Constants.SFX_UI_CLICK))


func _update_value_label(value: float) -> void:
	if value_label:
		value_label.text = str(int(value * 100)) + "%"