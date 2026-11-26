extends Node

signal beat(beat_index: int)

@export var bpm: float = 164.0
@export var tick_sound: AudioStream # Opcional: som de clique do metrônomo

var beat_duration: float = 0.5
var timer: float = 0.0
var current_beat: int = 0
var audio_player: AudioStreamPlayer

func _ready() -> void:
	add_to_group("metronome")
	beat_duration = 60.0 / bpm
	
	if tick_sound:
		audio_player = AudioStreamPlayer.new()
		audio_player.stream = tick_sound
		add_child(audio_player)

func _process(delta: float) -> void:
	timer += delta
	if timer >= beat_duration:
		timer -= beat_duration
		trigger_beat()

func trigger_beat() -> void:
	if audio_player:
		audio_player.play()
	beat.emit(current_beat)
	current_beat += 1
