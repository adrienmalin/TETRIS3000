extends Spatial

const NB_MINOES = 4
const CLOCKWISE = -1
const COUNTERCLOCKWISE = 1
const DROP_MOVEMENT = Vector3(0, -1, 0)

var super_rotation_system = [
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

var minoes = []
var grid_map
var lock_delay
var orientation = 0
var rotation_point_5_used = false
var rotated_last = false

func _ready():
	for i in range(NB_MINOES):
		minoes.append(get_node("Mino"+str(i)))
	grid_map = get_node("../Matrix/GridMap")
	lock_delay = get_node("../LockDelay")
	
func set_translations(translations):
	for i in range(NB_MINOES):
		minoes[i].translation = to_local(translations[i])
	
func get_translations():
	var translations = []
	for mino in minoes:
		translations.append(to_global(mino.translation))
	return translations

func move(movement):
	if grid_map.possible_positions(get_translations(), movement):
		translate(movement)
		if movement == DROP_MOVEMENT:
			locking(false)
			lock_delay.stop()
		rotated_last = false
		return true
	else:
		if movement == DROP_MOVEMENT:
			locking(true)
			lock_delay.start()
		return false
	
func turn(direction):
	var translations = get_translations()
	var rotated_translations = [translations[0]]
	var center = translations[0]
	for i in range(1, NB_MINOES):
		var rt = translations[i] - center
		rt = Vector3(-1*direction*rt.y, direction*rt.x, 0)
		rt += center
		rotated_translations.append(rt)
	var movements = super_rotation_system[orientation][direction]
	for i in range(movements.size()):
		if grid_map.possible_positions(rotated_translations, movements[i]):
			orientation = (orientation - direction) % NB_MINOES
			set_translations(rotated_translations)
			translate(movements[i])
			lock_delay.stop()
			locking(false)
			rotated_last = true
			if i == 4:
				rotation_point_5_used = true
			return true
	return false
	
func t_spin():
	return ""
	
func turn_light(on):
	for mino in minoes:
		mino.get_node("SpotLight").visible = on
		
func locking(visible):
	for mino in minoes:
		mino.get_node("LockingMesh").visible = visible
