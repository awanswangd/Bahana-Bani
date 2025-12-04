extends Node

var save_path = "user://leaderboard.save"
var scores: Array = []

func _ready():
	load_scores()

func add_score(new_score: int):
	scores.append(new_score)
	scores.sort()
	scores.reverse()
	if scores.size() > 20:
		scores.resize(20) 
		
	save_scores()
	
func save_scores():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(scores)
		print("Leaderboard disimpan: ", scores)

func load_scores():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			scores = file.get_var()
			print("Leaderboard dimuat: ", scores)
	else:
		scores = []
func get_best_score() -> int:
	if scores.size() > 0:
		return scores[0]
	return 0
