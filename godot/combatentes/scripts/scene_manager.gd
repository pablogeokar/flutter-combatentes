# scene_manager.gd
extends Node

var current_scene: Node = null

func _ready():
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)

func change_scene(scene_path: String):
	print("🎬 SCENE_MANAGER - Solicitação de mudança de cena para: ", scene_path)
	# Adia a troca de cena para o final do frame atual
	call_deferred("_deferred_change_scene", scene_path)

func _deferred_change_scene(scene_path: String):
	print("🎬 SCENE_MANAGER - Executando mudança de cena para: ", scene_path)
	
	# Libera a cena atual
	if current_scene != null:
		print("🎬 SCENE_MANAGER - Liberando cena atual: ", current_scene.name)
		current_scene.free()
	else:
		print("🎬 SCENE_MANAGER - Nenhuma cena atual para liberar")

	# Carrega a nova cena
	print("🎬 SCENE_MANAGER - Carregando nova cena...")
	var next_scene_res = load(scene_path)
	if next_scene_res == null:
		print("❌ SCENE_MANAGER - ERRO: Falha ao carregar a cena: " + scene_path)
		return

	# Instancia e define a nova cena como atual
	print("🎬 SCENE_MANAGER - Instanciando nova cena...")
	current_scene = next_scene_res.instantiate()
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene
	print("✅ SCENE_MANAGER - Cena alterada com sucesso para: ", current_scene.name)
