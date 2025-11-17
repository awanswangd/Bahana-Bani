extends Node2D

var Enemy = preload("res://enemy.tscn")
var score: int = 0


@onready var score_label = $CanvasLayer/ScoreLabel
@onready var spawn_timer = $SpawnTimer
@onready var enemy_container = $enemycontainer
@onready var spawn_container = $SpawnContainer
var active_enemy = null
var current_letter_index: int = -1

func _ready() -> void:
	randomize()
	spawn_timer.start()
	spawn_enemy()

func add_score(amount: int):
	score += amount
	score_label.text = "SCORE: %d" % score

func find_new_active_enemy(typed_character: String):
	print("Searching for enemy starting with: '%s'" % typed_character)
	for enemy in enemy_container.get_children():
		var prompt = enemy.get_prompt()
		print("Checking enemy with prompt: '%s'" % prompt)
		var next_character = prompt.substr(0, 1).to_lower()
		if next_character == typed_character:
			print("found new enemy that start with %s" % next_character)
			active_enemy = enemy
			current_letter_index = 1
			active_enemy.set_next_character(current_letter_index)
			return


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and not event.is_pressed():
		var key_typed = event.as_text().to_lower()
		if key_typed == "":
			return
		
		print("Input detected: '%s'" % key_typed)
		
		if active_enemy == null:
			find_new_active_enemy(key_typed)
		else:
			var prompt = active_enemy.get_prompt()
			var next_character = prompt.substr(current_letter_index, 1).to_lower()
			if key_typed == next_character:
				print("success %s" % key_typed)
				current_letter_index += 1
				active_enemy.set_next_character(current_letter_index)
				if current_letter_index == prompt.length():
					add_score(100)
					current_letter_index = -1
					active_enemy.queue_free()
					active_enemy = null
			else:
				print("gagal %s harusnya %s" % [key_typed, next_character])


func _on_spawn_timer_timeout() -> void:
	spawn_enemy()

func spawn_enemy():
	var enemy_instance = Enemy.instantiate()
	var spawns = spawn_container.get_children()
	var index = randi() % spawns.size()
	enemy_container.add_child(enemy_instance)
	enemy_instance.global_position = spawns[index].global_position
