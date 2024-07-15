extends Node


enum MesiStates { I, E, S, M }


class Cache:
	var tag: Array[int] = [0, 0]
	var data: Array[int] = [0, 0]
	var status: Array[MesiStates] = [MesiStates.I, MesiStates.I]


var caches := {
	0: Cache.new(),
	1: Cache.new(),
	2: Cache.new()
}

var ram: Array[int] = [0, 0, 0, 0]

var archive_caches := []
var archive_ram := []

var _protocal_is_bugged := false


@onready var cache_write_audio: AudioStreamPlayer = $CacheWriteAudio


func _ready() -> void:
	Signals.cpu_back_requested.connect(_cpu_go_back_in_time)
	Signals.cpu_read_issued.connect(_handle_read)
	Signals.cpu_write_issued.connect(_handle_write)
	Signals.bug_toggled.connect(func(is_bugged: bool): _protocal_is_bugged = is_bugged)


func _deep_caches_copy(to: Dictionary, from: Dictionary):
	for i in 3:
		to[i].tag = from[i].tag.duplicate()
		to[i].data = from[i].data.duplicate()
		to[i].status = from[i].status.duplicate()


func _archive_caches_copy() -> void:
	var copy_caches := {
		0: Cache.new(),
		1: Cache.new(),
		2: Cache.new()
	}
	_deep_caches_copy(copy_caches, caches)
	archive_caches.append(copy_caches)


func _cpu_go_back_in_time() -> void:
	if not archive_caches.is_empty():
		var previous_caches_contents = archive_caches.pop_back()
		_deep_caches_copy(caches, previous_caches_contents)
		ram = archive_ram.pop_back()
		Signals.force_system_contents_requested.emit(previous_caches_contents, ram)


func _handle_read(cpu_id: int, mem_address: int) -> void:
	_archive_caches_copy()
	archive_ram.append(ram.duplicate())

	var tag = mem_address >> 1
	var set_no = mem_address % 2
	var block_is_in_cache = caches[cpu_id].tag[set_no] == tag
	var block_is_invalid = caches[cpu_id].status[set_no] == MesiStates.I
	var needs_writeback = caches[cpu_id].status[set_no] == MesiStates.M

	if not block_is_in_cache and needs_writeback:
		await _writeback_block_to_ram(cpu_id, set_no)

	Signals.new_visuals_transaction_started.emit()

	if (block_is_in_cache and block_is_invalid) or not block_is_in_cache:
		await _snoop_read(cpu_id, mem_address)
	elif block_is_in_cache and not block_is_invalid:
		_read_in_cache(cpu_id, set_no, tag)
	else:
		assert(false, "Should not happen!")

	Signals.cpu_read_or_write_handled.emit()


func _handle_write(cpu_id: int, mem_address: int) -> void:
	_archive_caches_copy()
	archive_ram.append(ram.duplicate())

	var tag = mem_address >> 1
	var set_no = mem_address % 2
	var block_is_in_cache = caches[cpu_id].tag[set_no] == tag
	var block_is_exclusive = caches[cpu_id].status[set_no] == MesiStates.E
	var block_is_modified = caches[cpu_id].status[set_no] == MesiStates.M

	Signals.new_visuals_transaction_started.emit()

	if block_is_in_cache and (block_is_exclusive or block_is_modified):
		var new_data = caches[cpu_id].data[set_no] + 1
		_write_in_cache(cpu_id, set_no, tag, new_data, MesiStates.M)
	else:
		await _snoop_write(cpu_id, mem_address)

	Signals.cpu_read_or_write_handled.emit()


func _writeback_block_to_ram(cpu_id: int, set_no: int) -> void:
	Signals.new_visuals_transaction_started.emit()
	var writeback_address = caches[cpu_id].tag[set_no] * 2 + set_no
	Signals.write_transaction_started_to_ram.emit(cpu_id, writeback_address, caches[cpu_id].data[set_no])
	await Signals.transaction_finished
	ram[writeback_address] = caches[cpu_id].data[set_no]


func _write_in_cache(cpu_id: int, set_no: int, tag: int, data: int, state: MesiStates) -> void:
	caches[cpu_id].data[set_no] = data
	_update_cache_state(cpu_id, set_no, tag, state)
	Signals.write_transaction_performed_in_cache.emit(cpu_id, set_no, tag, caches[cpu_id].data[set_no])
	cache_write_audio.play()



func _update_cache_state(cpu_id: int, set_no: int, tag: int, state: MesiStates) -> void:
	caches[cpu_id].status[set_no] = state
	caches[cpu_id].tag[set_no] = tag
	Signals.cache_state_updated.emit(cpu_id, set_no, tag, MesiStates.keys()[state])


func _read_in_cache(cpu_id: int, set_no: int, tag: int) -> void:
	var state = MesiStates.keys()[caches[cpu_id].status[set_no]]
	Signals.read_transaction_performed_in_cache.emit(cpu_id, set_no, tag, state)


func _place_address_on_buses(cpu_id: int, mem_address: int) -> void:
	Signals.address_placed_on_buses.emit(cpu_id, mem_address)
	await Signals.transaction_finished


func _read_data_from_ram(cpu_id: int, mem_address: int) -> void:
	Signals.read_transaction_started_from_ram.emit(cpu_id, mem_address)
	await Signals.transaction_finished


func _read_from_other_cache(other_cpu_id: int, cpu_id: int, set_no: int, tag: int) -> void:
	var data = caches[other_cpu_id].data[set_no]
	var mem_address = tag * 2 + set_no

	_update_cache_state(other_cpu_id, set_no, tag, MesiStates.S)
	_read_in_cache(other_cpu_id, set_no, tag)
	Signals.read_transaction_started_from_other_cache.emit(other_cpu_id, cpu_id, mem_address, data)
	await Signals.transaction_finished


func _snoop_read(cpu_id: int, mem_address: int) -> void:
	var tag = mem_address >> 1
	var set_no = mem_address % 2

	var block_was_not_found_in_others = true
	var is_not_exclusive_or_modified_in_another_cache = true
	var is_shared_in_another_cache = false

	for other_cache_id in _get_other_cache_ids(cpu_id):
		var block_is_not_in_other_cache = caches[other_cache_id].tag[set_no] != tag
		if block_is_not_in_other_cache:
			continue

		block_was_not_found_in_others = false
		var block_in_other_is_shared = caches[other_cache_id].status[set_no] == MesiStates.S
		var block_in_other_is_exclusive = caches[other_cache_id].status[set_no] == MesiStates.E
		var block_in_other_is_modified = caches[other_cache_id].status[set_no] == MesiStates.M
		is_shared_in_another_cache = is_shared_in_another_cache or block_in_other_is_shared

		if block_in_other_is_exclusive:
			is_not_exclusive_or_modified_in_another_cache = false
			await _place_address_on_buses(cpu_id, mem_address)
			_update_cache_state(other_cache_id, set_no, tag, MesiStates.S)
			await _read_data_from_ram(cpu_id, mem_address)
			_write_in_cache(cpu_id, set_no, tag, ram[mem_address], MesiStates.S)
			_read_in_cache(cpu_id, set_no, tag)
			break
		elif block_in_other_is_modified:
			is_not_exclusive_or_modified_in_another_cache = false
			var other_cache_data = caches[other_cache_id].data[set_no]
			await _place_address_on_buses(cpu_id, mem_address)
			await _read_from_other_cache(other_cache_id, cpu_id, set_no, tag)
			_write_in_cache(cpu_id, set_no, tag, other_cache_data, MesiStates.S)
			_read_in_cache(cpu_id, set_no, tag)
			ram[mem_address] = other_cache_data
			break

	if block_was_not_found_in_others or is_not_exclusive_or_modified_in_another_cache:
		await _place_address_on_buses(cpu_id, mem_address)
		await _read_data_from_ram(cpu_id, mem_address)
		var state = MesiStates.S if is_shared_in_another_cache else MesiStates.E
		_write_in_cache(cpu_id, set_no, tag, ram[mem_address], state)
		_read_in_cache(cpu_id, set_no, tag)


func _snoop_write(cpu_id: int, mem_address: int) -> void:
	var tag = mem_address >> 1
	var set_no = mem_address % 2
	var block_is_in_cache = caches[cpu_id].tag[set_no] == tag
	var block_is_invalid = caches[cpu_id].status[set_no] == MesiStates.I
	var block_is_shared = caches[cpu_id].status[set_no] == MesiStates.S

	if block_is_in_cache and block_is_shared:
		await _place_address_on_buses(cpu_id, mem_address)
		if not _protocal_is_bugged:
			_invalidate_other_caches(cpu_id, set_no, tag)
		await _read_data_from_ram(cpu_id, mem_address)
		var new_data = ram[mem_address] + 1
		_write_in_cache(cpu_id, set_no, tag, new_data, MesiStates.M)
	elif (block_is_in_cache and block_is_invalid) or not block_is_in_cache:
		var writeback_in_this_cache_needed = caches[cpu_id].status[set_no] == MesiStates.M
		var wb = _get_caches_that_need_writeback(cpu_id, set_no, tag)
		var writeback_in_another_cache_needed = wb[0]
		var writeback_cpu_id = wb[1]

		if writeback_in_this_cache_needed:
			await _writeback_block_to_ram(cpu_id, set_no)
			Signals.new_visuals_transaction_started.emit()

		if writeback_in_another_cache_needed:
			await _place_address_on_buses(cpu_id, mem_address)
			await _read_from_other_cache(writeback_cpu_id, cpu_id, set_no, tag)
			var other_cache_data = caches[writeback_cpu_id].data[set_no]
			_update_cache_state(writeback_cpu_id, set_no, tag, MesiStates.I)
			_write_in_cache(cpu_id, set_no, tag, other_cache_data + 1, MesiStates.M)
			ram[mem_address] = other_cache_data
		else:
			await _place_address_on_buses(cpu_id, mem_address)
			if not _protocal_is_bugged:
				_invalidate_other_caches(cpu_id, set_no, tag)
			await _read_data_from_ram(cpu_id, mem_address)
			var new_data = ram[mem_address] + 1
			_write_in_cache(cpu_id, set_no, tag, new_data, MesiStates.M)


func _invalidate_other_caches(cpu_id: int, set_no: int, tag: int) -> void:
	for other_cache_id in _get_other_cache_ids(cpu_id):
		var block_is_in_another_cache = caches[other_cache_id].tag[set_no] == tag
		var other_is_shared = caches[other_cache_id].status[set_no] == MesiStates.S
		var other_is_exclusive = caches[other_cache_id].status[set_no] == MesiStates.E
		if block_is_in_another_cache and (other_is_shared or other_is_exclusive):
			_update_cache_state(other_cache_id, set_no, tag, MesiStates.I)


func _get_caches_that_need_writeback(cpu_id: int, set_no: int, tag: int) -> Array:
	var writeback_in_another_cache_needed = false
	var writeback_cpu_id = 0

	for other_cache_id in _get_other_cache_ids(cpu_id):
		var block_is_in_another_cache = caches[other_cache_id].tag[set_no] == tag
		if block_is_in_another_cache and caches[other_cache_id].status[set_no] == MesiStates.M :
			writeback_in_another_cache_needed = true
			writeback_cpu_id = other_cache_id
			break

	return [writeback_in_another_cache_needed, writeback_cpu_id]


func _get_other_cache_ids(current_id: int) -> Array:
	var other_ids = caches.keys()
	other_ids.erase(current_id)
	return other_ids
