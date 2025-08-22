#comprendre piece

extends Node2D   # La pièce est un Node2D (un objet qu’on peut placer sur la scène 2D)

const TILE_SIZE = 124  # Taille d'une case du plateau (en pixels)

# Variables exportées → visibles et modifiables dans l’éditeur Godot
@export var texture_path: String   # Chemin de l'image (sprite) de la pièce
@export var type: String           # Type de pièce (PION, ROI, TOUR, etc.)
@export var couleur: String        # Couleur de la pièce ("BLANC" ou "NOIR")

# Variables internes
var grid_position: Vector2   # Position de la pièce sur la grille (ex: (0,0) en haut à gauche)
var selected: bool = false   # Indique si la pièce est sélectionnée par le joueur

# Récupération du Sprite2D enfant celui qui affiche l’image de la pièce
@onready var sprite = $Sprite2D


# Fonction appelée quand la pièce est prête (après avoir été ajoutée à la scène)
func _ready():
	add_to_group("pieces")   # On ajoute toutes les pièces dans le groupe "pieces"
	var texture = load(texture_path)  # On charge l’image à partir du chemin donné
	if texture:
		sprite.texture = texture       # On applique la texture au Sprite
		sprite.centered = true         # On centre le Sprite
		_redimensionner()              # On redimensionne l’image à la bonne taille

# Fonction qui ajuste la taille de l’image de la pièce pour qu’elle tienne dans la case
func _redimensionner():
	if sprite.texture:
		# On calcule un ratio pour que la pièce occupe environ 80% de la case
		var ratio = TILE_SIZE * 0.8 / max(sprite.texture.get_width(), sprite.texture.get_height())
		sprite.scale = Vector2(ratio, ratio)  # On applique l’échelle calculée

# Quand on sélectionne une pièce (effet visuel)
func select():
	selected = true
	modulate = Color(1, 1, 1, 0.5)   # On rend la pièce légèrement transparente

# Quand on désélectionne une pièce effet visuel
func deselect():
	selected = false
	modulate = Color(1, 1, 1, 1)     # On remet l’opacité normale

# Déplacer une pièce vers une nouvelle position de grille
func move_to(new_grid_pos: Vector2):
	grid_position = new_grid_pos   # On enregistre la nouvelle position dans la grille
	position = Vector2(            # On convertit la grille en coordonnées pixels
		new_grid_pos.x * TILE_SIZE + TILE_SIZE / 2,  # X pixel (au centre de la case)
		new_grid_pos.y * TILE_SIZE + TILE_SIZE / 2   # Y pixel (au centre de la case)
	)

# Fonction qui renvoie tous les coups possibles selon le type de pièce
func get_valid_moves(piece_positions: Dictionary) -> Array:
	var moves: Array = []   # Liste des coups valides
	match type:             # On choisit en fonction du type de pièce
		"TOUR":
			moves += _ray_moves(piece_positions, [
				Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1) # Haut, bas, gauche, droite
			])
		"FOU":
			moves += _ray_moves(piece_positions, [
				Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1) # Diagonales
			])
		"REINE":
			moves += _ray_moves(piece_positions, [
				Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1), # Droites
				Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1) # Diagonales
			])
		"CAVALIER":
			moves += _knight_moves(piece_positions)  # Cavaliers
		"ROI":
			moves += _king_moves(piece_positions)    # Roi
		"PION":
			moves += _pawn_moves(piece_positions)    # Pions
		_:
			# Si type inconnu → aucun coup
			pass
	return moves



# Fonction pour les pièces "à rayon" (Tour, Fou, Reine)
func _ray_moves(piece_positions: Dictionary, directions: Array) -> Array:
	var out: Array = []
	for dir in directions:          # Pour chaque direction possible
		var p = grid_position + dir # On avance d’une case dans cette direction
		while _inside_board(p):     # Tant qu’on reste dans l’échiquier
			if piece_positions.has(p):   # Si une pièce bloque le chemin
				if piece_positions[p].couleur != couleur:  # Si c’est un ennemi
					out.append(p)   # On peut le capturer
				break  # On arrête (on ne peut pas sauter par-dessus)
			out.append(p)   # Case vide → coup valide
			p += dir        # On avance encore
	return out
	
	
# Déplacements du cavalier
func _knight_moves(piece_positions: Dictionary) -> Array:
	var out: Array = []
	var deltas = [  # Tous les déplacements possibles d’un cavalier
		Vector2(1, 2), Vector2(2, 1), Vector2(-1, 2), Vector2(-2, 1),
		Vector2(1, -2), Vector2(2, -1), Vector2(-1, -2), Vector2(-2, -1)
	]
	for d in deltas:
		var p = grid_position + d
		# Le cavalier peut aller sur une case vide ou capturer un ennemi
		if _inside_board(p) and (not piece_positions.has(p) or piece_positions[p].couleur != couleur):
			out.append(p)
	return out




# Déplacements du roi (1 case dans toutes les directions)
func _king_moves(piece_positions: Dictionary) -> Array:
	var out: Array = []
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0: # On saute la case actuelle
				continue
			var p = grid_position + Vector2(dx, dy)
			if _inside_board(p) and (not piece_positions.has(p) or piece_positions[p].couleur != couleur):
				out.append(p)
	return out




# Déplacements du pion
func _pawn_moves(piece_positions: Dictionary) -> Array:
	var out: Array = []
	# Les pions blancs montent (-1), les noirs descendent (+1)
	var dir = -1 if couleur == "BLANC" else 1
	# Ligne de départ des pions (pour avancer de 2 cases au premier coup)
	var start_row = 6 if couleur == "BLANC" else 1

	# Avance d’une case (seulement si vide)
	var one = grid_position + Vector2(0, dir)
	if _inside_board(one) and not piece_positions.has(one):
		out.append(one)
		# Avance de deux cases si on est sur la ligne de départ et que c’est vide
		var two = grid_position + Vector2(0, dir * 2)
		if int(grid_position.y) == start_row and not piece_positions.has(two):
			out.append(two)

	# Captures diagonales
	for dx in [-1, 1]:
		var diag = grid_position + Vector2(dx, dir)
		if _inside_board(diag) and piece_positions.has(diag) and piece_positions[diag].couleur != couleur:
			out.append(diag)

	# (roque, en passant et promotion → pas encore gérés ici)
	return out

# Vérifie si une position est bien à l’intérieur de l’échiquier (8x8)
func _inside_board(p: Vector2) -> bool:
	return p.x >= 0 and p.x < 8 and p.y >= 0 and p.y < 8
