extends Node2D

const TILE_SIZE = 124#C'est la taille largeur et hauteur en pixels d'une case du damier
const GRID_SIZE = 8 #nombre de case du damier
const PIECE_SCENE = preload("res://scene/piece_base.tscn") #on load la scene piece

var selected_piece = null #selectione une piece null si aucune piece
var piece_positions = {}  # Dictionnaire: position -> pièce
var valid_moves = []
var current_turn = "BLANC"# Tour actuel

func _ready():
	randomize()  # le générateur de nombres aléatoires 
	queue_redraw()  # Force le redessin du Node2D 
	placer_toutes_les_pieces() #appelle a la fonction pour tavu placer les pieces

# on load tout les pieces et on les places

func placer_toutes_les_pieces():
	# Pièces noires
	_creer_piece("res://texture/piece/noir/tour noir.png", "TOUR", "NOIR", Vector2(0,0))
	_creer_piece("res://texture/piece/noir/cavalier noir.png", "CAVALIER", "NOIR", Vector2(1,0))
	_creer_piece("res://texture/piece/noir/fou noir.png", "FOU", "NOIR", Vector2(2,0))
	_creer_piece("res://texture/piece/noir/reine noir.png", "REINE", "NOIR", Vector2(3,0))
	_creer_piece("res://texture/piece/noir/roi noir.png", "ROI", "NOIR", Vector2(4,0))
	_creer_piece("res://texture/piece/noir/fou noir.png", "FOU", "NOIR", Vector2(5,0))
	_creer_piece("res://texture/piece/noir/cavalier noir.png", "CAVALIER", "NOIR", Vector2(6,0))
	_creer_piece("res://texture/piece/noir/tour noir.png", "TOUR", "NOIR", Vector2(7,0))
	for x in range(8):
		_creer_piece("res://texture/piece/noir/pion noir.png", "PION", "NOIR", Vector2(x,1))

	# Pièces blanches
	_creer_piece("res://texture/piece/blanc/tour blanche.png", "TOUR", "BLANC", Vector2(0,7))
	_creer_piece("res://texture/piece/blanc/cavalier blanc.png", "CAVALIER", "BLANC", Vector2(1,7))
	_creer_piece("res://texture/piece/blanc/fou blanc.png", "FOU", "BLANC", Vector2(2,7))
	_creer_piece("res://texture/piece/blanc/reine blanc.png", "REINE", "BLANC", Vector2(3,7))
	_creer_piece("res://texture/piece/blanc/roi blanc.png", "ROI", "BLANC", Vector2(4,7))
	_creer_piece("res://texture/piece/blanc/fou blanc.png", "FOU", "BLANC", Vector2(5,7))
	_creer_piece("res://texture/piece/blanc/cavalier blanc.png", "CAVALIER", "BLANC", Vector2(6,7))
	_creer_piece("res://texture/piece/blanc/tour blanche.png", "TOUR", "BLANC", Vector2(7,7))
	for x in range(8):
		_creer_piece("res://texture/piece/blanc/pion blanc.png", "PION", "BLANC", Vector2(x,6))


# Création d’une pièce

func _creer_piece(texture_path: String, type: String, couleur: String, pos_case: Vector2):
	# texture_path (image), type (pion/dame), couleur (équipe), pos_case (position)
	var piece = PIECE_SCENE.instantiate()          # on copie avec instantiate la pièce
	piece.texture_path = texture_path             # Assignation du chemin de texture
	piece.type = type                             # Définit le type (Pion/Dame/etc)
	piece.couleur = couleur                       # Définit la couleur (Blanc/Noir)
	piece.move_to(pos_case)                       # Positionne visuellement la pièce
	piece.grid_position = pos_case                # Stocke sa position logique
	piece_positions[pos_case] = piece             # Enregistre dans le dictionnaire
	add_child(piece)                              # Ajoute à la scène
	
	



# Dessin du plateau
func _draw():
	for x in range(GRID_SIZE): #boucle pour placer piece en x et y
		for y in range(GRID_SIZE):
			var color = Color.WHITE if (x + y) % 2 == 0 else Color.BURLYWOOD#alternance de couleur
			draw_rect(Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE), color)

	for i in valid_moves: #on cherche dans la list les bon moves
		draw_rect(Rect2(i.x * TILE_SIZE, i.y * TILE_SIZE, TILE_SIZE, TILE_SIZE), Color(0.1, 0, 0.7, 0.2))
		#draw_rect(rectangle: Rect2, couleur: Color)
		#Rect2(position_x, position_y, largeur, hauteur)



# Gestion des clics CODE A REVOIR 

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var clicked_pos = get_global_mouse_position()
		var grid_pos = Vector2(floor(clicked_pos.x / TILE_SIZE), floor(clicked_pos.y / TILE_SIZE))

		# Sélection
		if selected_piece == null:
			if piece_positions.has(grid_pos) and piece_positions[grid_pos].couleur == current_turn:
				selected_piece = piece_positions[grid_pos]
				selected_piece.select()
				valid_moves = selected_piece.get_valid_moves(piece_positions)
				queue_redraw()
		else:
			if grid_pos in valid_moves:
				# Capture
				if piece_positions.has(grid_pos):
					piece_positions[grid_pos].queue_free()
					piece_positions.erase(grid_pos)

				# Déplacement
				piece_positions.erase(selected_piece.grid_position)
				selected_piece.move_to(grid_pos)
				piece_positions[grid_pos] = selected_piece

				# Vérification promotion du pion
				if selected_piece.type == "PION":
					if (selected_piece.couleur == "BLANC" and grid_pos.y == 0) or (selected_piece.couleur == "NOIR" and grid_pos.y == 7):
						promouvoir_pion(selected_piece)

				selected_piece.deselect()
				selected_piece = null
				valid_moves.clear()
				queue_redraw()

				# Vérification fin de partie
				if check_game_over():
					return

				# Changement de tour
				current_turn = "NOIR" if current_turn == "BLANC" else "BLANC"

				# IA
				if current_turn == "NOIR":
					await get_tree().create_timer(0.4).timeout
					ia_play()
			else:
				# Désélection si clic ailleurs
				selected_piece.deselect()
				selected_piece = null
				valid_moves.clear()
				queue_redraw()


# Promotion d’un pion en reine
func promouvoir_pion(pion):
	var couleur = pion.couleur
	var pos_case = pion.grid_position
	# Chemin de la texture de la reine correspondante
	var texture_path = "res://texture/piece/%s/reine %s.png" % [couleur.to_lower(), couleur.to_lower()]

	# Supprime le pion
	piece_positions.erase(pos_case)
	pion.queue_free()

	# Crée la reine à la même position
	_creer_piece(texture_path, "REINE", couleur, pos_case)


# IA simple pour les noirs

func ia_play():
	# On crée une liste pour stocker les pièces noires qui peuvent bouger
	var black_pieces = []
	for piece in piece_positions.values():
		if piece.couleur == "NOIR":  # On sélectionne uniquement les pièces noires
			if piece.get_valid_moves(piece_positions).size() > 0:  # Si la pièce a au moins un coup valide
				black_pieces.append(piece)  # On l’ajoute à la liste

	# Si aucune pièce noire ne peut jouer, l’IA arrête son tour
	if black_pieces.size() == 0:
		return

	# --- Amélioration : on essaye de trouver une capture avant de jouer au hasard ---
	var best_piece = null
	var best_move = null

	# On parcourt toutes les pièces noires et leurs coups
	for piece in black_pieces:
		for move in piece.get_valid_moves(piece_positions):
			# Si le coup mange une pièce ennemie, on le choisit en priorité
			if piece_positions.has(move) and piece_positions[move].couleur == "BLANC":
				best_piece = piece
				best_move = move
				break  # On arrête la recherche dès qu’on trouve une capture
		if best_piece != null:
			break

	# Si aucune capture trouvée → on joue au hasard (comme avant)
	if best_piece == null:
		best_piece = black_pieces[randi() % black_pieces.size()]
		var moves = best_piece.get_valid_moves(piece_positions)
		best_move = moves[randi() % moves.size()]

	# Si le coup choisi mange une pièce, on la supprime du jeu
	if piece_positions.has(best_move):
		piece_positions[best_move].queue_free()
		piece_positions.erase(best_move)

	# On enlève l’ancienne position de la pièce
	piece_positions.erase(best_piece.grid_position)

	# On déplace la pièce sur sa nouvelle case
	best_piece.move_to(best_move)
	piece_positions[best_move] = best_piece

	# --- Vérification promotion pion ---
	if best_piece.type == "PION":
		if (best_piece.couleur == "BLANC" and best_move.y == 0) or (best_piece.couleur == "NOIR" and best_move.y == 7):
			promouvoir_pion(best_piece)

	# --- Vérification fin de partie ---
	if check_game_over():
		return

	# On passe le tour aux blancs
	current_turn = "BLANC"


# Vérification de fin de partie
func check_game_over() -> bool:
	var roi_blanc_existe = false
	var roi_noir_existe = false

	# Vérifie si les rois existent encore
	for piece in piece_positions.values():
		if piece.type == "ROI":
			if piece.couleur == "BLANC":
				roi_blanc_existe = true
			elif piece.couleur == "NOIR":
				roi_noir_existe = true

	# Si un roi a été capturé, partie terminée
	if not roi_blanc_existe:
		print("NOIR GAGNE ! Roi blanc capturé")
		return true
	elif not roi_noir_existe:
		print("BLANC GAGNE ! Roi noir capturé")
		return true

	# Vérification de pat (aucun coup possible)
	if not has_any_valid_moves("BLANC") and roi_blanc_existe:
		print("PAT ! Égalité")
		return true
	elif not has_any_valid_moves("NOIR") and roi_noir_existe:
		print("PAT ! Égalité")
		return true

	return false  # Partie continue
	
# Vérifie si une couleur a encore des coups possibles

func has_any_valid_moves(couleur: String) -> bool:
	for piece in piece_positions.values():
		if piece.couleur == couleur:
			if piece.get_valid_moves(piece_positions).size() > 0:
				return true  # Au moins un coup possible
	return false # Aucun coup possible
