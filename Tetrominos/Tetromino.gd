extends Spatial

const NB_MINOES = 4
const CLOCKWISE = -1
const COUNTERCLOCKWISE = 1
const NO_T_SPIN = 0
const T_SPIN = 1
const MINI_T_SPIN = 2
const SUPER_ROTATION_SYSTEM = [
    {
        COUNTERCLOCKWISE: [
			Vector3(0, 0, 0),
			Vector3(1, 0, 0),
			Vector3(1, 1, 0),
			Vector3(0, -2, 0),
			Vector3(1, -2, 0)
		],
        CLOCKWISE: [
			Vector3(0, 0, 0),
			Vector3(-1, 0, 0),
			Vector3(-1, 1, 0),
			Vector3(0, -2, 0),
			Vector3(-1, -2, 0)
		],
    },
    {
        COUNTERCLOCKWISE: [
			Vector3(0, 0, 0),
			Vector3(1, 0, 0),
			Vector3(1, -1, 0),
			Vector3(0, 2, 0),
			Vector3(1, 2, 0)
		],
        CLOCKWISE: [
			Vector3(0, 0, 0),
			Vector3(1, 0, 0),
			Vector3(1, -1, 0),
			Vector3(0, 2, 0),
			Vector3(1, 2, 0)
		],
    },
    {
        COUNTERCLOCKWISE: [
			Vector3(0, 0, 0),
			Vector3(-1, 0, 0),
			Vector3(-1, 1, 0),
			Vector3(0, -2, 0),
			Vector3(-1, -2, 0)
		],
        CLOCKWISE: [
			Vector3(0, 0, 0),
			Vector3(1, 0, 0),
			Vector3(1, 1, 0),
			Vector3(0, -2, 0),
			Vector3(1, -2, 0)
		],
    },
    {
        COUNTERCLOCKWISE: [
			Vector3(0, 0, 0),
			Vector3(-1, 0, 0),
			Vector3(-1, -1, 0),
			Vector3(0, 2, 0),
			Vector3(-1, 2, 0)
		],
        CLOCKWISE: [
			Vector3(0, 0, 0),
			Vector3(-1, 0, 0),
			Vector3(-1, -1, 0),
			Vector3(0, -2, 0),
			Vector3(-1, 2, 0)
		]
    }
]

var minoes
var orientation = 0
var t_spin = NO_T_SPIN

func _ready():
	minoes = [$Mino0, $Mino1, $Mino2, $Mino3]
	
func positions():
	var p = []
	for mino in minoes:
		p.append(to_global(mino.translation))
	return p
	
func rotated_positions(direction):
	var translations = [to_global(minoes[0].translation) ]
	for i in range(1, 4):
		var v = to_global(minoes[i].translation) 
		v -= to_global(minoes[0].translation)
		v = Vector3(-1*direction*v.y, direction*v.x, 0)
		v += to_global(minoes[0].translation)
		translations.append(v)
	return translations
	
func apply_positions(positions):
	for i in range(NB_MINOES):
		minoes[i].translation = to_local(positions[i])

func move(movement):
	var new_positions = get_parent().possible_positions(positions(), movement)
	if new_positions:
		translate(movement)
		return true
	else:
		return false
	
func rotate(direction):
	var rotated_positions = rotated_positions(direction)
	var movements = SUPER_ROTATION_SYSTEM[orientation][direction]
	var test_position
	for movement in movements:
		test_position = get_parent().possible_positions(rotated_positions, movement)
		if test_position:
			orientation -= direction
			orientation %= NB_MINOES
			apply_positions(rotated_positions)
			translate(movement)
			return true
	return false
	
func emit_trail(emit):
	for mino in minoes:
		mino.get_node("Trail").emitting = emit