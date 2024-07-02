extends Node2D


@onready var bomb: AnimatedSprite2D = $Bomb
@onready var explosion: AnimatedSprite2D = $Explosion


func _ready() -> void:
	_activate()


func _activate() -> void:
	var tween = create_tween()
	tween.tween_property(bomb, "scale", Vector2.ONE, 0.1)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(bomb, "scale", Vector2(0.75, 0.75), 0.2)\
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)

	tween.parallel().tween_property(bomb, "position", bomb.position + Vector2(0, -30), 0.15)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(bomb, "position", bomb.position + Vector2(0, +30), 0.2)\
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)


func _explode() -> void:
	bomb.visible = false
	explosion.play("default")
	await explosion.animation_finished
	queue_free()


func _on_area_entered(_area: Area2D) -> void:
	_explode()

