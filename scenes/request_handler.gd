extends Node


class Request:
	var is_read: bool
	var cpu_id: int
	var address: int

var request_queue: Array[Request] = []
var _busy_handling_request := false


func _ready() -> void:
	Signals.user_read_requested.connect(_user_read_requested)
	Signals.user_write_requested.connect(_user_write_requested)
	Signals.cpu_read_or_write_handled.connect(_cpu_read_or_write_handled)


func _user_read_requested(cpu_id: int, memory_address: int) -> void:
	_add_request(cpu_id, memory_address, true)


func _user_write_requested(cpu_id: int, memory_address: int) -> void:
	_add_request(cpu_id, memory_address, false)


func _cpu_read_or_write_handled() -> void:
	_busy_handling_request = false
	if not request_queue.is_empty():
		var request = request_queue.pop_front()
		_issue_request(request)


func _attempt_issue_request(request: Request) -> bool:
	var was_request_handled = false
	if not _busy_handling_request and request_queue.is_empty():
		was_request_handled = true
		_issue_request(request)
	return was_request_handled


func _issue_request(request: Request) -> void:
	_busy_handling_request = true
	if request.is_read:
		Signals.cpu_read_issued.emit(request.cpu_id, request.address)
	else:
		Signals.cpu_write_issued.emit(request.cpu_id, request.address)


func _add_request(cpu_id: int, mem_address: int, is_read: bool) -> void:
	var request = Request.new()
	request.is_read = is_read
	request.cpu_id = cpu_id
	request.address = mem_address
	var was_issued = _attempt_issue_request(request)
	if not was_issued:
		request_queue.append(request)
