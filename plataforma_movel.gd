extends AnimatableBody2D

@export var speed: float = 220.0 # Velocidade da direita para a esquerda
@export var move_duration: float = 6.0 # Tempo total ativo antes de ser removida

var timer: float = 0.0

func _ready() -> void:
	sync_to_physics = true

func _physics_process(delta: float) -> void:
	position.x -= speed * delta
	timer += delta

	if timer >= move_duration:
		queue_free()
