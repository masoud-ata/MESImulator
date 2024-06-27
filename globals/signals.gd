extends Node


signal animation_speed_factor_changed(factor: float)

signal user_reset_requested

signal user_read_requested(cpu_id: int, memory_address: int)
signal user_write_requested(cpu_id: int, memory_address: int)
signal cpu_read_issued(cpu_id: int, memory_address: int)
signal cpu_write_issued(cpu_id: int, memory_address: int)
signal cpu_read_or_write_handled

signal write_transaction_performed_in_cache(cpu_id: int, set_no: int, tag: int, data: int)
signal read_transaction_performed_in_cache(cpu_id: int, set_no: int, tag: int, state: String)

signal read_transaction_started_on_bus(cpu_id: int, mem_address: int)
signal read_transaction_started_from_ram(cpu_id: int, mem_address: int)
signal read_transaction_started_from_other_cache(other_cpu_id: int, cpu_id: int, mem_address: int, data: int)

signal write_transaction_started_to_ram(cpu_id: int, mem_address: int, data: int)

signal cache_state_updated(cpu_id: int, set_no: int)

signal transaction_finished

signal all_new_transaction_started
