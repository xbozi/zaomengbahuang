# PoolManager.gd
extends Node

var pools = {}
var scene_cache = {}

func create_pool(scene_path: String, initial_size: int):
	if not pools.has(scene_path):
		pools[scene_path] = []
	var scene = _get_scene(scene_path)
	var need_count = max(initial_size - pools[scene_path].size(), 0)
	for i in range(need_count):
		var instance = scene.instantiate()
		_prepare_new_pooled_instance(instance)
		pools[scene_path].append(instance)

func get_instance(scene_path: String) -> Node:
	if pools.has(scene_path) and pools[scene_path].size() > 0:
		var instance = pools[scene_path].pop_back()
		instance.set_meta("_from_pool",true)
		_prepare_for_use(instance)
		return instance
	var scene = _get_scene(scene_path)
	var instance = scene.instantiate()
	instance.set_meta("_from_pool",false)
	_prepare_for_use(instance)
	return instance

func recycle_instance(scene_path: String, instance: Node):
	if instance == null or not is_instance_valid(instance):
		return
	if not pools.has(scene_path):
		pools[scene_path] = []
	if instance.get_parent() != null:
		instance.get_parent().remove_child(instance)
	_prepare_for_pool(instance)
	pools[scene_path].append(instance)

func _get_scene(scene_path: String) -> PackedScene:
	if not scene_cache.has(scene_path):
		scene_cache[scene_path] = load(scene_path)
	return scene_cache[scene_path]

func _prepare_for_use(instance: Node):
	instance.process_mode = Node.PROCESS_MODE_INHERIT
	if instance is CanvasItem:
		instance.visible = true

func _prepare_new_pooled_instance(instance: Node):
	if instance is CanvasItem:
		instance.visible = false
	instance.process_mode = Node.PROCESS_MODE_DISABLED

func _prepare_for_pool(instance: Node):
	if instance.has_method("reset_for_pool"):
		instance.reset_for_pool()
	if instance is CanvasItem:
		instance.visible = false
	instance.process_mode = Node.PROCESS_MODE_DISABLED