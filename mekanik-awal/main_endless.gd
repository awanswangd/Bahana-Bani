extends Node2D

var Enemy = preload("res://enemy.tscn")
var EnemyArcher = preload("res://enemy_archer.tscn")
var Projectile = preload("res://projectile.tscn")
var EnemyBoss = preload("res://enemy_boss.tscn")
var battle_theme = load("res://audio/bgm/battle_theme.ogg")

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
@onready var intro_timer: Timer = $IntroTimer
@onready var wave_intro_label: Label = $CanvasLayer/WaveIntroLabel

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

var base_minions_per_wave := 5          # jumlah musuh di awal wave 1
var minions_increment_per_wave := 1     # tiap wave nambah berapa musuh
var max_minions_per_wave := 25          # batas maksimal musuh per wave
var boss_wave_interval := 5             # tiap berapa wave muncul boss (0 = tidak pernah)
var enemy_speed_multiplier: float = 1.0   # multiplier awal (1x speed normal)
var enemy_speed_increment: float = 0.05   # nambah tiap 1 musuh mati (5%)
var total_kills: int = 0                  # cuma buat debug / info

func register_enemy_kill() -> void:
	total_kills += 1
	enemy_speed_multiplier += enemy_speed_increment
	print("Kill %d -> enemy_speed_multiplier = %.2f" % [total_kills, enemy_speed_multiplier])

func get_enemy_speed_multiplier() -> float:
	return enemy_speed_multiplier

func get_wave_config(index: int) -> Dictionary:
	var wave_number := index + 1

	var minions := base_minions_per_wave + minions_increment_per_wave * index
	minions = min(minions, max_minions_per_wave)

	var mix := wave_number >= 2
	var spawn_boss := false
	if boss_wave_interval > 0 and wave_number % boss_wave_interval == 0:
		spawn_boss = true

	return {
		"name": "Wave %d" % wave_number,
		"minion_count": minions,
		"mix": mix,
		"spawn_boss": spawn_boss
	}

var current_wave_index: int = 0
var remaining_to_spawn: int = 0
var spawning: bool = false
var boss_spawned: bool = false
var inter_wave_delay_seconds: float = 3.0
var wave_intro_duration: float = 1.5
var wave_countdown: int = 0


func _ready() -> void:
	add_to_group("main")
	randomize()
	update_hp_display()
	score_label.text = "SCORE: %d" % score

	if not wave_timer.timeout.is_connected(_on_wave_timer_timeout):
		wave_timer.timeout.connect(_on_wave_timer_timeout)

	if not spawn_timer.timeout.is_connected(_on_spawn_timer_timeout):
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)

	if intro_timer:
		intro_timer.timeout.connect(_on_intro_timer_timeout)
	else:
		pass

	if wave_intro_label:
		wave_intro_label.hide()

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
	SoundManager.stop_music()
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
		if "is_dead" in enemy and enemy.is_dead:
			continue
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
					var was_enemy := false
					if active_enemy != null and active_enemy.is_in_group("enemy"):
						was_enemy = true
					# BOSS pakai multi-phase
					if active_enemy != null and active_enemy.is_in_group("boss") and active_enemy.has_method("on_word_completed"):
						active_enemy.on_word_completed()
					else:
						# musuh biasa / projectile
						if active_enemy != null and active_enemy.has_method("die"):
							active_enemy.die()
						else:
							active_enemy.queue_free()
					if was_enemy:
						register_enemy_kill()  # termasuk boss phase juga, kalau kamu oke
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
	if index < 0:
		return

	var cfg = get_wave_config(index)

	current_wave_index = index
	remaining_to_spawn = cfg.minion_count
	spawning = false
	boss_spawned = false

	print(">> start_wave: %s (index=%d) — minions=%d | spawn_boss=%s | mix=%s (spawning will begin after intro)" %
		[cfg.name, index, remaining_to_spawn, str(cfg.spawn_boss), str(cfg.mix)])

	if not spawn_timer.is_stopped():
		spawn_timer.stop()

	_update_wave_label()
	_show_wave_intro(index)

func _show_wave_intro(index: int) -> void:
	if wave_intro_label:
		var cfg = get_wave_config(index)
		wave_intro_label.text = cfg.name
		wave_intro_label.show()

	intro_timer.start(wave_intro_duration)


func _on_intro_timer_timeout() -> void:
	# sembunyikan label intro
	if wave_intro_label:
		wave_intro_label.hide()

	# kalau game sudah game over, jangan mulai wave
	if game_state != GameState.PLAYING:
		return

	# mulai spawning untuk wave aktif
	var cfg = get_wave_config(current_wave_index)
	spawning = true
	remaining_to_spawn = cfg.minion_count

	print(">> Intro selesai, mulai spawn wave %d (minions=%d, spawn_boss=%s, mix=%s)" %
		[current_wave_index, remaining_to_spawn, str(cfg.spawn_boss), str(cfg.mix)])

	if cfg.spawn_boss and not boss_spawned:
		spawn_boss()
		boss_spawned = true

	if not spawn_timer.is_stopped():
		spawn_timer.stop()
	spawn_timer.start()

	_update_wave_label()

func _spawn_minion_for_current_wave() -> void:
	var cfg = get_wave_config(current_wave_index)
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
	if game_state != GameState.PLAYING:
		return
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
		register_enemy_kill() 
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
	# Story 1: semua wave sudah clear, lanjut ke Story 2 (cutscene)
	print("STORY 1 CLEAR — go to Story 2 cutscene")
	SoundManager.stop_music()
	SoundManager.play_sfx("win")

	game_state = GameState.GAME_OVER
	spawn_timer.stop()
	wave_timer.stop()
	spawning = false

	for enemy in enemy_container.get_children():
		enemy.queue_free()
	for proj in projectile_container.get_children():
		proj.queue_free()

	# langsung ganti scene ke cutscene Story 2
	Transition.change_scene_to_file("res://cutscene_story_2.tscn")

func _update_wave_label() -> void:
	if wave_label == null:
		return

	var enemy_alive := 0
	var proj_alive := 0
	var debug_lines: Array[String] = []

	# HITUNG ENEMY ALIVE: belum queued_free DAN belum is_dead
	for c in enemy_container.get_children():
		var queued := c.is_queued_for_deletion()
		var dead := false
		if "is_dead" in c:
			dead = c.is_dead

		if not queued and not dead:
			enemy_alive += 1

		debug_lines.append("ENEMY %s (%s) queued=%s is_dead=%s" %
			[c.name, c.get_class(), str(queued), str(dead)])

	# HITUNG PROJECTILE (mereka tidak punya is_dead, cukup queued)
	for p in projectile_container.get_children():
		var queuedp := p.is_queued_for_deletion()
		if not queuedp:
			proj_alive += 1

		debug_lines.append("PROJ  %s (%s) queued=%s" %
			[p.name, p.get_class(), str(queuedp)])

	var total_alive := enemy_alive + proj_alive
	var cfg_name := "-"
	if current_wave_index >= 0:
		var cfg = get_wave_config(current_wave_index)
		cfg_name = cfg.name

	wave_label.text = "%s | spawn left: %d | alive: %d" % [
		cfg_name, remaining_to_spawn, total_alive
	]

	print("--- WAVE DEBUG: %s — remaining %d — alive_total %d" %
		[cfg_name, remaining_to_spawn, total_alive])

	for line in debug_lines:
		print(line)


func _check_wave_progress() -> void:
	print(">> _check_wave_progress() called. wave=%d | remaining_to_spawn=%d | spawning=%s" %
		[current_wave_index, remaining_to_spawn, str(spawning)])

	_update_wave_label()

	# 1. Kalau masih ada yang harus di-spawn, jangan lanjut
	if remaining_to_spawn > 0:
		print("   -> still have remaining_to_spawn (%d), wait." % remaining_to_spawn)
		return

	# 2. Kalau masih flag spawning true, berarti spawn_timer masih kerja
	if spawning:
		print("   -> spawning flag true, wait.")
		return

	# 3. Cek apakah masih ada entity hidup
	var any_alive := false

	#   3a. Cek enemy
	for c in enemy_container.get_children():
		var queued := c.is_queued_for_deletion()
		var dead := false
		if "is_dead" in c:
			dead = c.is_dead
		if not queued and not dead:
			any_alive = true
			break

	#   3b. Kalau enemy sudah habis, cek projectile
	if not any_alive:
		for p in projectile_container.get_children():
			if not p.is_queued_for_deletion():
				any_alive = true
				break

	if any_alive:
		print("   -> there are still alive entities, wait.")
		return

	# 4. Sampai sini: tidak ada yang hidup lagi
	print("   -> wave %d fully clear." % current_wave_index)
	call_deferred("_start_inter_wave_timer")


func _start_inter_wave_timer() -> void:
	print(">> _start_inter_wave_timer() called. Setting countdown = %f seconds" % inter_wave_delay_seconds)

	if game_state != GameState.PLAYING:
		print("   -> game_state bukan PLAYING, batal mulai inter-wave timer.")
		return

	# inisialisasi countdown
	wave_countdown = int(inter_wave_delay_seconds)
	if wave_countdown <= 0:
		wave_countdown = 1

	# set WaveTimer menjadi timer 1 detik berulang
	if wave_timer:
		wave_timer.stop()
		wave_timer.wait_time = 1.0
		wave_timer.one_shot = false
		wave_timer.start()
		print("   -> WaveTimer started for countdown, wait_time=1, one_shot=false")
	else:
		print("   !! wave_timer is NULL, tidak bisa start countdown !!")

	if wave_label:
		wave_label.text = "Wave complete — next in %ds" % wave_countdown

func _on_wave_timer_timeout() -> void:
	print(">> WaveTimer TIMEOUT (countdown) fired. current_wave_index=%d, wave_countdown=%d" %
		[current_wave_index, wave_countdown])

	if game_state != GameState.PLAYING:
		print("   -> game_state=%s, stop WaveTimer." % str(game_state))
		wave_timer.stop()
		return

	# turunkan countdown
	wave_countdown -= 1

	# kalau masih ada sisa detik, update label dan tunggu tick berikutnya
	if wave_countdown > 0:
		if wave_label:
			wave_label.text = "Wave complete — next in %ds" % wave_countdown
		print("   -> countdown now %d, wait next tick." % wave_countdown)
		return

	# countdown habis
	print("   -> countdown finished, stop WaveTimer and start next wave.")
	wave_timer.stop()

	current_wave_index += 1
	print("   -> Moving to next wave: %d" % current_wave_index)

	start_wave(current_wave_index)

func reset_active_enemy():
	active_enemy = null
	current_letter_index = -1
