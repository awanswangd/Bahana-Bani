extends Node2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var max_hp: int = 5
var hp: int

func _ready() -> void:
	hp = max_hp
	sprite.play("idle")
func take_damage(amount: int):
	hp -= amount
	if hp < 0:
		hp = 0
	print("Player HP:", hp)
	
	if hp == 0:
		die()
	else:
		if "hurt" in sprite.sprite_frames.get_animation_names():
			sprite.play("hurt")
			await sprite.animation_finished
			sprite.play("idle")  

func has_animation() -> bool:
	return $AnimationPlayer.has_animation("hurt")
func die() -> void:
	print("PLAYER DEAD")
