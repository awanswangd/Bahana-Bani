extends Node2D

@export var blue: Color = Color("#4682b4")
@export var green: Color = Color("#FFFFFF")
@export var red: Color = Color("#FFFFFF")
@export var speed: float = 1
@onready var prompt = $RichTextLabel
@onready var sprite = $AnimatedSprite2D
@export var is_dead: bool = false
var is_animating_death: bool = false



func _ready() -> void:
	add_to_group("enemy")

func _physics_process(delta):
	if is_dead:
		return

	global_position.x -= speed
	if not sprite.is_playing():
		sprite.play("flight")

func get_prompt() -> String:
	return prompt.text

func set_prompt(text: String) -> void:
	prompt.text = text

func set_next_character(next_character_index: int):
	var blue_text = get_bbcode_color_tag(blue) + prompt.text.substr(0, next_character_index) + get_bbcode_end_color_tag()
	var green_text = get_bbcode_color_tag(green) + prompt.text.substr(next_character_index,1 ) + get_bbcode_end_color_tag()
	var red_text = ""
	
	if next_character_index != prompt.text.length():
		red_text = get_bbcode_color_tag(red) + prompt.text.substr(next_character_index + 1, prompt.text.length() - next_character_index + 1) + get_bbcode_end_color_tag()

	prompt.parse_bbcode(blue_text + green_text + red_text)

func get_bbcode_color_tag(color: Color) -> String:
	return "[color=#" + color.to_html(false) + "]"

func get_bbcode_end_color_tag() -> String:
	return "[/color]"

func die():
	is_dead = true
	$AnimatedSprite2D.play("death")
	await $AnimatedSprite2D.animation_finished
	var main = get_tree().get_first_node_in_group("main")
	if main and main.active_enemy == self:
		main.reset_active_enemy()
	queue_free()
