extends CharacterBody2D

@export_group("Animação")
@export var animacao: AnimatedSprite2D

# --- Configurações de Movimento Horizontal ---
@export_group("Movimento")
@export var speed: float = 340.0
@export var acceleration: float = 3800.0
@export var friction: float = 4200.0

# --- Configurações de Pulo e Gravidade ---
@export_group("Pulo")
@export var jump_velocity: float = -540.0
@export var jump_cut_multiplier: float = 0.45 # Corta a altura ao soltar o botão cedo
@export var fall_gravity_multiplier: float = 1.65 # Queda mais rápida que a subida
@export var max_fall_speed: float = 950.0
@export var coyote_time: float = 0.12 # Tempo extra para pular após sair de uma plataforma
@export var jump_buffer_time: float = 0.12 # Memoriza o aperto do botão antes de tocar o chão

# --- Configurações de Dash ---
@export_group("Dash")
@export var dash_speed: float = 880.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.35

# --- Configurações de Parede (Wall Slide / Wall Jump) ---
@export_group("Parede")
@export var wall_slide_speed: float = 160.0
@export var wall_jump_velocity: Vector2 = Vector2(420.0, -520.0)
@export var wall_jump_lock_time: float = 0.12 # Breve trava para afastar o personagem da parede

# --- Variáveis de Estado ---
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var facing_direction: float = 1.0

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var wall_jump_lock_timer: float = 0.0

var is_dashing: bool = false
var can_dash: bool = true
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: float = 1.0

func _physics_process(delta: float) -> void:
	update_timers(delta)
	
	
	# Reseta o dash ao tocar o chão ou deslizar na parede
	if is_on_floor() or is_on_wall_only():
		can_dash = true

	# 1. Execução do Dash (sobrepõe gravidade e movimento normal)
	if is_dashing:
		velocity = Vector2(dash_direction * dash_speed, 0.0)
		move_and_slide()
		return

	# Inicia o Dash
	if Input.is_action_just_pressed("dash") and can_dash and dash_cooldown_timer <= 0.0:
		start_dash()
		return

	# 2. Gravidade e Deslizamento na Parede (Wall Slide)
	apply_gravity(delta)

	# 3. Pulo (Chão, Coyote Time e Wall Jump)
	handle_jump()

	# 4. Movimentação Horizontal
	handle_horizontal_movement(delta)

	move_and_slide()
	update_animations()

func update_timers(delta: float) -> void:
	# Coyote Time
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta

	# Jump Buffer
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta

	# Timers de Dash e Wall Jump
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
			velocity.x *= 0.5 # Reduz o embalo residual ao fim do dash

	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	if wall_jump_lock_timer > 0.0:
		wall_jump_lock_timer -= delta

func start_dash() -> void:
	is_dashing = true
	can_dash = false
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	
	var input_dir := Input.get_axis("move_left", "move_right")
	# Se estiver na parede sem direcional, dá dash para longe da parede
	if is_on_wall_only() and input_dir == 0.0:
		dash_direction = get_wall_normal().x
	elif input_dir != 0.0:
		dash_direction = sign(input_dir)
	else:
		dash_direction = facing_direction
		
	facing_direction = dash_direction
	animacao.play("dash")

func apply_gravity(delta: float) -> void:
	if is_on_floor():
		return

	# Wall Slide automático ao encostar na parede caindo (estilo Mantis Claw)
	if is_on_wall_only() and velocity.y > 0.0:
		velocity.y = min(velocity.y + gravity * delta, wall_slide_speed)
	else:
		var current_gravity := gravity
		if velocity.y > 0.0:
			current_gravity *= fall_gravity_multiplier
		velocity.y = min(velocity.y + current_gravity * delta, max_fall_speed)

func handle_jump() -> void:
	# Executa pulo se houver buffer ativo
	if jump_buffer_timer > 0.0:
		if coyote_timer > 0.0:
			# Pulo normal ou via Coyote Time
			velocity.y = jump_velocity
			jump_buffer_timer = 0.0
			coyote_timer = 0.0
		elif is_on_wall_only():
			# Wall Jump
			var wall_normal := get_wall_normal()
			velocity.x = wall_normal.x * wall_jump_velocity.x
			velocity.y = wall_jump_velocity.y
			facing_direction = sign(wall_normal.x)
			wall_jump_lock_timer = wall_jump_lock_time
			jump_buffer_timer = 0.0

	# Pulo de altura variável (soltar o botão corta a subida)
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier

func handle_horizontal_movement(delta: float) -> void:
	if wall_jump_lock_timer > 0.0:
		return

	var direction := Input.get_axis("move_left", "move_right")
	
	if direction != 0.0:
		facing_direction = sign(direction)
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

func update_animations() -> void:
	# Vira o sprite horizontalmente se o personagem olhar para a esquerda
	animacao.flip_h = facing_direction < 0.0

	if is_on_floor():
		# Ativa "idle" quando o personagem está parado no chão
		if abs(velocity.x) < 10.0:
			animacao.play("idle")
		else:
			# Quando criar a animação de corrida, descomente a linha abaixo:
			animacao.play("correndo")
			pass
