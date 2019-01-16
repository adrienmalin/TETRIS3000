extends Spatial

const NB_MINOES = 4
const CLOCKWISE = -1
const COUNTERCLOCKWISE = 1
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
		lock_delay.start()
		rotated_last = false
		return true
	return false
	
func rotate(direction):
	var translations = get_translations()
	var rotated_translations = [translations[0]]
	var center = translations[0]
	for i in range(1, NB_MINOES):
		var rt = translations[i] - center
		rt = Vector3(-1*direction*rt.y, direction*rt.x, 0)
		rt += center
		rotated_translations.append(rt)
	var movements = SUPER_ROTATION_SYSTEM[orientation][direction]
	for i in range(movements.size()):
		if grid_map.possible_positions(rotated_translations, movements[i]):
			orientation = (orientation - direction) % NB_MINOES
			set_translations(rotated_translations)
			translate(movements[i])
			lock_delay.start()
			if i == 4:
				rotation_point_5_used = true
			rotated_last = true
			return true
	return false
	
func t_spin():
	return ""
	
func emit_trail(visible):
	var trail
	for mino in minoes:
		trail = mino.get_node("Trail")
		trail.emitting = visible
		trail.visible = visible
		mino.get_node("SpotLight").visible = visible