extends Node

var save_path = "user://highscore.save"
var high_score: int = 0

func _ready():
	load_score()

func save_score():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_32(high_score)
		print("High Score berhasil disimpan.")
	else:
		print("Gagal menyimpan file!")

func load_score():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			high_score = file.get_32()
			print("High Score dimuat: ", high_score)
	else:
		print("Belum ada file save. High Score diset ke 0.")
		high_score = 0

func check_and_update_highscore(current_score: int) -> bool:
	if current_score > high_score:
		high_score = current_score
		save_score()
		return true
	return false
