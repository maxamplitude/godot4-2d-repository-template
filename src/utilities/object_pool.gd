class_name ObjectPool extends Node

@export var pool_size := 20
@export var prefab: PackedScene

var pool: Array[Node] = []
var active_objects: Array[Node] = []

func get_object() -> Node:
	for obj in pool:
		if not obj.is_inside_tree():
			return obj
	# Pool exhausted, create new
	var new_obj = prefab.instantiate()
	pool.append(new_obj)
	return new_obj
