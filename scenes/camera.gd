extends Camera2D


var _shake_amount := 0.0


func _ready():
	Signals.fun_huge_explosion_happened.connect(_add_screenshake)


func _physics_process(delta: float) -> void:
	_update_shake()


func _add_screenshake() -> void:
	_screen_shake(4, 0.5)


func _screen_shake(amount: float, duration: float) -> void:
	_shake_amount = amount
	await get_tree().create_timer(0.5).timeout
	_shake_amount = 0.0


func _update_shake() -> void:
	offset.x = randf_range(-_shake_amount, _shake_amount)
	offset.y = randf_range(-_shake_amount, _shake_amount)
