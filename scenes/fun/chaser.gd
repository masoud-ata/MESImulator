extends Node2D


enum State {Running, Dead}

var state := State.Running

@onready var big_guy: AnimatedSprite2D = $BigGuy
@onready var bald_guy: AnimatedSprite2D = $BaldGuy

@onready var chasers: Array[AnimatedSprite2D] = [big_guy, bald_guy]
@onready var random_chaser: AnimatedSprite2D = chasers.pick_random()


func _ready() -> void:
	for chaser in chasers:
		chaser.visible = false

	random_chaser.visible = true
	random_chaser.play("run")


func _process(delta: float) -> void:
	if state == State.Running:
		const SPEED = 300
		position.x += SPEED * delta


func kill() -> void:
	queue_free()


func _on_area_2d_area_entered(_area: Area2D) -> void:
	random_chaser.play("dead")
	state = State.Dead

	var tween = create_tween()
	var pos = position
	tween.tween_property(self, "position", pos + Vector2(0, -30), .2)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position", position, .3)\
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)

	await get_tree().create_timer(2).timeout

	kill()
