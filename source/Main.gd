extends WorldEnvironment

const Tetromino = preload("res://Tetrominos/Tetromino.gd")
const TetroI = preload("res://Tetrominos/TetroI.tscn")
const TetroJ = preload("res://Tetrominos/TetroJ.tscn")
const TetroL = preload("res://Tetrominos/TetroL.tscn")
const TetroO = preload("res://Tetrominos/TetroO.tscn")
const TetroS = preload("res://Tetrominos/TetroS.tscn")
const TetroT = preload("res://Tetrominos/TetroT.tscn")
const TetroZ = preload("res://Tetrominos/TetroZ.tscn")

const THERE = Vector3(0, 0, 0)

const movements = {
	"move_right": Vector3(1, 0, 0),
	"move_left": Vector3(-1, 0, 0),
	"soft_drop": Vector3(0, -1, 0)
}

var random_bag = []

var next_piece
var current_piece
var held_piece
var current_piece_held

var autoshift_action = ""

var playing = false

func new_game(level):
	$Matrix/GridMap.clear()
	if current_piece:
		remove_child(current_piece)
	if held_piece:
		remove_child(held_piece)
		held_piece = null
	autoshift_action = ""
	next_piece = random_piece()
	$MidiPlayer.position = 0
	$Start.visible = false
	$Stats.new_game(level)
	new_piece()
	resume()
	
func new_piece():
	current_piece = next_piece
	current_piece.translation = $Matrix/Position3D.translation
	current_piece.emit_trail(true)
	next_piece = random_piece()
	next_piece.translation = $Next/Position3D.translation
	if current_piece.move(THERE):
		$DropTimer.start()
		$LockDelay.start()
		current_piece_held = false
	else:
		game_over()

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

func new_level(level):
	if level <= 15:
		$DropTimer.wait_time = pow(0.8 - ((level - 1) * 0.007), level - 1)
	else:
		$DropTimer.wait_time = 0.01
		$LockDelay.wait_time = 0.5 * pow(0.9, level-15)

func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		if playing:
			pause($controls_ui)
		elif $controls_ui.enable_resume:
			resume()
	if event.is_action_pressed("toggle_fullscreen"):
		OS.window_fullscreen = not OS.window_fullscreen
	if playing:
		if autoshift_action and event.is_action_released(autoshift_action):
			$AutoShiftDelay.stop()
			$AutoShiftTimer.stop()
			autoshift_action = ""
			for action in movements:
				if Input.is_action_pressed(action):
					autoshift_action = action
					process_autoshift()
					$AutoShiftDelay.start()
					break
		for action in movements:
			if action != autoshift_action:
				if event.is_action_pressed(action):
					$AutoShiftTimer.stop()
					autoshift_action = action
					process_autoshift()
					$AutoShiftDelay.start()
					break
		if event.is_action_pressed("hard_drop"):
			hard_drop()
		if event.is_action_pressed("rotate_clockwise"):
			current_piece.rotate(Tetromino.CLOCKWISE)
		if event.is_action_pressed("rotate_counterclockwise"):
			current_piece.rotate(Tetromino.COUNTERCLOCKWISE)
		if event.is_action_pressed("hold"):
			hold()

func _on_AutoShiftDelay_timeout():
	if autoshift_action:
		process_autoshift()
		$AutoShiftTimer.start()

func _on_AutoShiftTimer_timeout():
	if autoshift_action:
		process_autoshift()

func process_autoshift():
	var moved = current_piece.move(movements[autoshift_action])
	if moved and (autoshift_action == "soft_drop"):
		$Stats.piece_dropped(1)

func hard_drop():
	var score = 0
	while current_piece.move(movements["soft_drop"]):
		score += 2
	$Stats.piece_dropped(score)
	$LockDelay.stop()
	lock()

func _on_DropTimer_timeout():
	current_piece.move(movements["soft_drop"])

func _on_LockDelay_timeout():
	if not current_piece.move(movements["soft_drop"]):
		lock()
		
func lock():
	if $Matrix/GridMap.lock(current_piece):
		var lines_cleared = $Matrix/GridMap.clear_lines()
		$Stats.piece_locked(lines_cleared, current_piece.t_spin)
		if lines_cleared or current_piece.t_spin:
			$MidiPlayer.piece_locked(lines_cleared)
		remove_child(current_piece)
		new_piece()
	else:
		game_over()

func hold():
	if not current_piece_held:
		current_piece_held = true
		var swap = current_piece
		current_piece = held_piece
		held_piece = swap
		held_piece.emit_trail(false)
		held_piece.translation = $Hold/Position3D.translation
		if current_piece:
			current_piece.translation = $Matrix/Position3D.translation
			current_piece.emit_trail(true)
		else:
			new_piece()
		
func resume():
	playing = true
	$DropTimer.start()
	$LockDelay.start()
	$Stats.time = OS.get_system_time_secs() - $Stats.time
	$Stats/Clock.start()
	$MidiPlayer.resume()
	$controls_ui.visible = false
	$Stats.visible = true
	$Matrix.visible = true
	$Hold.visible = true
	$Next.visible = true
	current_piece.visible = true
	if held_piece:
		held_piece.visible = true
	next_piece.visible = true

func pause(gui=null):
	playing = false
	$MidiPlayer.stop()
	$DropTimer.stop()
	$LockDelay.stop()
	$AutoShiftDelay.stop()
	$AutoShiftTimer.stop()
	$Stats/Clock.stop()
	$Stats.time = OS.get_system_time_secs() - $Stats.time
	if gui:
		gui.visible = true
		$Stats.visible = false
		$Matrix.visible = false
		$Hold.visible = false
		$Next.visible = false
		current_piece.visible = false
		if held_piece:
			held_piece.visible = false
		next_piece.visible = false

func game_over():
	pause()
	current_piece.emit_trail(false)
	$FlashText.print("GAME\nOVER")
	$ReplayButton.visible = true

func _on_ReplayButton_pressed():
	pause($Start)
	$ReplayButton.visible = false
	
func _notification(what):
	match what:
		MainLoop.NOTIFICATION_WM_FOCUS_OUT:
			if playing:
				pause($controls_ui)
