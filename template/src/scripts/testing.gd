extends Node2D

func _ready() -> void:
	get_tree().create_timer(0.5) # time to create save meta file if need be
	SaveManager.create_save("save")
	var new_save_id: int = SaveManager.save.id
	SaveManager.save_game()
