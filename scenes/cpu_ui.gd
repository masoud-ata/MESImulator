extends Node2D


const DEFAULT_ANIMATION_TIME = 0.1

@export var id: int

@export var animation_scale_factor := Vector2(1.1, 1.1)
@export var animation_time := DEFAULT_ANIMATION_TIME

@onready var read_a_0: Button = %ReadA0
@onready var read_a_1: Button = %ReadA1
@onready var read_a_2: Button = %ReadA2
@onready var read_a_3: Button = %ReadA3

@onready var write_a_0: Button = %WriteA0
@onready var write_a_1: Button = %WriteA1
@onready var write_a_2: Button = %WriteA2
@onready var write_a_3: Button = %WriteA3

@onready var all_buttons = [
	read_a_0, read_a_1, read_a_2, read_a_3,
	write_a_0, write_a_1, write_a_2, write_a_3,
]

@onready var cache_value = [
	$CPUCacheUI/PanelContainer/VBoxContainer/PanelContainer/HBoxContainer/Value,
	$CPUCacheUI/PanelContainer/VBoxContainer/PanelContainer2/HBoxContainer/Value,
]

@onready var cache_tag = [
	$CPUCacheUI/PanelContainer/VBoxContainer/PanelContainer/HBoxContainer/Address,
	$CPUCacheUI/PanelContainer/VBoxContainer/PanelContainer2/HBoxContainer/Address,
]

@onready var cache_state = [
	$CPUCacheUI/PanelContainer/VBoxContainer/PanelContainer/HBoxContainer/Status,
	$CPUCacheUI/PanelContainer/VBoxContainer/PanelContainer2/HBoxContainer/Status,
]

@onready var cache_line = [
	$CPUCacheUI/PanelContainer/VBoxContainer/PanelContainer,
	$CPUCacheUI/PanelContainer/VBoxContainer/PanelContainer2,
]


func _ready() -> void:
	Signals.animation_speed_factor_changed.connect(_adjust_animation_speed)

	read_a_0.pressed.connect(_on_read_a_0_pressed)
	read_a_1.pressed.connect(_on_read_a_1_pressed)
	read_a_2.pressed.connect(_on_read_a_2_pressed)
	read_a_3.pressed.connect(_on_read_a_3_pressed)
	write_a_0.pressed.connect(_on_write_a_0_pressed)
	write_a_1.pressed.connect(_on_write_a_1_pressed)
	write_a_2.pressed.connect(_on_write_a_2_pressed)
	write_a_3.pressed.connect(_on_write_a_3_pressed)

	for button in all_buttons:
		button.pivot_offset = button.size / 2

	for line in cache_line:
		line.pivot_offset = line.size / 2

	_init_contents()


func reset() -> void:
	for set_no in range(2):
		cache_value[set_no].text = str(0)
		cache_tag[set_no].text = ""
		cache_state[set_no].text = "I"


func _adjust_animation_speed(factor: float) -> void:
	if is_equal_approx(factor, 0.0):
		animation_time = DEFAULT_ANIMATION_TIME * factor
	else:
		animation_time = DEFAULT_ANIMATION_TIME


func _on_read_a_0_pressed() -> void:
	Signals.user_read_requested.emit(id, 0)
	_animate_button(read_a_0)


func _on_read_a_1_pressed() -> void:
	Signals.user_read_requested.emit(id, 1)
	_animate_button(read_a_1)


func _on_read_a_2_pressed() -> void:
	Signals.user_read_requested.emit(id, 2)
	_animate_button(read_a_2)


func _on_read_a_3_pressed() -> void:
	Signals.user_read_requested.emit(id, 3)
	_animate_button(read_a_3)


func _on_write_a_0_pressed() -> void:
	Signals.user_write_requested.emit(id, 0)
	_animate_button(write_a_0)


func _on_write_a_1_pressed() -> void:
	Signals.user_write_requested.emit(id, 1)
	_animate_button(write_a_1)


func _on_write_a_2_pressed() -> void:
	Signals.user_write_requested.emit(id, 2)
	_animate_button(write_a_2)


func _on_write_a_3_pressed() -> void:
	Signals.user_write_requested.emit(id, 3)
	_animate_button(write_a_3)


func _init_contents() -> void:
	for val in cache_value:
		val.text = "0"
	for state in cache_state:
		state.text = "I"


func _animate_button(button: Button) -> void:
	var tween = create_tween()
	tween.tween_property(button, "scale", animation_scale_factor, DEFAULT_ANIMATION_TIME / 2)
	tween.tween_property(button, "scale", Vector2.ONE, DEFAULT_ANIMATION_TIME / 2)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func update_cache_content(set_no: int, tag: int, value: int) -> void:
	cache_value[set_no].text = str(value)
	cache_tag[set_no].text = "a" + str(tag*2 + set_no)


func update_cache_state(set_no: int, tag: int, state: String) -> void:
	cache_tag[set_no].text = "a" + str(tag*2 + set_no)
	cache_state[set_no].text = state


func animate_cache_content(set_no: int) -> void:
	var tween = create_tween()
	tween.tween_property(cache_line[set_no], "scale", animation_scale_factor, DEFAULT_ANIMATION_TIME)
	tween.tween_property(cache_line[set_no], "scale", Vector2.ONE, DEFAULT_ANIMATION_TIME)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await tween.finished
	await get_tree().create_timer(animation_time).timeout
