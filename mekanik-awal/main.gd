extends Node2D

var Enemy = preload("res://enemy.tscn")
var EnemyArcher = preload("res://enemy_archer.tscn")
var Projectile = preload("res://projectile.tscn")
var EnemyBoss = preload("res://enemy_boss.tscn")

var score: int = 0
var max_hp: int = 5
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
@onready var wave_timer = $WaveTimer
@onready var wave_label = $CanvasLayer.get_node_or_null("WaveLabel")
@onready var gameover_label = $CanvasLayer/GameOverLabel

var active_enemy = null
var current_letter_index: int = -1

var word_list = [
	"temambugh",
	"kaghai",
	"kumbang",
	"pedom",
	"lapah",
	"ghatong",
	"lengong",
	"ghuccah",
	"tebengbang",
	"mahu",
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

var waves = [
	{ "name":"Wave 1", "minion_count":5, "spawn_boss": false, "mix": false },
	{ "name":"Wave 2", "minion_count":5, "spawn_boss": false, "mix": true  },
	{ "name":"Wave 3", "minion_count":5, "spawn_boss": true,  "mix": true  }
]

var current_wave_index: int = 0
var remaining_to_spawn: int = 0
var spawning: bool = false
var boss_spawned: bool = false
var inter_wave_delay_seconds: float = 3.0

var battle_theme = load("res://audio/bgm/battle_theme.ogg")

func _ready() -> void:
	add_to_group("main")
	randomize()
	update_hp_display()
	score_label.text = "SCORE: %d" % score
	wave_timer.timeout.connect(_on_wave_timer_timeout)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	start_wave(current_wave_index)
	SoundManager.play_music(battle_theme)

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
	SoundManager.play_sfx("lose")
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
					if prompt.length() <= 3:
						SoundManager.play_sfx("projectile_correct")
					else:
						SoundManager.play_sfx("correct")
					add_score(100)
					current_letter_index = -1
					if active_enemy != null and active_enemy.has_method("die"):
						active_enemy.die()
					else:
						active_enemy.queue_free()
					active_enemy = null
					call_deferred("_check_wave_progress")
			else:
				print("gagal %s harusnya %s" % [key_typed, next_character])
				SoundManager.play_sfx("misstype")

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
	if game_state != GameState.PLAYING:
		spawn_timer.stop()
		spawning = false
		return

	if remaining_to_spawn > 0:
		_spawn_minion_for_current_wave()
		remaining_to_spawn -= 1
		print("   -> remaining_to_spawn now: %d" % remaining_to_spawn)
		_update_wave_label()

		if remaining_to_spawn <= 0:
			spawn_timer.stop()
			spawning = false
			print("All minions spawned for wave %d" % current_wave_index)
			call_deferred("_check_wave_progress")
	else:
		spawn_timer.stop()
		spawning = false

func spawn_enemy() -> void:
	if game_state != GameState.PLAYING:
		return

	var enemy_instance: Node2D

	#chance spawn
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
	
	SoundManager.play_sfx("enemy_projectile")

func start_wave(index: int) -> void:
	if index < 0 or index >= waves.size():
		return
	var cfg = waves[index]
	# pastikan set dari awal
	current_wave_index = index
	remaining_to_spawn = cfg.minion_count
	spawning = true
	boss_spawned = false

	print(">> start_wave: %s (index=%d) — will spawn %d | spawn_boss=%s | mix=%s" %
		[cfg.name, index, remaining_to_spawn, str(cfg.spawn_boss), str(cfg.mix)])

	# spawn boss segera jika perlu (boss + minions present)
	if cfg.spawn_boss:
		spawn_boss()
		boss_spawned = true

	# pastikan spawn_timer autostart tidak ganggu — start manual
	if not spawn_timer.is_stopped():
		spawn_timer.stop()
	spawn_timer.start()
	_update_wave_label()


func _spawn_minion_for_current_wave() -> void:
	var cfg = waves[current_wave_index]
	var enemy_instance: Node2D
	print("   -> spawning one minion for wave %d (mix=%s)" % [current_wave_index, str(cfg.mix)])
	# kalau mix true -> kesempatan jadi archer; else always basic
	if cfg.mix and (randi() % 3) == 0:
		enemy_instance = EnemyArcher.instantiate()
	else:
		enemy_instance = Enemy.instantiate()

	var spawns = spawn_container.get_children()
	if spawns.size() == 0:
		push_error("No spawn points found in SpawnContainer")
		return
	var idx = randi() % spawns.size()
	enemy_container.add_child(enemy_instance)
	enemy_instance.global_position = spawns[idx].global_position

	if enemy_instance.has_method("set_prompt"):
		enemy_instance.set_prompt(word_list.pick_random())
	print("      spawned: %s (%s) at spawn idx %d" % [enemy_instance.name, enemy_instance.get_class(), idx])

func spawn_boss() -> void:
	if game_state != GameState.PLAYING:
		return

	var boss_instance = EnemyBoss.instantiate()
	enemy_container.add_child(boss_instance)

	var spawns = spawn_container.get_children()
	var index = randi() % spawns.size()
	boss_instance.global_position = spawns[index].global_position

func _on_player_line_area_entered(area: Area2D) -> void:
	var obj = area.get_parent()
	if obj.is_in_group("enemy"):
		hp -= 1
		SoundManager.play_sfx("hit")
		if hp < 0:
			hp = 0
		update_hp_display()
		if obj == active_enemy:
			active_enemy = null
			current_letter_index = -1
		obj.queue_free()
		call_deferred("_check_wave_progress")
		if hp == 0:
			game_over()
		return
	if obj.is_in_group("projectile"):
		hp -= 1
		SoundManager.play_sfx("hit")
		if hp < 0:
			hp = 0
		update_hp_display()
		if obj == active_enemy:
			active_enemy = null
			current_letter_index = -1
		obj.queue_free()
		call_deferred("_check_wave_progress")
		if hp == 0:
			game_over()
		return

func show_win() -> void:
	game_state = GameState.GAME_OVER
	print("YOU WIN")
	SoundManager.play_sfx("win")
	spawn_timer.stop()
	wave_timer.stop()
	spawning = false
	for enemy in enemy_container.get_children():
		enemy.queue_free()
	for proj in projectile_container.get_children():
		proj.queue_free()
	gameover_label.text = "YOU WIN!\nKetik \"hidup lagi\" untuk bermain lagi"
	gameover_label.show()

func _update_wave_label() -> void:
	if wave_label == null:
		return

	# hitung alive dengan filter node yang belum queued_for_deletion
	var alive := 0
	var alive_names := []
	for c in enemy_container.get_children():
		# pastikan node valid dan belum dijadwalkan untuk dihapus
		if not c.is_queued_for_deletion():
			alive += 1
			alive_names.append("%s(%s)" % [c.name, c.get_class()])

	# juga periksa projectile secara terpisah (jika mau tampil total)
	var proj_alive := 0
	for p in projectile_container.get_children():
		if not p.is_queued_for_deletion():
			proj_alive += 1
			alive_names.append("%s(%s)" % [p.name, p.get_class()])

	var total_alive := alive + proj_alive
	var cfg_name = "-"
	if current_wave_index < waves.size():
		cfg_name = waves[current_wave_index].name
	wave_label.text = "%s | spawn left: %d | alive: %d" % [cfg_name, remaining_to_spawn, total_alive]
	print("--- WAVE DEBUG: %s — remaining %d — alive_total %d" % [cfg_name, remaining_to_spawn, total_alive])
	if alive_names.size() > 0:
		print("Children: ", alive_names)



func _check_wave_progress() -> void:
	# debug first
	print(">> _check_wave_progress() called. wave=%d | remaining_to_spawn=%d | spawning=%s" %
		[current_wave_index, remaining_to_spawn, str(spawning)])

	_update_wave_label()

	# pertama: jika masih ada yang harus di-spawn, jangan lanjut
	if remaining_to_spawn > 0:
		print("   -> still have remaining_to_spawn (%d), wait." % remaining_to_spawn)
		return

	# jika masih spawning (timer mungkin masih aktif), tunggu
	if spawning:
		print("   -> spawning flag true, wait.")
		return

	# hitung apakah ada enemy/projectile yang valid (belum queued_for_deletion)
	var any_enemy := false
	for c in enemy_container.get_children():
		if not c.is_queued_for_deletion() and not c.is_dead:
			any_enemy = true
			break

	if not any_enemy:
		for p in projectile_container.get_children():
			if not p.is_queued_for_deletion() :
				any_enemy = true
				break

	# jika masih ada entity hidup, tunggu
	if any_enemy:
		print("   -> there are still alive entities, wait.")
		return

	# kalau sampai sini: remaining_to_spawn == 0, spawning == false, dan tidak ada entity hidup
	print("   -> wave %d fully clear." % current_wave_index)

	if current_wave_index < waves.size() - 1:
		# gunakan deferred untuk aman
		call_deferred("_start_inter_wave_timer")
	else:
		call_deferred("show_win")

func _start_inter_wave_timer() -> void:
	wave_timer.start(inter_wave_delay_seconds)
	if wave_label:
		wave_label.text = "Wave complete — next in %ds" % int(inter_wave_delay_seconds)

func _on_wave_timer_timeout() -> void:
	print(">> WaveTimer timeout fired (current_wave_index=%d)" % current_wave_index)
	# safety: kalau game over / last wave -> ignore
	if game_state != GameState.PLAYING:
		return
	if current_wave_index >= waves.size() - 1:
		show_win()
		return

	current_wave_index += 1
	if current_wave_index < waves.size():
		start_wave(current_wave_index)
	else:
		show_win()

func reset_active_enemy():
	active_enemy = null
	current_letter_index = -1
