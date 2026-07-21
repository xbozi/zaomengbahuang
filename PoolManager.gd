extends Node

const DEFAULT_MAX_POOL_SIZE := 64

var pools: Dictionary = {}
var scene_cache: Dictionary = {}

func get_scene(scene_path: String) -> PackedScene:
	if not scene_cache.has(scene_path):
		scene_cache[scene_path] = load(scene_path)
	return scene_cache[scene_path]

func create_pool(scene_path: String, initial_size: int) -> void:
	if not pools.has(scene_path):
		pools[scene_path] = []
	var scene := get_scene(scene_path)
	var need_create = max(initial_size - pools[scene_path].size(), 0)
	for _i in range(need_create):
		var instance := scene.instantiate()
		instance.name = "PooledInstance"
		if instance.has_method("reset_for_pool"):
			instance.reset_for_pool()
		if instance.has_method("hide"):
			instance.hide()
		instance.set_process(false)
		instance.set_physics_process(false)
		pools[scene_path].append(instance)

func get_instance(scene_path: String) -> Node:
	if not pools.has(scene_path):
		pools[scene_path] = []
	var instance: Node
	if pools[scene_path].size() > 0:
		instance = pools[scene_path].pop_back()
	else:
		instance = get_scene(scene_path).instantiate()
	if instance.has_method("show"):
		instance.show()
	instance.set_process(true)
	instance.set_physics_process(true)
	return instance

func discard_instance(instance: Node) -> void:
	if instance.get_parent() != null:
		instance.get_parent().remove_child(instance)
	instance.queue_free()

func recycle_instance(scene_path: String, instance: Node) -> void:
	if instance == null or not is_instance_valid(instance):
		return
	if not pools.has(scene_path):
		pools[scene_path] = []
	if pools[scene_path].size() >= DEFAULT_MAX_POOL_SIZE:
		discard_instance(instance)
		return
	if instance.has_method("reset_for_pool"):
		instance.reset_for_pool()
	if instance.get_parent() != null:
		instance.get_parent().remove_child(instance)
	if instance.has_method("hide"):
		instance.hide()
	instance.set_process(false)
	instance.set_physics_process(false)
	pools[scene_path].append(instance)
