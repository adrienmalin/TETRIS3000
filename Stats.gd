extends MarginContainer

const password= "TETRIS 3000"

var level
var goal
var score
var high_score
var time
var combos

func _ready():
	var save_game = File.new()
	if not save_game.file_exists("user://high_score.save"):
		high_score = 0
	else:
		save_game.open_encrypted_with_pass("user://high_score.save", File.READ, password)
		high_score = int(save_game.get_line())
		$HBC/VBC1/HighScore.text = str(high_score)
		save_game.close()
	
func new_game():
	level = 0
	goal = 0
	score = 0
	time = 0
	combos = -1
	
func new_level():
	level += 1
	goal += 5 * level
	$HBC/VBC1/Level.text = str(level)
	$HBC/VBC1/Goal.text = str(goal)
	
func update_score(new_score):
		score += 100 * new_score
		$HBC/VBC1/Score.text = str(score)
		goal -= new_score
		$HBC/VBC1/Goal.text = str(goal)
		if score > high_score:
			high_score = score
			$HBC/VBC1/HighScore.text = str(high_score)

func _on_Clock_timeout():
	var time_elapsed = OS.get_system_time_secs() - time
	var seconds = time_elapsed % 60
	var minutes = int(time_elapsed/60) % 60
	var hours = int(time_elapsed/3600)
	$HBC/VBC1/Time.text = str(hours) + ":%02d"%minutes + ":%02d"%seconds


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		var save_game = File.new()
		save_game.open_encrypted_with_pass("user://high_score.save", File.WRITE, password)
		save_game.store_line(str(high_score))
		save_game.close()
		get_tree().quit()