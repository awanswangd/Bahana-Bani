extends Node2D

var Enemy = preload("res://enemy.tscn")
var EnemyArcher = preload("res://enemy_archer.tscn")
var Projectile = preload("res://projectile.tscn")
var EnemyBoss = preload("res://enemy_boss.tscn")
var battle_theme = load("res://audio/bgm/battle_theme.ogg")

var score: int = 0
enum GameState { PLAYING, GAME_OVER }
var game_state: GameState = GameState.PLAYING
var restart_phrase := "hidup"
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
@onready var pause_menu = $PauseMenu
@onready var tutorial_popup = $Notification

var active_enemy = null
var current_letter_index: int = -1

var word_list = [
	"temambugh","berondok","paten","bedangkik","dapoek",
	"kaghai","langgar","aluang","andung","lebung",
	"kumbang","balubua","jombang","lengong","tekuyung",
	"pedom","Mandeh","nyanyang","santing","tingkap",
	"lapah","sejemang","sipangkalan","dulang","ngadat",
	"ghatong","baladas","pongkang","belange","jemuah",
	"lengong","pening","gampong","nganyak","ngeladang",
	"ghuccah","mangcek","betumbuk","bicek","busung",
	"tebengbang","galo","mahu","makon","ngaro",
	"jingok","pacak","cindo","beungeh","sonang",
	"lapau","bahempang","pinggan","Kaspin","cawan","nyabit",
]
var projectile_words = [
	"po", "pi", "pow", "zap", "hit", "wid", "xo",
	"bam", "dor", "boom", "zip", "duar", "tic", "toc",
	"hey", "run", "cut", "tap", "top", "tip", "fix",
	"zig", "zag", "fox", "no", "go", "up", "ha", "hi",
	"woy", "gas", "los", "yep", "noh", "bom"
]

var waves = [
	{ "name":"Wave 1", "minion_count":5, "spawn_boss": false, "mix": false },
	{ "name":"Wave 2", "minion_count":5, "spawn_boss": false, "mix": true  },
	{ "name":"Wave 3", "minion_count":10, "spawn_boss": true,  "mix": true  }
]

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
	SoundManager.play_music(battle_theme)
	if wave_intro_label:
		wave_intro_label.hide()
	
	get_tree().paused = true
	
	if tutorial_popup:
		tutorial_popup.show()
		if not tutorial_popup.tutorial_finished.is_connected(_on_tutorial_finished):
			tutorial_popup.tutorial_finished.connect(_on_tutorial_finished)
	else:
		_on_tutorial_finished()

func _on_tutorial_finished():
	print("Tutorial Selesai -> Game Dimulai!")
	get_tree().paused = false 
	start_wave(current_wave_index)

func game_over() -> void:
	game_state = GameState.GAME_OVER
	print("GAME OVER")
	SoundManager.stop_music()
	SoundManager.play_sfx("lose")
	spawn_timer.stop()
	for enemy in enemy_container.get_children():
		enemy.queue_free()
	var go_label = $CanvasLayer/GameOverLabel
	go_label.text = "GAME OVER\nKetik \"'hidup'\" untuk bermain lagi"
	go_label.show()

func add_score(amount: int):
	score += amount
	score_label.text = "SCORE: %d" % score

func update_hp_display() -> void:
	if player:
		hp_label.text = "HP: %d" % player.hp

func find_new_active_enemy(typed_character: String):
	print("Searching for enemy starting with: '%s'" % typed_character)
	
	for projectile in projectile_container.get_children():
		var prompt = projectile.get_prompt()
		var next_character = prompt.substr(0, 1).to_lower()
		if next_character == typed_character:
			if active_enemy and active_enemy.has_method("set_targeted"):
				active_enemy.set_targeted(false)
			active_enemy = projectile
			if active_enemy.has_method("set_targeted"):
				active_enemy.set_targeted(true) 
			if player.has_method("play_attack"):
				player.play_attack()
			if active_enemy.has_method("set_targeted"):
				active_enemy.set_targeted(true)
			current_letter_index = 1
			active_enemy.set_next_character(current_letter_index)
			return
	for enemy in enemy_container.get_children():
		if "is_dead" in enemy and enemy.is_dead:
			continue
		var prompt = enemy.get_prompt()
		var next_character = prompt.substr(0, 1).to_lower()
		if next_character == typed_character:
			if active_enemy and active_enemy.has_method("set_targeted"):
				active_enemy.set_targeted(false)
			SoundManager.play_sfx("typing")
			active_enemy = enemy
			if active_enemy.has_method("set_targeted"):
				active_enemy.set_targeted(true) 
			if player.has_method("play_attack"):
				player.play_attack()
			current_letter_index = 1
			active_enemy.set_next_character(current_letter_index)
			return

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_ESCAPE:
			if game_state != GameState.GAME_OVER:
				_toggle_pause()
			return
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
				SoundManager.play_sfx("typing")
				if player.has_method("play_attack"):
					player.play_attack()
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
					if active_enemy != null and active_enemy.is_in_group("boss") and active_enemy.has_method("on_word_completed"):
						active_enemy.on_word_completed()
					else:
						# musuh biasa / projectile
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

	# set status wave
	current_wave_index = index
	remaining_to_spawn = cfg.minion_count
	spawning = false
	boss_spawned = false

	print(">> start_wave: %s (index=%d) — minions=%d | spawn_boss=%s | mix=%s (spawning will begin after intro)" %
		[cfg.name, index, remaining_to_spawn, str(cfg.spawn_boss), str(cfg.mix)])

	# pastikan spawn_timer nggak jalan dulu
	if not spawn_timer.is_stopped():
		spawn_timer.stop()

	_update_wave_label()
	_show_wave_intro(index)

func _show_wave_intro(index: int) -> void:
	if wave_intro_label:
		var cfg_name = waves[index].name if index < waves.size() else "Wave ?"
		wave_intro_label.text = cfg_name
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
	var cfg = waves[current_wave_index]
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
	if game_state != GameState.PLAYING:
		return
	var obj = area.get_parent()
	
	if obj.is_in_group("enemy") or obj.is_in_group("projectile"):
		if player.has_method("take_damage"):
			player.take_damage(1)
		if player.hp > 0: 
			SoundManager.play_sfx("hit")
		else:
			pass
		update_hp_display()

		if obj == active_enemy:
			reset_active_enemy()
		obj.queue_free()
		call_deferred("_check_wave_progress")
		if player.hp <= 0:
			game_over()
		return

func show_win() -> void:
	# Story 1: semua wave sudah clear, lanjut ke Story 2
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

	Transition.change_scene_to_file("res://main2.tscn")

func _update_wave_label() -> void:
	if wave_label == null:
		return

	var enemy_alive := 0
	var proj_alive := 0
	var debug_lines: Array[String] = []

	for c in enemy_container.get_children():
		var queued := c.is_queued_for_deletion()
		var dead := false
		if "is_dead" in c:
			dead = c.is_dead

		if not queued and not dead:
			enemy_alive += 1

		debug_lines.append("ENEMY %s (%s) queued=%s is_dead=%s" %
			[c.name, c.get_class(), str(queued), str(dead)])

	for p in projectile_container.get_children():
		var queuedp := p.is_queued_for_deletion()
		if not queuedp:
			proj_alive += 1

		debug_lines.append("PROJ  %s (%s) queued=%s" %
			[p.name, p.get_class(), str(queuedp)])

	var total_alive := enemy_alive + proj_alive
	var cfg_name = "-"
	if current_wave_index < waves.size():
		cfg_name = waves[current_wave_index].name

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

	if current_wave_index < waves.size() - 1:
		call_deferred("_start_inter_wave_timer")
	else:
		call_deferred("show_win")


func _start_inter_wave_timer() -> void:
	print(">> _start_inter_wave_timer() called. Setting countdown = %f seconds" % inter_wave_delay_seconds)

	if game_state != GameState.PLAYING:
		print("   -> game_state bukan PLAYING, batal mulai inter-wave timer.")
		return

	if current_wave_index >= waves.size() - 1:
		print("   -> sudah di wave terakhir, langsung show_win()")
		show_win()
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

	wave_countdown -= 1

	if wave_countdown > 0:
		if wave_label:
			wave_label.text = "Wave complete — next in %ds" % wave_countdown
		print("   -> countdown now %d, wait next tick." % wave_countdown)
		return

	# countdown habis
	print("   -> countdown finished, stop WaveTimer and start next wave.")
	wave_timer.stop()

	# safety: cek lagi indeks wave
	if current_wave_index >= waves.size() - 1:
		print("   -> sudah di wave terakhir, panggil show_win()")
		show_win()
		return

	current_wave_index += 1
	print("   -> Moving to next wave: %d" % current_wave_index)

	if current_wave_index < waves.size():
		start_wave(current_wave_index)
	else:
		print("   -> index out of range setelah increment, panggil show_win() sebagai fallback.")
		show_win()

func reset_active_enemy():
	if active_enemy and is_instance_valid(active_enemy) and active_enemy.has_method("set_targeted"):
		active_enemy.set_targeted(false)
	active_enemy = null
	current_letter_index = -1
	if player and player.has_method("play_idle"):
		player.play_idle()

func _toggle_pause() -> void:
	if get_tree().paused:
		get_tree().paused = false
		if pause_menu:
			pause_menu.hide_pause()
	else:
		get_tree().paused = true
		SoundManager.stop_music()
		if pause_menu:
			pause_menu.show_pause()
