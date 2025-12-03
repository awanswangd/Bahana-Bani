extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var max_hp: int = 5
var hp: int
var is_dead: bool = false
var is_attacking: bool = false 

func _ready() -> void:
	hp = max_hp
	play_idle()

func play_idle() -> void:
	if is_dead: return
	is_attacking = false
	if sprite.animation != "idle" and sprite.animation != "hurt":
		sprite.play("idle")

func play_attack() -> void:
	if is_dead: return
	is_attacking = true
	if sprite.animation != "attack" and sprite.animation != "hurt":
		sprite.play("attack")

func take_damage(amount: int):
	if is_dead: return
	
	hp -= amount
	if hp < 0:
		hp = 0
	
	print("Player HP:", hp)
	
	if hp == 0:
		die()
	else:
		sprite.play("hurt")
		await sprite.animation_finished
		if is_dead: return
		if is_attacking:
			sprite.play("attack")
		else:
			sprite.play("idle")

func die() -> void:
	is_dead = true
	sprite.play("death")
