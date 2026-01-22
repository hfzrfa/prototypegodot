extends Area2D

@onready var timer: Timer = $Timer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

const RELOAD_DELAY := 0.2

func _on_body_entered(body: Node2D) -> void:
	print("You Died!")
	animation_player.play("death")
	Engine.time_scale = 0.1
	if body.has_method("die"):
		body.call("die")
	else:
		var collision := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision:
			collision.disabled = true

	timer.ignore_time_scale = true
	timer.start(RELOAD_DELAY)

func _on_timer_timeout() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
