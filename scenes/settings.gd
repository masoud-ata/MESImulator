extends Node2D


const NUM_SPEED_STEPS = 10

@onready var speed_slider: HSlider = %SpeedSlider


func _ready() -> void:
	speed_slider.drag_ended.connect(_on_speed_slider_drag_ended)
	speed_slider.min_value = -NUM_SPEED_STEPS / 2
	speed_slider.max_value = NUM_SPEED_STEPS / 2
	speed_slider.value = 0


func _on_speed_slider_drag_ended(value_changed: bool) -> void:
	var speed_factor = speed_slider.value * 0.2 + 1.0
	Signals.animation_speed_factor_changed.emit(speed_factor)
	print(speed_factor)
