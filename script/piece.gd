extends Node2D

const TILE_SIZE = 81

@export var texture_path: String
@export var type: String
@export var couleur: String
var grid_position: Vector2
var selected: bool = false

@onready var sprite = $Sprite2D


func _ready():
	add_to_group("pieces")
	var texture = load(texture_path)
	if texture:
		sprite.texture = texture
		sprite.centered = true
		_redimensionner()
	else:
		push_error("Texture manquante: " + texture_path)

func _redimensionner():
	if sprite.texture:
		var ratio = TILE_SIZE * 0.8 / max(sprite.texture.get_width(), sprite.texture.get_height())
		sprite.scale = Vector2(ratio, ratio)

func select():
	selected = true
	modulate = Color(1, 1, 1, 0.7)

func deselect():
	selected = false
	modulate = Color(1, 1, 1, 1)

func move_to(new_grid_pos: Vector2):
	grid_position = new_grid_pos
	position = Vector2(
		new_grid_pos.x * TILE_SIZE + TILE_SIZE / 2,
		new_grid_pos.y * TILE_SIZE + TILE_SIZE / 2
	)

func get_valid_moves(piece_positions: Dictionary) -> Array:
	var moves: Array = []
	match type:
		"TOUR":
			moves += _ray_moves(piece_positions, [
				Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)
			])
		"FOU":
			moves += _ray_moves(piece_positions, [
				Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)
			])
		"REINE":
			moves += _ray_moves(piece_positions, [
				Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1),
				Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)
			])
		"CAVALIER":
			moves += _knight_moves(piece_positions)
		"ROI":
			moves += _king_moves(piece_positions)
		"PION":
			moves += _pawn_moves(piece_positions)
		_:
			# Par défaut aucun coup
			pass
	return moves


func _ray_moves(piece_positions: Dictionary, directions: Array) -> Array:
	var out: Array = []
	for dir in directions:
		var p = grid_position + dir
		while _inside_board(p):
			if piece_positions.has(p):
				# On peut capturer si c'est une pièce ennemie
				if piece_positions[p].couleur != couleur:
					out.append(p)
				break
			out.append(p)
			p += dir
	return out


func _knight_moves(piece_positions: Dictionary) -> Array:
	var out: Array = []
	var deltas = [
		Vector2(1, 2), Vector2(2, 1), Vector2(-1, 2), Vector2(-2, 1),
		Vector2(1, -2), Vector2(2, -1), Vector2(-1, -2), Vector2(-2, -1)
	]
	for d in deltas:
		var p = grid_position + d
		if _inside_board(p) and (not piece_positions.has(p) or piece_positions[p].couleur != couleur):
			out.append(p)
	return out


func _king_moves(piece_positions: Dictionary) -> Array:
	var out: Array = []
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var p = grid_position + Vector2(dx, dy)
			if _inside_board(p) and (not piece_positions.has(p) or piece_positions[p].couleur != couleur):
				out.append(p)
	return out


func _pawn_moves(piece_positions: Dictionary) -> Array:
	var out: Array = []
	var dir = -1 if couleur == "BLANC" else 1
	var start_row = 6 if couleur == "BLANC" else 1

	# Avance d'une case si vide
	var one = grid_position + Vector2(0, dir)
	if _inside_board(one) and not piece_positions.has(one):
		out.append(one)
		# Avance de deux cases depuis la rangée de départ si les deux sont vides
		var two = grid_position + Vector2(0, dir * 2)
		if int(grid_position.y) == start_row and not piece_positions.has(two):
			out.append(two)

	# Captures diagonales
	for dx in [-1, 1]:
		var diag = grid_position + Vector2(dx, dir)
		if _inside_board(diag) and piece_positions.has(diag) and piece_positions[diag].couleur != couleur:
			out.append(diag)

	# (roque/en passant/promotion non gérés ici)
	return out


func _inside_board(p: Vector2) -> bool:
	return p.x >= 0 and p.x < 8 and p.y >= 0 and p.y < 8
