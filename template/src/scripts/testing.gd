extends Node2D

func _ready() -> void:
	#get_tree().create_timer(0.5) # time to create save meta file if need be
	#SaveManager.create_save("save")
	#var new_save_id: int = SaveManager.save.id
	#SaveManager.save_game()
	
	get_tree().create_timer(0.5)
	var master_volume: float = SettingsManager.get_value("audio", "master_volume")
	Util.dprint(str(master_volume))
	SettingsManager.update_value("audio", "master_volume", master_volume + 0.1)
