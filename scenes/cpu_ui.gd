extends Node2D


@export var id: int


@onready var read_a_0: Button = %ReadA0
@onready var read_a_1: Button = %ReadA1
@onready var read_a_2: Button = %ReadA2
@onready var read_a_3: Button = %ReadA3

@onready var write_a_0: Button = %WriteA0
@onready var write_a_1: Button = %WriteA1
@onready var write_a_2: Button = %WriteA2
@onready var write_a_3: Button = %WriteA3

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
	read_a_0.pressed.connect(_on_read_a_0_pressed)
	read_a_1.pressed.connect(_on_read_a_1_pressed)
	read_a_2.pressed.connect(_on_read_a_2_pressed)
	read_a_3.pressed.connect(_on_read_a_3_pressed)
	write_a_0.pressed.connect(_on_write_a_0_pressed)
	write_a_1.pressed.connect(_on_write_a_1_pressed)
	write_a_2.pressed.connect(_on_write_a_2_pressed)
	write_a_3.pressed.connect(_on_write_a_3_pressed)

	read_a_0.pivot_offset = read_a_0.size / 2
	read_a_1.pivot_offset = read_a_1.size / 2
	read_a_2.pivot_offset = read_a_2.size / 2
	read_a_3.pivot_offset = read_a_3.size / 2

	for line in cache_line:
		line.pivot_offset = line.size / 2

	_init_contents()


func _on_read_a_0_pressed() -> void:
	Signals.read_requested.emit(id, 0)
	_animate_button(read_a_0)


func _on_read_a_1_pressed() -> void:
	Signals.read_requested.emit(id, 1)
	_animate_button(read_a_1)


func _on_read_a_2_pressed() -> void:
	Signals.read_requested.emit(id, 2)
	_animate_button(read_a_2)


func _on_read_a_3_pressed() -> void:
	Signals.read_requested.emit(id, 3)
	_animate_button(read_a_3)


func _on_write_a_0_pressed() -> void:
	Signals.write_requested.emit(id, 0)


func _on_write_a_1_pressed() -> void:
	Signals.write_requested.emit(id, 1)


func _on_write_a_2_pressed() -> void:
	Signals.write_requested.emit(id, 2)


func _on_write_a_3_pressed() -> void:
	Signals.write_requested.emit(id, 3)


func _init_contents() -> void:
	for val in cache_value:
		val.text = "0"
	for state in cache_state:
		state.text = "I"


func update_cache_content(set_no: int, tag: int, value: int) -> void:
	cache_value[set_no].text = str(value)
	cache_tag[set_no].text = "a" + str(tag*2 + set_no)


func update_cache_state(set_no: int, tag: int, state: String) -> void:
	cache_tag[set_no].text = "a" + str(tag*2 + set_no)
	cache_state[set_no].text = state


func _animate_button(button: Button) -> void:
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), .05)
	tween.tween_property(button, "scale", Vector2.ONE, .05)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func animate_cache_content(set_no: int) -> void:
	var tween = create_tween()
	tween.tween_property(cache_line[set_no], "scale", Vector2(1.1, 1.1), .1)
	tween.tween_property(cache_line[set_no], "scale", Vector2.ONE, .1)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await tween.finished
	await get_tree().create_timer(.1).timeout
