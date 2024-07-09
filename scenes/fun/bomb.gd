extends Node2D


var is_timed := false
var explosion_signal := Signals.fun_explosion_happened


@onready var bomb: AnimatedSprite2D = $Bomb
@onready var explosion: AnimatedSprite2D = $Explosion
@onready var explosion_audio: AudioStreamPlayer = $ExplosionAudio


func _ready() -> void:
	_create()
	if is_timed:
		explosion_signal = Signals.fun_huge_explosion_happened
		create_tween().tween_callback(_explode).set_delay(2)


func _create() -> void:
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
	explosion_signal.emit()
	bomb.visible = false
	explosion.play("default")
	explosion_audio.play()
	await explosion.animation_finished
	queue_free()


func _on_area_entered(_area: Area2D) -> void:
	_explode()
