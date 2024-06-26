extends Node2D


var system_scene = preload("res://scenes/system.tscn")
var system_ui_scene = preload("res://scenes/system_ui.tscn")


func _ready() -> void:
	Signals.user_reset_requested.connect(_reset)


func _reset():
	var system_node = get_node("System")
	remove_child(system_node)
	system_node.queue_free()
	var system_ui_node = get_node("SystemUI")
	remove_child(system_ui_node)
	system_ui_node.queue_free()

	add_child(system_scene.instantiate())
	add_child(system_ui_scene.instantiate())
