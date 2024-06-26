extends Node2D


@onready var mem_lines: Array[PanelContainer] = [
	$PanelContainer/VBoxContainer/PanelContainer,
	$PanelContainer/VBoxContainer/PanelContainer2,
	$PanelContainer/VBoxContainer/PanelContainer3,
	$PanelContainer/VBoxContainer/PanelContainer4,
]


func _ready() -> void:
	for line in mem_lines:
		line.pivot_offset = line.size / 2


func clear_colors() -> void:
	for line in mem_lines:
		line.get_child(0).get_child(0).set("theme_override_colors/font_color", Color.WHITE)
		line.get_child(0).get_child(1).set("theme_override_colors/font_color", Color.WHITE)


func animate_mem_line_read(mem_address: int) -> void:
	mem_lines[mem_address].get_child(0).get_child(0).set("theme_override_colors/font_color", Color.YELLOW_GREEN)
	mem_lines[mem_address].get_child(0).get_child(1).set("theme_override_colors/font_color", Color.YELLOW_GREEN)
	var tween = create_tween()
	tween.tween_property(mem_lines[mem_address], "scale", Vector2(1.05, 1.05), .05)
	tween.tween_property(mem_lines[mem_address], "scale", Vector2.ONE, .05)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func animate_mem_line_write(mem_address: int, data: int) -> void:
	clear_colors()
	mem_lines[mem_address].get_child(0).get_child(1).text = str(data)
	mem_lines[mem_address].get_child(0).get_child(0).set("theme_override_colors/font_color", Color.TOMATO)
	mem_lines[mem_address].get_child(0).get_child(1).set("theme_override_colors/font_color", Color.TOMATO)
	var tween = create_tween()
	tween.tween_property(mem_lines[mem_address], "scale", Vector2(1.05, 1.05), .05)
	tween.tween_property(mem_lines[mem_address], "scale", Vector2.ONE, .05)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
