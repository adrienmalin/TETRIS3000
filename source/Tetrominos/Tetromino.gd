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

func _ready():
	randomize()
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
		return true
	return false
	
func rotate(direction):
	var rotations = SUPER_ROTATION_SYSTEM[orientation][direction]
	if rotations:
		var translations = get_translations()
		var rotated_translations = [translations[0]]
		for i in range(1, NB_MINOES):
			var rotated_translation = translations[i] - translations[0]
			rotated_translation = Vector3(-1*direction*rotated_translation.y, direction*rotated_translation.x, 0)
			rotated_translation += translations[0]
			rotated_translations.append(rotated_translation)
		for i in range(rotations.size()):
			if grid_map.possible_positions(rotated_translations, rotations[i]):
				orientation = (orientation - direction) % NB_MINOES
				set_translations(rotated_translations)
				translate(rotations[i])
				lock_delay.start()
				if i == 4:
					rotation_point_5_used = true
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