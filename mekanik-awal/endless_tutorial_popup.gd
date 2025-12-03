extends Panel

signal tutorial_finished

@onready var tut_img = $Container/TutorialImage
@onready var tut_msg = $Container/Message
@onready var next_btn = $Next_bttn
@onready var prev_btn = $Prev_bttn
@onready var close_btn = $Close_bttn

var current_index: int = 0

var pages = [
	{
		"text": "Di Endless Mode, Speed Musuh Selalu Meningkat\nSetiap Kali Musuh Dibunuh.",
		"image": preload("res://EnemySpeed.png")
	},
	{
		"text": "Ketik kata di atas kepala musuh!",
		"image": preload("res://enemybiasa.png")
	},
	{
		"text": "*Targeting System*\nMusuh yang diketik akan punya Outline Merah!",
		"image": preload("res://outline.png")
	},
	{
		"text": "Musuh pemanah menambakkan pemanah, hati hati!",
		"image": preload("res://enemyarcher.png")
	},
	{
		"text": "*Hati-hati Boss!*\nDia punya 3 fase serangan.",
		"image": preload("res://enemyboss.jpeg")
	},
	{
		"text": "Selamat Bermain :)",
		"image": null 
	},
]

func _ready():
	update_ui()

func update_ui():
	var data = pages[current_index]
	
	tut_msg.text = data["text"]
	if data["image"]:
		tut_img.texture = data["image"]
		tut_img.show()
	else:
		tut_img.hide() 

	if current_index == 0:
		prev_btn.disabled = true
	else:
		prev_btn.disabled = false

func _on_next_bttn_pressed():
	if current_index < pages.size() - 1:
		current_index += 1
		update_ui()
	else:
		tutup_tutorial()

func _on_prev_bttn_pressed():
	if current_index > 0:
		current_index -= 1
		update_ui()

func _on_close_bttn_pressed():
	tutup_tutorial()

func tutup_tutorial():
	hide() 
	emit_signal("tutorial_finished") 
