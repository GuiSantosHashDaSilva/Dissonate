extends Marker2D

@export var platform_scene: PackedScene # Arraste o arquivo plataforma_movel.tscn aqui
@export var beat_pattern: Array[bool] = [true, false] # true = nasce na batida, false = pausa

@export_group("Configuração das Plataformas Geradas")
@export var platform_speed: float = 220.0
@export var platform_duration: float = 6.0 # Ajuste para cobrir toda a largura da tela

func _ready() -> void:
	var metronome := get_tree().get_first_node_in_group("metronome")
	if metronome:
		metronome.beat.connect(_on_beat)

func _on_beat(beat_index: int) -> void:
	if beat_pattern.is_empty() or not platform_scene:
		return

	var step := posmod(beat_index, beat_pattern.size())
	if beat_pattern[step]:
		spawn_platform()

func spawn_platform() -> void:
	var platform := platform_scene.instantiate()
	platform.global_position = global_position
	platform.speed = platform_speed
	platform.move_duration = platform_duration
	get_parent().add_child(platform)
