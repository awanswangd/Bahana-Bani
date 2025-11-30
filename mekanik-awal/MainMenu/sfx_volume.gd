extends HSlider
@export var audio_bus_name: String 
@onready var sfx_sample_: AudioStreamPlayer = $"../../../Sfx(sample)"

var audio_bus_id 

func _ready():
	audio_bus_id = AudioServer.get_bus_index(audio_bus_name)

func _on_value_changed(value: float) -> void:
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(audio_bus_id, db)
	if not sfx_sample_.playing:
		sfx_sample_.play()
	else:
		sfx_sample_.stop()
		sfx_sample_.play()
