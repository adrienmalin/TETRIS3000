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

const MIDI_MOVE_CHANNELS = [7, 8, 9, 11]
const MIDI_LINE_CLEAR_CHANNELS = [2, 6, 10]

var next_piece = random_piece()
var current_piece
var held_piece
var current_piece_held = false

var autoshift_action = ""

var exploding_lines = []
var lines_to_clear = []
var random_bag = []
var playing = true

var level = 0
var goal = 0
var score = 0

func _ready():
	randomize()
	print(NB_LINES)
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
	current_piece.emit_trail(true)
	autoshift_action = ""
	update_ghost_piece()
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
				if move(movements[action]):
					move_midi()
				autoshift_action = action
				$AutoShiftTimer.stop()
				$AutoShiftDelay.start()
	if Input.is_action_just_pressed("hard_drop"):
		move_midi()
		while move(movements["soft_drop"]):
			pass
		lock_piece()
	if Input.is_action_just_pressed("rotate_clockwise"):
		rotate(Tetromino.CLOCKWISE)
		move_midi()
	if Input.is_action_just_pressed("rotate_counterclockwise"):
		rotate(Tetromino.COUNTERCLOCKWISE)
		move_midi()
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
		if movement.x:
			update_ghost_piece()
		return true
	else:
		return false
		
func rotate(direction):
	if current_piece.rotate(direction):
		update_ghost_piece()
		$LockDelay.start()
		return true
	else:
		return false
		
func move_midi():
	for channel_id in MIDI_MOVE_CHANNELS:
		$MidiPlayer.channel_status[channel_id].pan = current_piece.translation.x / 10.0
	mute_midi_channel(MIDI_MOVE_CHANNELS, false)
	$MidiPlayer/MoveDelay.start()
		
func update_ghost_piece():
	var new_positions = current_piece.positions()
	var positions
	while(new_positions):
		positions = new_positions
		new_positions = possible_positions(positions, movements["soft_drop"])
	$GhostPiece.apply_positions(positions)

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
	lines_to_clear = []
	for y in range(NB_LINES-1, -1, -1):
		NB_MINOES = 0
		for x in range(NB_COLLUMNS):
			if get_cell_item(x, y, 0) == 0:
				NB_MINOES += 1
		if NB_MINOES == NB_COLLUMNS:
			for x in range(NB_COLLUMNS):
				set_cell_item(x, y, 0, EMPTY_CELL)
			lines_to_clear.append(y)
			exploding_lines[y].restart()
	if lines_to_clear:
		$ExplosionDelay.start()
	update_score()
	
func update_score():
	if lines_to_clear or current_piece.t_spin:
		var s = SCORES[lines_to_clear.size()][current_piece.t_spin]
		score += 100 * s
		goal -= s
		print(T_SPIN_NAMES[current_piece.t_spin], ' ', LINES_CLEARED_NAMES[lines_to_clear.size()], " Score ", score)
		mute_midi_channel(MIDI_LINE_CLEAR_CHANNELS, false)
		$MidiPlayer.play_now()
		if lines_to_clear.size() == Tetromino.NB_MINOES:
			$MidiPlayer/LineLcearDelay.wait_time = 1.71
		else:
			$MidiPlayer/LineLcearDelay.wait_time = 0.86
		$MidiPlayer/LineLcearDelay.start()
	if goal <= 0:
		new_level()
	else:
		new_piece()

func _on_ExplosionDelay_timeout():
	for cleared_line in lines_to_clear:
		for y in range(cleared_line, NB_LINES+2):
			for x in range(NB_COLLUMNS):
				set_cell_item(x, y, 0, get_cell_item(x, y+1, 0))
	update_ghost_piece()

func hold():
	if not current_piece_held:
		if held_piece:
			var tmp = held_piece
			held_piece = current_piece
			current_piece = tmp
			current_piece.translation = START_POSITION
			current_piece.emit_trail(true)
			update_ghost_piece()
		else:
			held_piece = current_piece
			new_piece()
		held_piece.translation = HOLD_POSITION
		held_piece.emit_trail(false)
		current_piece_held = true
		
func resume():
	playing = true
	$DropTimer.start()
	$LockDelay.start()
	$MidiPlayer.play()
	mute_midi_channel(MIDI_MOVE_CHANNELS, true)
	mute_midi_channel(MIDI_LINE_CLEAR_CHANNELS, true)
	print("RESUME")

func pause():
	playing = false
	$DropTimer.stop()
	$LockDelay.stop()
	$MidiPlayer.stop()
	print("PAUSE")
		
func game_over():
	playing = false
	$DropTimer.stop()
	$AutoShiftDelay.stop()
	$AutoShiftTimer.stop()
	print("GAME OVER")
	
func _notification(what):
    if what == MainLoop.NOTIFICATION_WM_FOCUS_OUT:
        pause()

func mute_midi_channel(channels, muted):
	for channel_id in channels:
		$MidiPlayer.channel_mute[channel_id] = muted

func _on_MoveDelay_timeout():
	mute_midi_channel(MIDI_MOVE_CHANNELS, true)

func _on_LineLcearDelay_timeout():
	mute_midi_channel(MIDI_LINE_CLEAR_CHANNELS, true)
