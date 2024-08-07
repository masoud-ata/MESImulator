extends Node2D


const NUM_SPEED_STEPS := 10.0

@onready var speed_slider: HSlider = %SpeedSlider
@onready var fun_button: Button = %FunButton
@onready var back_button: Button = %BackButton
@onready var reset_button: Button = %ResetButton
@onready var background_check_button: CheckBox = %BackgroundCheckButton
@onready var bug_check_button: CheckBox = %BugCheckButton


func _ready() -> void:
	fun_button.pressed.connect(_on_fun_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	reset_button.pressed.connect(_on_reset_button_pressed)
	speed_slider.drag_ended.connect(_on_speed_slider_drag_ended)
	background_check_button.toggled.connect(_on_background_toggled)
	bug_check_button.toggled.connect(_on_bug_toggled)

	fun_button.pivot_offset = fun_button.size / 2
	back_button.pivot_offset = back_button.size / 2
	reset_button.pivot_offset = reset_button.size / 2
	speed_slider.min_value = -NUM_SPEED_STEPS / 2
	speed_slider.max_value = NUM_SPEED_STEPS / 2
	speed_slider.value = 0


func _on_speed_slider_drag_ended(_value_changed: bool) -> void:
	_on_speed_slider_update()


func _on_speed_slider_update() -> void:
	var speed_factor = speed_slider.value * -0.2 + 1.0
	Signals.animation_speed_factor_changed.emit(speed_factor)


func _on_fun_button_pressed() -> void:
	_animate_button(fun_button)
	Signals.user_fun_requested.emit()


func _on_reset_button_pressed() -> void:
	_animate_button(reset_button)
	Signals.user_reset_requested.emit()


func _on_back_button_pressed() -> void:
	_animate_button(back_button)
	Signals.user_back_requested.emit()


func _animate_button(button: Button) -> void:
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(button, "scale", Vector2.ONE, 0.1)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _on_background_toggled(toggled_on: bool) -> void:
	Signals.background_visibility_toggled.emit(toggled_on)


func _on_bug_toggled(toggled_on: bool) -> void:
	Signals.bug_toggled.emit(toggled_on)


func revert_settings() -> void:
	_on_speed_slider_update()
	_on_background_toggled(background_check_button.button_pressed)
	_on_bug_toggled(bug_check_button.button_pressed)
