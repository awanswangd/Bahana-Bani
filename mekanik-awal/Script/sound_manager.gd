extends Node

# Referensi ke BGMPlayer
@onready var bgm_player = $BGMPlayer

# Library untuk menyimpan sfx
var sfx_library = {}

# Daftar sfx
var sfx_to_load = {
	"win": "res://audio/sfx/win.wav",
	"correct": "res://audio/sfx/correct.wav",
	"enemy_projectile": "res://audio/sfx/enemy_projectile.wav",
	"hit": "res://audio/sfx/hit.wav",
	"lose": "res://audio/sfx/lose.wav",
	"misstype": "res://audio/sfx/misstype.wav",
	"projectile_correct": "res://audio/sfx/projectile_correct.wav"
}


func _ready() -> void:
	# Muat sfx
	for sound_name in sfx_to_load:
		sfx_library[sound_name] = load(sfx_to_load[sound_name])

# Pemutar musik
func play_music(music_stream: AudioStream):
	bgm_player.stream = music_stream
	bgm_player.volume_db = -10.0
	bgm_player.autoplay = true
	
	bgm_player.play()

func stop_music() -> void:
	if bgm_player and bgm_player.playing:
		bgm_player.stop()

# Pemutar sfx
func play_sfx(sound_name: String):
	# Periksa sfx
	if not sfx_library.has(sound_name):
		print("Error: SFX " + sound_name + " not found")
		return
		
	# Buat pemutar audio baru, transfer audio dari library
	var sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = sfx_library[sound_name]
	sfx_player.connect("finished", sfx_player.queue_free)
	
	# Tambahkan sebagai child dan play
	add_child(sfx_player)
	sfx_player.play()
