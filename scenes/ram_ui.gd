extends Node2D


const DEFAULT_ANIMATION_TIME = 0.1

@onready var mem_lines: Array[PanelContainer] = [
	$PanelContainer/VBoxContainer/PanelContainer,
	$PanelContainer/VBoxContainer/PanelContainer2,
	$PanelContainer/VBoxContainer/PanelContainer3,
	$PanelContainer/VBoxContainer/PanelContainer4,
]

@export var animation_scale_factor := Vector2(1.1, 1.1)
@export var animation_time := DEFAULT_ANIMATION_TIME


func _ready() -> void:
	Signals.fun_explosion_happened.connect(_animate_shake)

	for line in mem_lines:
		line.pivot_offset = line.size / 2

	_animate_intro.call_deferred()


func _animate_intro() -> void:
	var displacement = Vector2(0, -50)
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

	for line in mem_lines:
		if random:
			displacement = Vector2(randf_range(-20, 20), randf_range(-20, 20))
		animate.call(line, displacement)


func clear_colors() -> void:
	for line in mem_lines:
		line.get_child(0).get_child(0).set("theme_override_colors/font_color", Color.WHITE)
		line.get_child(0).get_child(1).set("theme_override_colors/font_color", Color.WHITE)


func animate_mem_line_read(mem_address: int) -> void:
	mem_lines[mem_address].get_child(0).get_child(0).set("theme_override_colors/font_color", Color.YELLOW_GREEN)
	mem_lines[mem_address].get_child(0).get_child(1).set("theme_override_colors/font_color", Color.YELLOW_GREEN)
	var tween = create_tween()
	tween.tween_property(mem_lines[mem_address], "scale", animation_scale_factor, animation_time / 2)
	tween.tween_property(mem_lines[mem_address], "scale", Vector2.ONE, animation_time / 2)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func animate_mem_line_write(mem_address: int, data: int) -> void:
	mem_lines[mem_address].get_child(0).get_child(1).text = str(data)
	mem_lines[mem_address].get_child(0).get_child(0).set("theme_override_colors/font_color", Color.TOMATO)
	mem_lines[mem_address].get_child(0).get_child(1).set("theme_override_colors/font_color", Color.TOMATO)
	var tween = create_tween()
	tween.tween_property(mem_lines[mem_address], "scale", animation_scale_factor, animation_time / 2)
	tween.tween_property(mem_lines[mem_address], "scale", Vector2.ONE, animation_time / 2)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
