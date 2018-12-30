extends "Tetromino.gd"
    
const T_SLOT = [
	Vector3(-1, 1, 0),
	Vector3(1, 1, 0),
	Vector3(1, -1, 0),
	Vector3(-1, -1, 0)
]

func rotate(direction):
	if .rotate(direction):
		detect_t_spin()
		return true
	return false
	
func detect_t_spin():
	var center = to_global(minoes[0].translation)
	var a = not get_parent().is_free_cell(center + T_SLOT[orientation])
	var b = not get_parent().is_free_cell(center + T_SLOT[(1+orientation)%4])
	var c = not get_parent().is_free_cell(center + T_SLOT[(2+orientation)%4])
	var d = not get_parent().is_free_cell(center + T_SLOT[(3+orientation)%4])
	if a and b and (c or d):
		t_spin = T_SPIN
	elif c and d and (a or b):
		if t_spin != T_SPIN:
			t_spin = MINI_T_SPIN