extends CharacterBody2D

const SPEED := 130.0
const JUMP_VELOCITY := -300.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var cam: Camera2D = $Camera2D

var was_on_floor := false
var is_dead := false
var last_floor_collider: Object = null

const TRAMPOLINE_GROUP := "trampolin"
const TRAMPOLINE_BOUNCE_MULTIPLIER := 2.0

func die() -> void:
	if is_dead:
		return
	is_dead = true

	velocity = Vector2.ZERO
	set_physics_process(false)
	set_process_input(false)

	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision:
		collision.disabled = true

	if (
		animated_sprite
		and animated_sprite.sprite_frames
		and animated_sprite.sprite_frames.has_animation("death")
	):
		animated_sprite.sprite_frames.set_animation_loop("death", false)
		animated_sprite.play("death")

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Auto-jump saat baru mendarat
	var on_floor_now := is_on_floor()
	if on_floor_now and not was_on_floor:
		var bounced := false
		var floor_node := last_floor_collider as Node
		if floor_node and (
			floor_node.is_in_group(TRAMPOLINE_GROUP)
			or floor_node.name.to_lower().contains("trampolin")
		):
			velocity.y = JUMP_VELOCITY * TRAMPOLINE_BOUNCE_MULTIPLIER
			bounced = true
		if not bounced:
			velocity.y = JUMP_VELOCITY
		animation_player.play("jump")
	was_on_floor = on_floor_now

	# Movement kiri kanan
	var direction := Input.get_axis("move_left", "move_right")
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Animations
	if is_on_floor():
		animated_sprite.play("run" if direction != 0 else "idle")
	else:
		animated_sprite.play("jump")
	

	move_and_slide()
	_update_last_floor_collider()

func _update_last_floor_collider() -> void:
	# Best-effort: find the collider we are standing on from slide collisions.
	last_floor_collider = null
	var count := get_slide_collision_count()
	for i in range(count):
		var col := get_slide_collision(i)
		# Floor surfaces usually have an UP normal (0, -1)
		if col and col.get_normal().y < -0.7:
			last_floor_collider = col.get_collider()
			return
