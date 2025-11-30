extends HSlider

@export var audio_bus_name: String 

var audio_bus_id 

func _ready():
	audio_bus_id = AudioServer.get_bus_index(audio_bus_name)
	print("MusicSlider: bus_name=", audio_bus_name, " bus_id=", audio_bus_id)

	print("--- AUDIO BUS LIST ---")
	var count = AudioServer.get_bus_count()
	print("Bus count:", count)
	for i in range(count):
		print("Bus[", i, "] name = ", AudioServer.get_bus_name(i))

func _on_value_changed(value: float) -> void:
	if audio_bus_id == -1:
		print("MusicSlider ERROR: bus not found: ", audio_bus_name)
		return

	var v = max(value, 0.001)
	var db = linear_to_db(v)
	AudioServer.set_bus_volume_db(audio_bus_id, db)
