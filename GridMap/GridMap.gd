extends GridMap

const ExplodingLine = preload("res://ExplodingLine/ExplodingLine.tscn")
const Tetromino = preload("res://Tetrominos/Tetromino.gd")
const TetroI = preload("res://Tetrominos/TetroI.tscn")
const TetroJ = preload("res://Tetrominos/TetroJ.tscn")
const TetroL = preload("res://Tetrominos/TetroL.tscn")
const TetroO = preload("res://Tetrominos/TetroO.tscn")
const TetroS = preload("res://Tetrominos/TetroS.tscn")
const TetroT = preload("res://Tetrominos/TetroT.tscn")
const TetroZ = preload("res://Tetrominos/TetroZ.tscn")

const NB_LINES = 20
const NB_COLLUMNS = 10

const EMPTY_CELL = -1

const NEXT_POSITION = Vector3(13, 16, 0)
const START_POSITION = Vector3(5, 20, 0)
const HOLD_POSITION = Vector3(-5, 16, 0)

const movements = {
	"move_right": Vector3(1, 0, 0),
	"move_left": Vector3(-1, 0, 0),
	"soft_drop": Vector3(0, -1, 0)
}

const SCORES = [
	[0, 4, 1],
	[1, 8, 2],
	[3, 12],
	[5, 16],
	[8]
]
const LINES_CLEARED_NAMES = ["", "SINGLE", "DOUBLE", "TRIPLE", "TETRIS"]
const T_SPIN_NAMES = ["", "T-SPIN", "MINI T-SPIN"]

const LINE_CLEAR_MIDI_CHANNELS = [2, 6]

var next_piece = random_piece()
var current_piece
var held_piece
var current_piece_held = false

var autoshift_action = ""

var exploding_lines = []
var random_bag = []
var playing = true

var level = 0
var goal = 0
var score = 0

func _ready():
	randomize()
	for y in range(NB_LINES):
		exploding_lines.append(ExplodingLine.instance())
		add_child(exploding_lines[y])
		exploding_lines[y].translation = Vector3(NB_COLLUMNS/2, y, 1)
	resume()
	new_level()
	
func new_level():
	level += 1
	goal += 5 * level
	$DropTimer.wait_time = pow(0.8 - ((level - 1) * 0.007), level - 1)
	if level > 15:
		$LockDelay.wait_time = 0.5 * pow(0.9, level-15)
	print("LEVEL ", level, " Goal ", goal)
	new_piece()
	
func random_piece():
	if not random_bag:
		random_bag = [
			TetroI, TetroJ, TetroL, TetroO,
			TetroS, TetroT, TetroZ
		]
	var choice = randi() % random_bag.size()
	var piece = random_bag[choice].instance()
	random_bag.remove(choice)
	add_child(piece)
	return piece
	
func new_piece():
	current_piece = next_piece
	current_piece.translation = START_POSITION
	autoshift_action = ""
	next_piece = random_piece()
	next_piece.translation = NEXT_POSITION
	if move(movements["soft_drop"]):
		$DropTimer.start()
		$LockDelay.start()
		current_piece_held = false
	else:
		game_over()

func _process(delta):
	if autoshift_action:
		if not Input.is_action_pressed(autoshift_action):
			$AutoShiftDelay.stop()
			$AutoShiftTimer.stop()
			autoshift_action = ""
	if Input.is_action_just_pressed("pause"):
		if playing:
			pause()
		else:
			resume()
	if playing:
		process_actions()
			
func process_actions():
	for action in movements:
		if action != autoshift_action:
			if Input.is_action_pressed(action):
				move(movements[action])
				autoshift_action = action
				$AutoShiftTimer.stop()
				$AutoShiftDelay.start()
	if Input.is_action_just_pressed("hard_drop"):
		while move(movements["soft_drop"]):
			pass
		lock_piece()
	if Input.is_action_just_pressed("rotate_clockwise"):
		rotate(Tetromino.CLOCKWISE)
	if Input.is_action_just_pressed("rotate_counterclockwise"):
		rotate(Tetromino.COUNTERCLOCKWISE)
	if Input.is_action_just_pressed("hold"):
		hold()

func _on_AutoShiftDelay_timeout():
	if playing and autoshift_action:
		move(movements[autoshift_action])
		$AutoShiftTimer.start()

func _on_AutoShiftTimer_timeout():
	if playing and autoshift_action:
		move(movements[autoshift_action])
		
func is_free_cell(position):
	return (
		0 <= position.x and position.x < NB_COLLUMNS
		and position.y >= 0
		and get_cell_item(position.x, position.y, 0) == GridMap.INVALID_CELL_ITEM
	)
	
func possible_positions(initial_positions, movement):
	var position
	var test_positions = []
	for i in range(4):
		position = initial_positions[i] + movement
		if is_free_cell(position):
			test_positions.append(position)
	if test_positions.size() == Tetromino.NB_MINOES:
		return test_positions
	else:
		return []
		
func move(movement):
	if current_piece.move(movement):
		$LockDelay.start()
		return true
	else:
		return false
		
func rotate(direction):
	if current_piece.rotate(direction):
		$LockDelay.start()
		return true
	else:
		return false

func _on_DropTimer_timeout():
	move(movements["soft_drop"])

func _on_LockDelay_timeout():
	if not move(movements["soft_drop"]):
		lock_piece()

func lock_piece():
	for mino in current_piece.minoes:
		set_cell_item(current_piece.to_global(mino.translation).x, current_piece.to_global(mino.translation).y, 0, 0)
	remove_child(current_piece)
	line_clear()
	
func line_clear():
	var NB_MINOES
	var lines_cleared = 0
	for y in range(NB_LINES-1, -1, -1):
		NB_MINOES = 0
		for x in range(NB_COLLUMNS):
			if get_cell_item(x, y, 0) == 0:
				NB_MINOES += 1
		if NB_MINOES == NB_COLLUMNS:
			for y2 in range(y, NB_LINES+2):
				for x in range(NB_COLLUMNS):
					set_cell_item(x, y2, 0, get_cell_item(x, y2+1, 0))
			lines_cleared += 1
			exploding_lines[y].restart()
	if lines_cleared or current_piece.t_spin:
		var s = SCORES[lines_cleared][current_piece.t_spin]
		score += 100 * s
		goal -= s
		print(T_SPIN_NAMES[current_piece.t_spin], ' ', LINES_CLEARED_NAMES[lines_cleared], " Score ", score)
		
		if lines_cleared == Tetromino.NB_MINOES:
			for channel in LINE_CLEAR_MIDI_CHANNELS:
				$MidiPlayer.channel_status[channel].vomume = 127
			$MidiPlayer/LineCLearTimer.wait_time = 0.86
		else:
			for channel in LINE_CLEAR_MIDI_CHANNELS:
				$MidiPlayer.channel_status[channel].vomume = 100
			$MidiPlayer/LineCLearTimer.wait_time = 0.43
		$MidiPlayer.unmute_channels(LINE_CLEAR_MIDI_CHANNELS)
		$MidiPlayer/LineCLearTimer.start()
	if goal <= 0:
		new_level()
	else:
		new_piece()

func hold():
	if not current_piece_held:
		if held_piece:
			var tmp = held_piece
			held_piece = current_piece
			current_piece = tmp
			current_piece.translation = START_POSITION
		else:
			held_piece = current_piece
			new_piece()
		held_piece.translation = HOLD_POSITION
		current_piece_held = true
		
func resume():
	playing = true
	$DropTimer.start()
	$LockDelay.start()
	$MidiPlayer.resume()
	$MidiPlayer.mute_channels(LINE_CLEAR_MIDI_CHANNELS)
	print("RESUME")

func pause():
	playing = false
	$DropTimer.stop()
	$LockDelay.stop()
	$MidiPlayer.stop()
	print("PAUSE")
		
func game_over():
	pause()
	print("GAME OVER")
	
func _notification(what):
    if what == MainLoop.NOTIFICATION_WM_FOCUS_OUT:
        pause()
    if what == MainLoop.NOTIFICATION_WM_FOCUS_IN:
        resume()

func _on_LineCLearTimer_timeout():
	$MidiPlayer.mute_channels(LINE_CLEAR_MIDI_CHANNELS)
