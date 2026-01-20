extends Area2D

@onready var timer: Timer = $Timer

const RELOAD_DELAY := 0.9

func _on_body_entered(body: Node2D) -> void:
	print("KILLZONE HIT:", body.name)
	Engine.time_scale = 0.5
	if body.has_method("die"):
		body.call("die")
	else:
		var collision := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision:
			collision.disabled = true

	timer.ignore_time_scale = true
	timer.start(RELOAD_DELAY)

func _on_timer_timeout():
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
