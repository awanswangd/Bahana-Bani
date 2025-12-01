extends Node2D

@export var blue: Color = Color("#4682b4")
@export var green: Color = Color("#FFFFFF")
@export var red: Color = Color("#FFFFFF")
@export var is_dead: bool = false
var is_animating_death: bool = false
@onready var sprite = $AnimatedSprite2D
@export var speed: float = 1
@export var words: Array[String] = [
	"aku bossnya",
	"ini testing",
	"serangan terakhir"
]

@onready var prompt: RichTextLabel = $RichTextLabel
@onready var phase_timer: Timer = $PhaseTimer

var is_phase_wait: bool = false
var current_word_index: int = 0
var i = 1

func _ready() -> void:
	add_to_group("enemy")  
	add_to_group("boss")   

	phase_timer.timeout.connect(_on_phase_timer_timeout)

	_show_current_word()

func _physics_process(delta):
	if is_dead:
		return

	if is_phase_wait:
		if sprite.is_playing():
			sprite.stop()
		return

	var final_speed := speed

	# cari node "main" (bisa main.gd atau main_endless.gd)
	var main = get_tree().get_first_node_in_group("main")
	if main and main.has_method("get_enemy_speed_multiplier"):
		final_speed *= main.get_enemy_speed_multiplier()

	global_position.x -= final_speed
	if not sprite.is_playing():
		sprite.play("flight")

func _show_current_word() -> void:
	if current_word_index < words.size():
		prompt.text = words[current_word_index]
	else:
		prompt.text = ""

func get_prompt() -> String:
	return prompt.text

func set_prompt(text: String) -> void:
	prompt.text = text

func set_next_character(next_character_index: int) -> void:
	var text := prompt.text

	var blue_text = get_bbcode_color_tag(blue) + text.substr(0, next_character_index) + get_bbcode_end_color_tag()
	var green_text = ""
	var red_text = ""

	if next_character_index < text.length():
		green_text = get_bbcode_color_tag(green) + text.substr(next_character_index, 1) + get_bbcode_end_color_tag()

	if next_character_index + 1 < text.length():
		red_text = get_bbcode_color_tag(red) + text.substr(next_character_index + 1) + get_bbcode_end_color_tag()

	prompt.parse_bbcode(blue_text + green_text + red_text)

func get_bbcode_color_tag(color: Color) -> String:
	return "[color=#" + color.to_html(false) + "]"

func get_bbcode_end_color_tag() -> String:
	return "[/color]"

func on_word_completed() -> void:
	current_word_index += 1
	i = 0

	if current_word_index >= words.size():
		print("Boss defeated!")
		die()
	else:
		print("Boss phase %d complete, waiting 3s..." % current_word_index)
		prompt.text = ""
		is_phase_wait = true
		phase_timer.start()

func _on_phase_timer_timeout() -> void:
	_show_current_word()
	i = current_word_index
	is_phase_wait = false  

func die():
	is_dead = true
	$AnimatedSprite2D.play("death")
	await $AnimatedSprite2D.animation_finished
	var main = get_tree().get_first_node_in_group("main")
	if main and main.active_enemy == self:
		main.reset_active_enemy()
	queue_free()
