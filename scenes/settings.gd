extends Node2D


const NUM_SPEED_STEPS = 10.0

@onready var speed_slider: HSlider = %SpeedSlider
@onready var reset_button: Button = %ResetButton


func _ready() -> void:
	reset_button.pressed.connect(_on_reset_button_pressed)
	speed_slider.drag_ended.connect(_on_speed_slider_drag_ended)

	reset_button.pivot_offset = reset_button.size / 2
	speed_slider.min_value = -NUM_SPEED_STEPS / 2
	speed_slider.max_value = NUM_SPEED_STEPS / 2
	speed_slider.value = 0


func _on_speed_slider_drag_ended(_value_changed: bool) -> void:
	var speed_factor = speed_slider.value * -0.2 + 1.0
	Signals.animation_speed_factor_changed.emit(speed_factor)


func _on_reset_button_pressed() -> void:
	_animate_button(reset_button)
	Signals.user_reset_requested.emit()


func _animate_button(button: Button) -> void:
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(button, "scale", Vector2.ONE, 0.1)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
