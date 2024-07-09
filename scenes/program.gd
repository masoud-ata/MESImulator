extends Node2D


const SystemScene = preload("res://scenes/system.tscn")
const SystemUIScene = preload("res://scenes/system_ui.tscn")
const Fun = preload("res://scenes/fun/fun.tscn")


func _ready() -> void:
	Signals.user_reset_requested.connect(_reset)


func _reset():
	_free_node("System")
	_free_node("SystemUI")
	_free_node("Fun")

	add_child(SystemScene.instantiate())
	add_child(SystemUIScene.instantiate())
	add_child(Fun.instantiate())

	get_node("AlwaysOnTop/SettingsUI").revert_settings()


func _free_node(node_name: String) -> void:
	var node = get_node(node_name)
	remove_child(node)
	node.queue_free()
