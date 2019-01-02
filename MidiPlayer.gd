extends "midi/MidiPlayer.gd"

const LINE_CLEAR_MIDI_CHANNELS = [2, 6]

func _on_Main_piece_locked(lines, t_spin):
	if lines or t_spin:
		if lines == Tetromino.NB_MINOES:
			for channel in LINE_CLEAR_MIDI_CHANNELS:
				channel_status[channel].vomume = 127
			$LineCLearTimer.wait_time = 0.86
		else:
			for channel in LINE_CLEAR_MIDI_CHANNELS:
				channel_status[channel].vomume = 100
			$LineCLearTimer.wait_time = 0.43
		unmute_channels(LINE_CLEAR_MIDI_CHANNELS)
		$LineCLearTimer.start()

func _on_LineCLearTimer_timeout():
	mute_channels(LINE_CLEAR_MIDI_CHANNELS)
