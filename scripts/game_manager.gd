extends Node

var score = 0

@onready var score_label: Label = $ScoreLabel


func add_point():
	score += 1
	score_label.text = "You collected " + str(score) + " coins."
	#saya mau buat jika score mencapai 10, munculkan pesan "You win!"
	if score >= 15:
		score_label.text = "You win!"
	if score == 10:
		score_label.text += "\nHalfway there!"
