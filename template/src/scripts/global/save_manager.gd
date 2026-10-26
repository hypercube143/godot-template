extends Node

# intended for game saving & loading

var save: Save

const SAVE_LOCATION: String = "res://data/saves/"
const SAVES_META_FILENAME: String = "saves_meta"
const SAVES_META_FILEPATH: String = SAVE_LOCATION + SAVES_META_FILENAME + ".ini"
# alernative location = "user://"
# IMPORTANT NOTE: If this file stores save-game metadata that changes at runtime, use user://data/saves/saves.ini rather than res://, since exported game resources may be read-only.

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_LOCATION))
	if not save_meta_file_exists():
		create_save_meta_file()
		Util.dprint("save meta file created as one didn't exist")
	Util.dprint(SAVES_META_FILEPATH)

func get_save_path_from_id(save_id: int):
	return SAVE_LOCATION + str(save_id) + ".res"

func create_save(save_name: String):
	save = Save.new()
	var save_id: int = len(get_all_save_file_names())
	save.id = save_id
	save.save_name = save_name
	save.save_path = get_save_path_from_id(save_id)
	var timestamp_now: float = Time.get_unix_time_from_system()
	save.save_created_timestamp = timestamp_now
	save.save_updated_timestamp = timestamp_now
	SignalBus.save_created.emit()
	Util.dprint("created save for '" + save_name + "'. Yet to save to file")
	
func delete_save(save_filename: String):
	#var error = DirAccess.remove_absolute(SAVE_LOCATION + save_filename)
	var path = SAVE_LOCATION + save_filename
	var error = DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if error == OK:
		Util.dprint("deleted save file " + save_filename + " successfully")
		SignalBus.delete_complete.emit()
	else:
		Util.dprint("unable to delete save file " + save_filename)
		SignalBus.delete_failed.emit(error)

func save_game():
	save.save_updated_timestamp = Time.get_unix_time_from_system()
	var error = ResourceSaver.save(save, save.save_path)
	if error == OK:
		save_save_meta_file()
		Util.dprint("save complete for '" + save.save_name + "' (" + save.save_path + ")")
		SignalBus.save_complete.emit()
	else:
		Util.dprint("save failed for '" + save.save_name + "' (" + save.save_path + ")")
		SignalBus.save_failed.emit(error)

func load_game(save_id: int):
	# load all save's variables into game_save and into game
	Util.dprint("Attempting to load game. save_id=" + str(save_id))
	Util.dprint("List of existing save filepaths: ", get_all_save_file_names())
	var save_path: String
	save_path = get_save_path_from_id(save_id)
	if ResourceLoader.exists(save_path):
		var resource = ResourceLoader.load(save_path)
		if resource is Save:
			save = resource.duplicate(true) as Save
			Util.dprint("data loaded for '" + save.save_name + "' (" + save.save_path + ")" + "of id=" + str(save.id))
			SignalBus.load_complete.emit()
		else:
			Util.dprint("no data in save file for '" + save.save_name + "' (" + save.save_path + ")? :(")
			SignalBus.load_failed.emit()
	else:
		Util.dprint("failed loading save. path '" + save_path + "' does not exist!")

func get_all_save_file_names() -> Array[String]:
	var files: Array[String] = []
	var dir = DirAccess.open(SAVE_LOCATION)
	if dir == null:
		return files
	dir.list_dir_begin()
	var filename := dir.get_next()
	while filename != "":
		if not dir.current_is_dir() and filename.ends_with(".res"):
			files.append(filename)
		filename = dir.get_next()
	dir.list_dir_end()
	return files
	
func create_save_meta_file():
	var config = ConfigFile.new()
	var err = config.save(SAVES_META_FILEPATH)
	if err != OK:
		push_error("Failed to create INI file: %s" % err)
	
func load_save_meta_file():
	var config = ConfigFile.new()
	var err = config.load(SAVES_META_FILEPATH)

	if err != OK:
		push_warning("Failed to load saves_meta.ini: %s" % err)
		return [null, {}]
	
	var saves_dict: Dictionary = {}

	for section in config.get_sections():
		saves_dict[int(section)] = {
			"save_name": config.get_value(section, "save_name", ""),
			"save_path": config.get_value(section, "save_path", ""),
			"created_timestamp": config.get_value(section, "created_timestamp", 0),
			"updated_timestamp": config.get_value(section, "updated_timestamp", 0),
			"thumbnail": config.get_value(section, "thumbnail", "")
		}

	return [config, saves_dict]
	
func save_save_meta_file():
	var config_file: ConfigFile = load_save_meta_file()[0]
	
	config_file.set_value(str(save.id), "save_name", save.save_name)
	config_file.set_value(str(save.id), "save_path", save.save_path)
	config_file.set_value(str(save.id), "created_timestamp", save.save_created_timestamp)
	config_file.set_value(str(save.id), "updated_timestamp", save.save_updated_timestamp)
	config_file.set_value(str(save.id), "thumbnail", save.thumbnail_path)
	
	config_file.save(SAVES_META_FILEPATH)
	
func save_meta_file_exists() -> bool:
	return FileAccess.file_exists(SAVES_META_FILEPATH)


# EXAMPLES

# example saves_meta.ini	
#[0]
# save_name = first save
# save_path = res://data/saves/0.res
# created_timestamp = 12039812098
# updated_timestamp = 23948023948
# thumbnail = res://data/saves/thumbnails/0.png

# creation example
# SaveManager.create_save("first save")
# SaveManager.save.testing_var = "this is how you update me"
# SaveManager.save_game()

# loading example
# var save_meta_data: Dictionary = SaveManager.load_save_meta_file()[1] # 0 gets the config file itself, 1 gets the config file converted to a dict like so:
# 0: {
#	 "save_name": "bingus"
#	 "save_path: "..."
# }
# if the target save name is "bingus," open 0
# SaveManager.load_game(0) 
