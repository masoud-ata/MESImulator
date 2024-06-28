extends Node2D


const DEFAULT_ANIMATION_TIME = 0.5

@export var animation_time := DEFAULT_ANIMATION_TIME

@onready var buses_node: Node2D = $Buses

@onready var cpus: Array[Node2D] = [$CPU0, $CPU1, $CPU2]

@onready var ram_ui: Node2D = $RamUI

@onready var cache_data_in_buses = [
	$Buses/Cache0DataIn,
	$Buses/Cache1DataIn,
	$Buses/Cache2DataIn,
]

@onready var cache_data_out_buses = [
	$Buses/Cache0DataOut,
	$Buses/Cache1DataOut,
	$Buses/Cache2DataOut,
]

@onready var cache_address_in_buses = [
	$Buses/Cache0AddressIn,
	$Buses/Cache1AddressIn,
	$Buses/Cache2AddressIn,
]

@onready var cache_address_out_buses = [
	$Buses/Cache0AddressOut,
	$Buses/Cache1AddressOut,
	$Buses/Cache2AddressOut,
]

@onready var ram_address_in_bus: CanvasGroup = $Buses/RamAddressIn
@onready var ram_address_out_bus: CanvasGroup = $Buses/RamAddressOut
@onready var ram_data_in_bus: CanvasGroup = $Buses/RamDataIn
@onready var ram_data_out_bus: CanvasGroup = $Buses/RamDataOut

@onready var data_bus: CanvasGroup = $Buses/DataBus
@onready var address_bus: CanvasGroup = $Buses/AddressBus

@onready var background_plain: ColorRect = $BackgroundPlain
@onready var background_space_1: Sprite2D = $BackgroundSpace1
@onready var background_space_2: Sprite2D = $BackgroundSpace2
@onready var falling_star: AnimatedSprite2D = $FallingStar


func _ready() -> void:
	Signals.animation_speed_factor_changed.connect(_adjust_animation_speed)
	Signals.background_visibility_toggled.connect(_background_visibility_toggled)
	Signals.all_new_transaction_started.connect(_clear_visuals)
	Signals.cache_state_updated.connect(_cache_state_updated)
	Signals.write_transaction_performed_in_cache.connect(_write_transaction_performed_in_cache)
	Signals.read_transaction_performed_in_cache.connect(_read_transaction_performed_in_cache)
	Signals.address_placed_on_buses.connect(_address_placed_on_buses)
	Signals.read_transaction_started_from_ram.connect(_read_transaction_started_from_ram)
	Signals.read_transaction_started_from_other_cache.connect(_read_transaction_started_from_other_cache)
	Signals.write_transaction_started_to_ram.connect(_write_transaction_started_to_ram)

	_clear_bus_visuals()

	var show_me = randi() & 1
	background_space_1.visible = show_me
	background_space_2.visible = not show_me


func _adjust_animation_speed(factor: float) -> void:
	animation_time = DEFAULT_ANIMATION_TIME * factor


func _background_visibility_toggled(toggled_on: bool) -> void:
	if toggled_on:
		background_plain.visible = false
		var show_me = randi() & 1
		background_space_1.visible = show_me
		background_space_2.visible = not show_me
		falling_star.visible = true
	else:
		background_plain.visible = true
		background_space_1.visible = false
		background_space_2.visible = false
		falling_star.visible = false


func _clear_bus_visuals() -> void:
	for bus in buses_node.get_children():
		bus.self_modulate = Color(1, 1, 1, 0)


func _clear_cache_visuals() -> void:
	for cpu in cpus:
		for c in cpu.cache_value:
			c.set("theme_override_colors/font_color", Color.WHITE)
		for c in cpu.cache_tag:
			c.set("theme_override_colors/font_color", Color.WHITE)
		for c in cpu.cache_state:
			c.set("theme_override_colors/font_color", Color.WHITE)


func _clear_memory_visuals() -> void:
	ram_ui.clear_colors()


func _clear_visuals() -> void:
	_clear_memory_visuals()
	_clear_bus_visuals()
	_clear_cache_visuals()


func _write_transaction_performed_in_cache(cpu_id: int, set_no: int, tag: int, data: int) -> void:
	cpus[cpu_id].cache_value[set_no].set("theme_override_colors/font_color", Color.TOMATO)
	cpus[cpu_id].cache_tag[set_no].set("theme_override_colors/font_color", Color.TOMATO)
	cpus[cpu_id].cache_state[set_no].set("theme_override_colors/font_color", Color.TOMATO)
	cpus[cpu_id].update_cache_content(set_no, tag, data)
	cpus[cpu_id].animate_cache_content(set_no)


func _read_transaction_performed_in_cache(cpu_id: int, set_no: int, tag: int, state: String) -> void:
	cpus[cpu_id].cache_value[set_no].set("theme_override_colors/font_color", Color.YELLOW_GREEN)
	cpus[cpu_id].cache_tag[set_no].set("theme_override_colors/font_color", Color.YELLOW_GREEN)
	cpus[cpu_id].cache_state[set_no].set("theme_override_colors/font_color", Color.YELLOW_GREEN)
	cpus[cpu_id].update_cache_state(set_no, tag, state)
	cpus[cpu_id].animate_cache_content(set_no)


func _address_placed_on_buses(cpu_id: int, _mem_address: int) -> void:
	var tween = create_tween()
	tween.tween_property(cache_address_out_buses[cpu_id], "self_modulate", Color.SKY_BLUE, animation_time)
	tween.tween_property(address_bus, "self_modulate", Color.SKY_BLUE, animation_time)
	tween.tween_property(ram_address_in_bus, "self_modulate", Color.SKY_BLUE, animation_time)
	var other_address_in_buses = cache_address_in_buses.duplicate()
	other_address_in_buses.remove_at(cpu_id)
	for b in other_address_in_buses:
		tween.parallel().tween_property(b, "self_modulate", Color.SKY_BLUE, animation_time)
	await tween.finished
	Signals.transaction_finished.emit()


func _write_transaction_started_to_ram(cpu_id: int, mem_address: int, data: int) -> void:
	var tween = create_tween()
	tween.tween_property(cache_address_out_buses[cpu_id], "self_modulate", Color.SKY_BLUE, animation_time)
	tween.tween_property(address_bus, "self_modulate", Color.SKY_BLUE, animation_time)
	tween.tween_property(ram_address_in_bus, "self_modulate", Color.SKY_BLUE, animation_time)
	var tween_data = create_tween()
	tween_data.tween_property(cache_data_out_buses[cpu_id], "self_modulate", Color.TOMATO, animation_time)
	tween_data.tween_property(data_bus, "self_modulate", Color.TOMATO, animation_time)
	tween_data.tween_property(ram_data_in_bus, "self_modulate", Color.TOMATO, animation_time)
	await tween.finished
	ram_ui.animate_mem_line_write(mem_address, data)
	await get_tree().create_timer(animation_time).timeout
	Signals.transaction_finished.emit()


func _read_transaction_started_from_ram(cpu_id: int, mem_address: int) -> void:
	var tween = create_tween()
	ram_ui.animate_mem_line_read(mem_address)
	tween.tween_property(ram_data_out_bus, "self_modulate", Color.TOMATO, animation_time)
	tween.tween_property(data_bus, "self_modulate", Color.TOMATO, animation_time)
	tween.tween_property(cache_data_in_buses[cpu_id], "self_modulate", Color.TOMATO, animation_time)
	await tween.finished
	Signals.transaction_finished.emit()


func _read_transaction_started_from_other_cache(other_cpu_id: int, cpu_id: int, mem_address:int, data: int) -> void:
	var tween = create_tween()
	tween.tween_property(cache_data_out_buses[other_cpu_id], "self_modulate", Color.TOMATO, animation_time)
	tween.tween_property(data_bus, "self_modulate", Color.TOMATO, animation_time)
	tween.tween_property(cache_data_in_buses[cpu_id], "self_modulate", Color.TOMATO, animation_time)
	tween.parallel().tween_property(ram_data_in_bus, "self_modulate", Color.TOMATO, animation_time)
	await tween.finished
	ram_ui.animate_mem_line_write(mem_address, data)
	Signals.transaction_finished.emit()


func _cache_state_updated(cpu_id: int, set_no: int, tag: int, state: String) -> void:
	cpus[cpu_id].update_cache_state(set_no, tag, state)
	await cpus[cpu_id].animate_cache_content(set_no)


func _on_star_timer_timeout() -> void:
	falling_star.play("default")
