extends Node2D

var Enemy = preload("res://enemy.tscn")
var EnemyArcher = preload("res://enemy_archer.tscn")
var Projectile = preload("res://projectile.tscn")

var score: int = 0
var max_hp: int = 99
var hp: int = max_hp

enum GameState { PLAYING, GAME_OVER }
var game_state: GameState = GameState.PLAYING
var restart_phrase := "hidup lagi"
var restart_index: int = 0

@onready var player = $Player
@onready var hp_label = $CanvasLayer/HPLabel
@onready var score_label = $CanvasLayer/ScoreLabel
@onready var spawn_timer = $SpawnTimer
@onready var enemy_container = $enemycontainer
@onready var spawn_container = $SpawnContainer
@onready var projectile_container = $ProjectileContainer

var active_enemy = null
var current_letter_index: int = -1

var word_list = [
	"game ini bagus",
	"musik for life",
	"hidup popowi",
	"bahluil pertaminux",
	"skill issue",
	"quest ez pz",
	"attack on titan",
	"colossal titan",
	"reinkarnasi jadi slime"
]
var projectile_words = [
	"po",
	"pi",
	"pow",
	"zap",
	"hit",
	"wid",
	"xo"
]

func _ready() -> void:
	add_to_group("main")
	randomize()
	spawn_timer.start()
	spawn_enemy()
	update_hp_display()
	score_label.text = "SCORE: %d" % score

func player_hit() -> void:
	if game_state != GameState.PLAYING:
		return
	hp -= 1
	if hp < 0:
		hp = 0
	update_hp_display()
	if hp == 0:
		game_over()

func game_over() -> void:
	game_state = GameState.GAME_OVER
	print("GAME OVER")
	spawn_timer.stop()
	for enemy in enemy_container.get_children():
		enemy.queue_free()
	var go_label = $CanvasLayer/GameOverLabel
	go_label.text = "GAME OVER\nKetik \"hidup lagi\" untuk bermain lagi"
	go_label.show()

func add_score(amount: int):
	score += amount
	score_label.text = "SCORE: %d" % score

func update_hp_display() -> void:
	hp_label.text = "HP: %d" % hp

func find_new_active_enemy(typed_character: String):
	print("Searching for enemy starting with: '%s'" % typed_character)
	for projectile in projectile_container.get_children():
		var prompt = projectile.get_prompt()
		print("Checking projectile with prompt: '%s'" % prompt)
		if prompt.is_empty():
			continue

		var next_character = prompt.substr(0, 1).to_lower()
		if next_character == typed_character:
			print("Found projectile that starts with %s" % next_character)
			active_enemy = projectile
			current_letter_index = 1
			active_enemy.set_next_character(current_letter_index)
			return
	
	for enemy in enemy_container.get_children():
		var prompt = enemy.get_prompt()
		print("Checking enemy with prompt: '%s'" % prompt)
		if prompt.is_empty():
			continue

		var next_character = prompt.substr(0, 1).to_lower()
		if next_character == typed_character:
			print("Found enemy that starts with %s" % next_character)
			active_enemy = enemy
			current_letter_index = 1
			active_enemy.set_next_character(current_letter_index)
			return

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and not event.is_pressed():
		var key_typed = event.as_text().to_lower()
		if key_typed == "":
			return
		if key_typed == "space":
			key_typed = " "
		if game_state == GameState.GAME_OVER:
			handle_restart_typing(key_typed)
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
					print("done")
					add_score(100)
					current_letter_index = -1
					active_enemy.queue_free()
					active_enemy = null
			else:
				print("gagal %s harusnya %s" % [key_typed, next_character])

func handle_restart_typing(key_typed: String) -> void:
	var key_char := key_typed

	if key_typed == "space":
		key_char = " "

	var expected_char := restart_phrase.substr(restart_index, 1)

	if key_char == expected_char:
		restart_index += 1
		print("Restart progress: %d / %d" % [restart_index, restart_phrase.length()])

		if restart_index >= restart_phrase.length():
			print("Restart complete! Hidup lagi")
			get_tree().reload_current_scene()
	else:
		print("Salah ketik buat restart, mulai lagi dari awal.")
		restart_index = 0

func _on_spawn_timer_timeout() -> void:
	spawn_enemy()

func spawn_enemy() -> void:
	if game_state != GameState.PLAYING:
		return

	var enemy_instance: Node2D

	#chanche spawn
	if randi() % 3 == 0:
		enemy_instance = EnemyArcher.instantiate()
	else:
		enemy_instance = Enemy.instantiate()

	var spawns = spawn_container.get_children()
	var index = randi() % spawns.size()

	enemy_container.add_child(enemy_instance)
	enemy_instance.global_position = spawns[index].global_position

	if enemy_instance.has_method("set_prompt"):
		var word = word_list.pick_random()
		enemy_instance.set_prompt(word)


func spawn_projectile_at(pos: Vector2) -> void:
	if game_state != GameState.PLAYING:
		return

	var p = Projectile.instantiate()
	projectile_container.add_child(p)
	p.global_position = pos

	var word = projectile_words.pick_random()
	p.set_prompt(word)


func _on_player_line_area_entered(area: Area2D) -> void:
	var obj = area.get_parent()
	if obj.is_in_group("enemy"):
		hp -= 1
		if hp < 0:
			hp = 0
		update_hp_display()
		if obj == active_enemy:
			active_enemy = null
			current_letter_index = -1
		obj.queue_free()
		if hp == 0:
			game_over()
		return
	if obj.is_in_group("projectile"):
		hp -= 1
		if hp < 0:
			hp = 0
		update_hp_display()
		if obj == active_enemy:
			active_enemy = null
			current_letter_index = -1
		obj.queue_free()
		if hp == 0:
			game_over()
		return
