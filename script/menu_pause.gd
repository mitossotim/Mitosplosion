extends CanvasLayer
var pause = false

#fonction pour le menu pause

func paspause():
	pause = !pause
	
	if pause:
		get_tree().paused = true
		show()
		
	else:
		get_tree().paused = false
		hide()
		

		
#click pause
func _input(event):
	if event.is_action_pressed("pause"):
		paspause()
		
#les boutons


	
#aussi bug

func _on_rejouer_button_down() -> void:
	get_tree().change_scene_to_file("res://scene/main.tscn")


func _on_quitter_button_down() -> void:
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
