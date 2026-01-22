extends CharacterBody2D

const SPEED := 200.0
const JUMP_VELOCITY := -400.0
const CAMERA_TOP_MARGIN := 80.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var cam: Camera2D = get_node_or_null("Camera2D")

var was_on_floor := false
var is_dead := false
var last_floor_collider: Object = null

const TRAMPOLINE_GROUP := "trampolin"
const TRAMPOLINE_BOUNCE_MULTIPLIER := 2.0

# Kamera
var camera_start_x: float
var camera_min_y: float   # kamera hanya boleh naik (Y makin kecil)

func _ready() -> void:
	if cam:
		camera_start_x = cam.global_position.x
		camera_min_y = cam.global_position.y

func die() -> void:
	is_dead = true
	# Hentikan semua velocity agar tidak melompat
	velocity = Vector2.ZERO
	# Disable collision agar tidak bereaksi dengan platform
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Auto jump saat mendarat
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
	
	# Movement kiri–kanan
	var direction := Input.get_axis("move_left", "move_right")
	
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	
	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# Animasi
	if is_on_floor():
		animated_sprite.play("run" if direction != 0 else "idle")
	else:
		animated_sprite.play("jump")
	
	move_and_slide()
	_update_last_floor_collider()
	_update_camera()
	_screen_wrap()

func _update_last_floor_collider() -> void:
	last_floor_collider = null
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		if col and col.get_normal().y < -0.7:
			last_floor_collider = col.get_collider()
			return

func _update_camera() -> void:
	if not cam:
		return
	
	# Kunci kamera horizontal
	cam.global_position.x = camera_start_x
	
	# Hitung batas atas view kamera (world space)
	var viewport_height := cam.get_viewport().get_visible_rect().size.y
	var half_height := (viewport_height * 0.5) / cam.zoom.y
	var top_limit := cam.global_position.y - half_height + CAMERA_TOP_MARGIN
	
	# Jika player MENEMBUS batas atas kamera
	if global_position.y < top_limit:
		var target_y := global_position.y + half_height - CAMERA_TOP_MARGIN
		# ONE-WAY UP: kamera tidak boleh turun
		camera_min_y = min(camera_min_y, target_y)
		cam.global_position.y = camera_min_y

func _screen_wrap() -> void:
	if not cam:
		return
	
	var viewport_width := get_viewport().get_visible_rect().size.x
	var half_width := (viewport_width * 0.5) / cam.zoom.x
	
	var left_edge := cam.global_position.x - half_width
	var right_edge := cam.global_position.x + half_width
	
	# Jika player keluar dari sisi kanan, teleport ke kiri
	if global_position.x > right_edge:
		global_position.x = left_edge
	# Jika player keluar dari sisi kiri, teleport ke kanan
	elif global_position.x < left_edge:
		global_position.x = right_edge
