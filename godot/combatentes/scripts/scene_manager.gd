# scene_manager.gd
extends Node

var current_scene: Node = null

func _ready():
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)

func change_scene(scene_path: String):
	# Adia a troca de cena para o final do frame atual
	call_deferred("_deferred_change_scene", scene_path)

func _deferred_change_scene(scene_path: String):
	# Libera a cena atual
	if current_scene != null:
		current_scene.free()

	# Carrega a nova cena
	var next_scene_res = load(scene_path)
	if next_scene_res == null:
		print_error("Falha ao carregar a cena: " + scene_path)
		return

	# Instancia e define a nova cena como atual
	current_scene = next_scene_res.instantiate()
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene
