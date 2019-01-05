extends "midi/MidiPlayer.gd"

const Tetromino = preload("res://Tetrominos/Tetromino.gd")

const LINE_CLEAR_CHANNELS = [2, 6]
const MOVE_CHANNELS = [3]

func _ready():
	mute_channels(MOVE_CHANNELS+LINE_CLEAR_CHANNELS)

func resume():
	play(position)
	
func mute_channels(channels):
	for channel_id in channels:
		channel_mute[channel_id] = true
		
func unmute_channels(channels):
	for channel_id in channels:
		channel_mute[channel_id] = false
		for note in muted_events[channel_id]:
			_process_track_event_note_on(channel_status[channel_id], muted_events[channel_id][note])

func move():
	unmute_channels(MOVE_CHANNELS)
	mute_channels(MOVE_CHANNELS)

func _on_Main_piece_locked(lines, t_spin):
	if lines or t_spin:
		if lines == Tetromino.NB_MINOES:
			for channel in LINE_CLEAR_CHANNELS:
				channel_status[channel].vomume = 127
			$LineCLearTimer.wait_time = 0.86
		else:
			for channel in LINE_CLEAR_CHANNELS:
				channel_status[channel].vomume = 100
			$LineCLearTimer.wait_time = 0.43
		unmute_channels(LINE_CLEAR_CHANNELS)
		$LineCLearTimer.start()

func _on_LineCLearTimer_timeout():
	mute_channels(LINE_CLEAR_CHANNELS)