extends Node2D


const Explosion = preload("res://scenes/fun/bomb.tscn")
const Chaser = preload("res://scenes/fun/chaser.tscn")

@onready var bomb_guy: AnimatedSprite2D = $BombGuy


func _ready() -> void:
	Signals.user_fun_requested.connect(_start_having_fun, CONNECT_ONE_SHOT)


func _start_having_fun() -> void:
	var we_want_ridiculous_bomb_baby = randi_range(1, 2) == 2
	if we_want_ridiculous_bomb_baby:
		await _start_ridiculous_bomb_fun()
	else:
		await _start_chase_fun()


func _start_ridiculous_bomb_fun() -> void:
	var bomb = Explosion.instantiate()
	bomb.global_position = Vector2(400, 320)
	bomb.scale = Vector2(6, 6)
	bomb.is_timed = true
	add_child(bomb)
	await Signals.fun_huge_explosion_happened
	Signals.user_fun_requested.connect(_start_having_fun, CONNECT_ONE_SHOT)


func _start_chase_fun():
	bomb_guy.play("run")

	var viewport_size = get_viewport().get_visible_rect().size
	var run_to_position_x = viewport_size.x + 200

	var tween = create_tween()
	tween.tween_property(bomb_guy, "global_position", bomb_guy.global_position + Vector2(run_to_position_x, 0.0), 5)

	await get_tree().create_timer(2.5).timeout

	var chaser = Chaser.instantiate()
	add_child(chaser)
	chaser.global_position = Vector2(-100, viewport_size.y)

	await get_tree().create_timer(0.5).timeout

	var bomb = Explosion.instantiate()
	bomb.global_position = bomb_guy.global_position
	add_child(bomb)

	await tween.finished

	Signals.user_fun_requested.connect(_start_having_fun, CONNECT_ONE_SHOT)

	bomb_guy.global_position.x = 0.0 - 100.0
