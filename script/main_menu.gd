extends Control

#le probleme viens d'ici
func _on_button_button_down() -> void:
	# Ajouter la scène de chargement par-dessus
	var chargement = load("res://scene/scene en plus/menu_chargement.tscn").instantiate()
	add_child(chargement)

	# Attendre 2 secondes
	await get_tree().create_timer(1.0).timeout

	# Supprimer l'écran de chargement
	chargement.queue_free()

	# Passer à la scène du jeu
	get_tree().change_scene_to_file("res://scene/main.tscn")


func _on_atelier_button_down() -> void:
	get_tree().change_scene_to_file("res://scene/atelier.tscn")


func _on_galerie_des_trophes_button_down() -> void:
	get_tree().change_scene_to_file("res://scene/trophées.tscn")


func _on_reglage_button_down() -> void:
	get_tree().change_scene_to_file("res://scene/parametre.tscn")





func _on_quitter_button_down() -> void:
	get_tree().quit()


#debuggage le probleme viens de la
#func _on_quitter_2_button_down() -> void:
	#get_tree().change_scene_to_file("res://scene/main_menu.tscn")
	#print("sa marche") AUSSI LA TAILLE DE L ECRAN ??
