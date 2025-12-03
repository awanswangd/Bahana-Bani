extends Node2D

@export var blue: Color = Color("#4682b4")
@export var green: Color = Color("#FFFFFF")
@export var red: Color = Color("#FFFFFF")
@export var is_dead: bool = false
@export var speed: float = 1.0
@export var words: Array[String] = [
	"aku bossnya",
	"ini testing",
	"serangan terakhir"
]

@onready var sprite = $AnimatedSprite2D
@onready var prompt: RichTextLabel = $RichTextLabel
@onready var phase_timer: Timer = $PhaseTimer

var is_targeted: bool = false
var is_phase_wait: bool = false 
var current_word_index: int = 0

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("boss")

	if not phase_timer.timeout.is_connected(_on_phase_timer_timeout):
		phase_timer.timeout.connect(_on_phase_timer_timeout)

	if sprite.material:
		sprite.material = sprite.material.duplicate()

	_show_current_word()

func _physics_process(delta):
	if is_dead or is_phase_wait:
		return

	var final_speed := speed
	var main = get_tree().get_first_node_in_group("main")
	if main and main.has_method("get_enemy_speed_multiplier"):
		final_speed *= main.get_enemy_speed_multiplier()

	global_position.x -= final_speed
	
	if sprite.animation != "flight":
		sprite.play("flight")

func on_word_completed() -> void:
	current_word_index += 1

	if current_word_index >= words.size():
		print("Boss defeated!")
		die()
	else:
		print("Boss phase %d complete, playing HURT then IDLE..." % current_word_index)
		set_targeted(false)
		is_phase_wait = true
		prompt.text = "" 
		
		sprite.play("hurt")
		
		await sprite.animation_finished
		
		if not is_dead:
			sprite.play("idle")
			phase_timer.start() 

func _on_phase_timer_timeout() -> void:
	_show_current_word()
	is_phase_wait = false 
	

func _show_current_word() -> void:
	if current_word_index < words.size():
		prompt.text = words[current_word_index]
	else:
		prompt.text = ""

func set_targeted(value: bool) -> void:
	is_targeted = value
	if sprite.material:
		if value:
			sprite.material.set_shader_parameter("line_thickness", 10.0)
		else:
			sprite.material.set_shader_parameter("line_thickness", 0.0)

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

func die():
	is_dead = true
	phase_timer.stop() 
	
	$AnimatedSprite2D.play("death")
	await $AnimatedSprite2D.animation_finished
	
	var main = get_tree().get_first_node_in_group("main")
	if main and main.active_enemy == self:
		main.reset_active_enemy()
	queue_free()
