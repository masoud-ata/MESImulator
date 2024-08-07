extends Node2D


const DEFAULT_ANIMATION_TIME = 0.1


@export var id: int

@export var animation_scale_factor := Vector2(1.1, 1.1)
@export var animation_time := DEFAULT_ANIMATION_TIME


var modified_lines_in_this_transaction: Array[int] = []
var modified_lines_in_all_transactions := []

var all_transactions_labels: Array[String] = []
var transaction_label_init_position : Vector2


@onready var transaction_label: Label = $TransactionLabel

@onready var read_a_0: Button = %ReadA0
@onready var read_a_1: Button = %ReadA1
@onready var read_a_2: Button = %ReadA2
@onready var read_a_3: Button = %ReadA3

@onready var write_a_0: Button = %WriteA0
@onready var write_a_1: Button = %WriteA1
@onready var write_a_2: Button = %WriteA2
@onready var write_a_3: Button = %WriteA3

@onready var all_buttons: Array[Button] = [
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

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer


func _ready() -> void:
	Signals.fun_explosion_happened.connect(_animate_shake)
	Signals.fun_huge_explosion_happened.connect(_animate_destruction)
	Signals.animation_speed_factor_changed.connect(_adjust_animation_speed)
	Signals.cpu_read_or_write_handled.connect(_cpu_read_or_write_handled)
	Signals.all_new_transaction_started.connect(_all_new_transaction_started)

	read_a_0.pressed.connect(_send_read_request.bind(read_a_0, 0))
	read_a_1.pressed.connect(_send_read_request.bind(read_a_1, 1))
	read_a_2.pressed.connect(_send_read_request.bind(read_a_2, 2))
	read_a_3.pressed.connect(_send_read_request.bind(read_a_3, 3))
	write_a_0.pressed.connect(_send_write_request.bind(write_a_0, 0))
	write_a_1.pressed.connect(_send_write_request.bind(write_a_1, 1))
	write_a_2.pressed.connect(_send_write_request.bind(write_a_2, 2))
	write_a_3.pressed.connect(_send_write_request.bind(write_a_3, 3))

	for button in all_buttons:
		button.pivot_offset = button.size / 2

	for line in cache_line:
		line.pivot_offset = line.size / 2

	_init_contents()

	_animate_intro.call_deferred()

	transaction_label_init_position = transaction_label.global_position


func _animate_intro() -> void:
	var displacement = Vector2(0, -100)
	_animate_all(displacement, false)


func _animate_shake() -> void:
	_animate_all(Vector2.ZERO, true)


func _animate_all(displacement: Vector2, random: bool) -> void:
	var animate = func(ui, offset):
		var start_position = ui.global_position + offset
		var end_position = ui.global_position
		var tween = create_tween()
		tween.tween_property(ui, "global_position", start_position, 0.01)
		tween.tween_property(ui, "global_position", end_position, randf_range(0.2, 0.75))\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)

	for button in all_buttons:
		if random:
			displacement = Vector2(randf_range(-20, 20), randf_range(-20, 20))
		animate.call(button, displacement)
	for line in cache_line:
		if random:
			displacement = Vector2(randf_range(-20, 20), randf_range(-20, 20))
		animate.call(line, displacement)


func _animate_destruction() -> void:
	var fall = func(ui):
		var start_position = ui.global_position
		var top_offset = Vector2(randf_range(-50, 50), randf_range(-30, -70))
		var peak_position = start_position + top_offset
		var end_position = peak_position + Vector2(top_offset.x * 2, 400)

		var tween = create_tween()
		tween.tween_property(ui, "global_position", peak_position, randf_range(.2, 0.3))\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(ui, "global_position", end_position, randf_range(1.0, 1.5))\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
		tween.tween_property(ui, "global_position", start_position, 0.01)
		tween.tween_property(ui, "scale", Vector2(1.3, 1.3), 0.1)
		tween.tween_property(ui, "scale", Vector2(1.0, 1.0), 0.1)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	for button in all_buttons:
		fall.call(button)
	for line in cache_line:
		fall.call(line)


func _send_read_request(button: Button, address: int):
	Signals.user_read_requested.emit(id, address)
	_animate_button(button)
	audio_stream_player.play()


func _send_write_request(button: Button, address: int):
	Signals.user_write_requested.emit(id, address)
	_animate_button(button)
	audio_stream_player.play()


func _init_contents() -> void:
	for val in cache_value:
		val.text = "0"
	for state in cache_state:
		state.text = "I"
	for i in cache_tag.size():
		cache_tag[i].text = "a" + str(i)


func _adjust_animation_speed(factor: float) -> void:
	if is_equal_approx(factor, 0.0):
		animation_time = DEFAULT_ANIMATION_TIME * factor
	else:
		animation_time = DEFAULT_ANIMATION_TIME


func _animate_button(button: Button) -> void:
	const DEFAULT_ANIMATION_HALF_TIME = DEFAULT_ANIMATION_TIME / 2
	var tween = create_tween()
	tween.tween_property(button, "scale", animation_scale_factor, DEFAULT_ANIMATION_HALF_TIME)
	tween.tween_property(button, "scale", Vector2.ONE, DEFAULT_ANIMATION_HALF_TIME)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)


func update_cache_content(set_no: int, tag: int, value: int) -> void:
	modified_lines_in_this_transaction.append(set_no)

	cache_value[set_no].text = str(value)
	cache_tag[set_no].text = "a" + str(tag*2 + set_no)


func update_cache_state(set_no: int, tag: int, state: String) -> void:
	modified_lines_in_this_transaction.append(set_no)

	cache_tag[set_no].text = "a" + str(tag*2 + set_no)
	cache_state[set_no].text = state


func set_cache_content(set_no: int, tag: int, value: int, state: String) -> void:
	cache_value[set_no].text = str(value)
	cache_tag[set_no].text = "a" + str(tag*2 + set_no)
	cache_state[set_no].text = state


func animate_cache_content(set_no: int) -> void:
	var tween = create_tween()
	tween.tween_property(cache_line[set_no], "scale", animation_scale_factor, DEFAULT_ANIMATION_TIME)
	tween.tween_property(cache_line[set_no], "scale", Vector2.ONE, DEFAULT_ANIMATION_TIME)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)


func _cpu_read_or_write_handled() -> void:
	modified_lines_in_all_transactions.append(modified_lines_in_this_transaction.duplicate())
	modified_lines_in_this_transaction.clear()


func animate_previously_modified_lines() -> void:
	var modified_lines = modified_lines_in_all_transactions.pop_back()
	for line in modified_lines:
		animate_cache_content(line)


func animate_previous_transaction_label() -> void:
	all_transactions_labels.pop_back()
	var label = "" if all_transactions_labels.is_empty() else all_transactions_labels[-1]
	transaction_label.global_position = transaction_label_init_position
	transaction_label.show()
	transaction_label.text = label
	var tween = create_tween()
	tween.tween_property(transaction_label, "global_position:y", transaction_label_init_position.y - 7, .1)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)


func _all_new_transaction_started(cpu_id: int, memory_address: int, type: String) -> void:
	transaction_label.global_position = transaction_label_init_position
	if cpu_id == id:
		transaction_label.show()
		transaction_label.text = type + " " + "a" + str(memory_address)
		var tween = create_tween()
		tween.tween_property(transaction_label, "global_position:y", transaction_label_init_position.y - 7, .1)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)

		all_transactions_labels.append(transaction_label.text)
	else:
		transaction_label.hide()
		all_transactions_labels.append("")


