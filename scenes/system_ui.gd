extends Node2D


@onready var buses: Node2D = $Buses

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
@onready var ram_data_in: CanvasGroup = $Buses/RamDataIn
@onready var ram_data_out: CanvasGroup = $Buses/RamDataOut

@onready var data_bus: CanvasGroup = $Buses/DataBus
@onready var address_bus: CanvasGroup = $Buses/AddressBus


func _ready() -> void:
	Signals.all_new_transaction_started.connect(all_new_transaction_started)
	Signals.cache_state_updated.connect(cache_state_updated)
	Signals.write_transaction_performed_in_cache.connect(write_transaction_performed_in_cache)
	Signals.read_transaction_performed_in_cache.connect(read_transaction_performed_in_cache)
	Signals.read_transaction_started_on_bus.connect(read_transaction_started_on_bus)
	Signals.snoop_transaction_started_on_bus.connect(snoop_transaction_started_on_bus)
	Signals.read_transaction_started_from_ram.connect(read_transaction_started_from_ram)
	Signals.read_transaction_started_from_other_cache.connect(read_transaction_started_from_other_cache)
	Signals.write_transaction_started_to_ram.connect(write_transaction_started_to_ram)
	_clear_bus_visuals()


func _clear_bus_visuals() -> void:
	for bus in buses.get_children():
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


func all_new_transaction_started() -> void:
	_clear_memory_visuals()
	_clear_bus_visuals()
	_clear_cache_visuals()


func write_transaction_performed_in_cache(cpu_id: int, set_no: int, tag: int, data: int) -> void:
	cpus[cpu_id].cache_value[set_no].set("theme_override_colors/font_color", Color.TOMATO)
	cpus[cpu_id].cache_tag[set_no].set("theme_override_colors/font_color", Color.TOMATO)
	cpus[cpu_id].cache_state[set_no].set("theme_override_colors/font_color", Color.TOMATO)
	cpus[cpu_id].update_cache_content(set_no, tag, data)
	await cpus[cpu_id].animate_cache_content(set_no)
	Signals.transaction_finished.emit()


func read_transaction_performed_in_cache(cpu_id: int, set_no: int, tag: int, state: String) -> void:
	cpus[cpu_id].cache_value[set_no].set("theme_override_colors/font_color", Color.YELLOW_GREEN)
	cpus[cpu_id].cache_tag[set_no].set("theme_override_colors/font_color", Color.YELLOW_GREEN)
	cpus[cpu_id].cache_state[set_no].set("theme_override_colors/font_color", Color.YELLOW_GREEN)
	cpus[cpu_id].update_cache_state(set_no, tag, state)
	await cpus[cpu_id].animate_cache_content(set_no)
	Signals.transaction_finished.emit()


func read_transaction_started_on_bus(cpu_id: int, mem_address: int) -> void:
	var tween = create_tween()
	tween.tween_property(cache_address_out_buses[cpu_id], "self_modulate", Color.SKY_BLUE, .5)
	tween.tween_property(address_bus, "self_modulate", Color.SKY_BLUE, .5)
	tween.tween_property(ram_address_in_bus, "self_modulate", Color.SKY_BLUE, .5)
	var other_address_in_buses = cache_address_in_buses.duplicate()
	other_address_in_buses.remove_at(cpu_id)
	for b in other_address_in_buses:
		tween.parallel().tween_property(b, "self_modulate", Color.SKY_BLUE, .5)
	await tween.finished
	Signals.transaction_finished.emit()


func snoop_transaction_started_on_bus(cpu_id: int, mem_address: int) -> void:
	var tween = create_tween()
	tween.tween_property(cache_address_out_buses[cpu_id], "self_modulate", Color.SKY_BLUE, .5)
	tween.tween_property(address_bus, "self_modulate", Color.SKY_BLUE, .5)
	#tween.tween_property(ram_address_in_bus, "self_modulate", Color.SKY_BLUE, .5)
	var other_address_in_buses = cache_address_in_buses.duplicate()
	other_address_in_buses.remove_at(cpu_id)
	for b in other_address_in_buses:
		tween.parallel().tween_property(b, "self_modulate", Color.SKY_BLUE, .5)
	await tween.finished
	Signals.transaction_finished.emit()


func write_transaction_started_to_ram(cpu_id: int, mem_address: int, data: int) -> void:
	var tween = create_tween()
	tween.tween_property(cache_address_out_buses[cpu_id], "self_modulate", Color.SKY_BLUE, .5)
	tween.tween_property(address_bus, "self_modulate", Color.SKY_BLUE, .5)
	tween.tween_property(ram_address_in_bus, "self_modulate", Color.SKY_BLUE, .5)
	var tween_data = create_tween()
	tween_data.tween_property(cache_data_out_buses[cpu_id], "self_modulate", Color.TOMATO, .5)
	tween_data.tween_property(data_bus, "self_modulate", Color.TOMATO, .5)
	tween_data.tween_property(ram_data_in, "self_modulate", Color.TOMATO, .5)
	await tween.finished
	ram_ui.animate_mem_line_write(mem_address, data)
	await get_tree().create_timer(.5).timeout
	Signals.transaction_finished.emit()


func read_transaction_started_from_ram(cpu_id: int, mem_address: int) -> void:
	var tween = create_tween()
	ram_ui.animate_mem_line_read(mem_address)
	tween.tween_property(ram_data_out, "self_modulate", Color.TOMATO, .5)
	tween.tween_property(data_bus, "self_modulate", Color.TOMATO, .5)
	tween.tween_property(cache_data_in_buses[cpu_id], "self_modulate", Color.TOMATO, .5)
	await tween.finished
	Signals.transaction_finished.emit()


func read_transaction_started_from_other_cache(other_cpu_id: int, cpu_id: int, mem_address:int, data: int) -> void:
	var tween = create_tween()
	tween.tween_property(cache_data_out_buses[other_cpu_id], "self_modulate", Color.TOMATO, .5)
	tween.tween_property(data_bus, "self_modulate", Color.TOMATO, .5)
	tween.tween_property(cache_data_in_buses[cpu_id], "self_modulate", Color.TOMATO, .5)
	tween.parallel().tween_property(ram_data_in, "self_modulate", Color.TOMATO, .5)
	await tween.finished
	ram_ui.animate_mem_line_write(mem_address, data)
	Signals.transaction_finished.emit()


func cache_state_updated(cpu_id: int, set_no: int, tag: int, state: String) -> void:
	cpus[cpu_id].update_cache_state(set_no, tag, state)
	await cpus[cpu_id].animate_cache_content(set_no)
