extends "Tetromino.gd"
    
const T_SLOT = [
	Vector3(-1, 1, 0),
	Vector3(1, 1, 0),
	Vector3(1, -1, 0),
	Vector3(-1, -1, 0)
]

var rotation_point_5_used = false

func rotate(direction):
	var rotation_point = .rotate(direction)
	if rotation_point:
		var center = to_global(minoes[0].translation)
		var a = not grid_map.is_free_cell(center + T_SLOT[orientation])
		var b = not grid_map.is_free_cell(center + T_SLOT[(1+orientation)%4])
		var c = not grid_map.is_free_cell(center + T_SLOT[(2+orientation)%4])
		var d = not grid_map.is_free_cell(center + T_SLOT[(3+orientation)%4])
		if a and b and (c or d) or rotation_point_5_used:
			t_spin = "T-SPIN"
		elif c and d and (a or b):
			t_spin = "MINI T-SPIN"
		else:
			t_spin = ""
		if rotation_point == 5:
			rotation_point_5_used = true
	return rotation_point