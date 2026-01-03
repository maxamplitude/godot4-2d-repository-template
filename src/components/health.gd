# Generic health component
class_name HealthComponent extends Node

signal health_changed(current, max_health)
signal died

@export var max_health := 100.0
var current_health: float

func _ready():
	current_health = max_health

func take_damage(amount: float):
	current_health -= amount
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		died.emit()

# src/components/hitbox_component.gd
class_name HitboxComponent extends Area2D
# Deals damage to hurtboxes

# src/components/hurtbox_component.gd  
class_name HurtboxComponent extends Area2D
# Receives damage from hitboxes
signal hit_received(damage: float, hitbox: HitboxComponent)
