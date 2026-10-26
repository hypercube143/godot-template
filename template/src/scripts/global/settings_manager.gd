extends Node
# responsible for settings: storing and editting

const SETTINGS_FILENAME: String = "settings"
const SETTINGS_DIR: String = "res://data/settings/"
const SETTINGS_FILEPATH: String = SETTINGS_DIR + SETTINGS_FILENAME + ".ini"

var settings_config: ConfigFile


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SETTINGS_DIR))
	if not settings_config_exists():
		create_settings_config()
	else:
		load_settings_config()


func _set_init_values():
	settings_config.set_value("audio", "master_volume", 0.5) # middle 0-1
	settings_config.set_value("audio", "music_volume", 0.5)
	settings_config.set_value("audio", "sfx", 0.5)


func create_settings_config():
	settings_config = ConfigFile.new()
	_set_init_values()
	var err: Error = settings_config.save(SETTINGS_FILEPATH)
	if err != OK:
		push_warning("could not create and save settings file")


func load_settings_config():
	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load(SETTINGS_FILEPATH)
	if err != OK:
		push_warning("unable to load settings file")
	else:
		settings_config = config


func update_value(section: String, key: String, value) -> void:
	if settings_config:
		settings_config.set_value(section, key, value)
		settings_config.save(SETTINGS_FILEPATH)
	else:
		push_warning("'" + key + "' not updated. settings file not loaded")


func get_value(section: String, key: String) -> Variant:
	if settings_config:
		var value: Variant = settings_config.get_value(section, key)
		if not value:
			push_warning("retrieved settings key '" + key + "' as null")
		return value
	else:
		push_warning("settings file not currently loaded. retrieving '" + key + "' as null")
		return null

func settings_config_exists():
	return FileAccess.file_exists(SETTINGS_FILEPATH)
