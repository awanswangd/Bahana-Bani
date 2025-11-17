extends Node2D

@export var max_hp: int = 5
var hp: int

func _ready() -> void:
	hp = max_hp

func take_damage(amount: int):
	hp -= amount
	if hp < 0:
		hp = 0

	print("Player HP:", hp)
	if has_animation():
		$AnimationPlayer.play("hurt")

func has_animation() -> bool:
	return $AnimationPlayer.has_animation("hurt")
