extends Node2D

func _ready() -> void:
	get_tree().create_timer(0.5) # time to create save meta file if need be
	SaveManager.create_save("first save")
	var new_save_id: int = SaveManager.save.id
	SaveManager.save.testing_var = "I have updated!"
	SaveManager.save_game()
	
	# creation example
	SaveManager.create_save("first save")
	SaveManager.save.testing_var = "this is how you update me"
	SaveManager.save_game()
	
	# loading example
	var save_meta_data: Dictionary = SaveManager.load_save_meta_file()[1] # 0 gets the config file itself, 1 gets the config file converted to a dict like so:
	# 0: {
	# 	 "save_name": "bingus"
	#	 "save_path: "..."
	# }
	# if the target save name is "bingus," open 0
	SaveManager.load_game(0) 
