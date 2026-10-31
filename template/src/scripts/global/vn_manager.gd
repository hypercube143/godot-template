extends Node

const VN_DIR: String = "data/vn/"
const VN_SETTINGS_FILENAME: String = VN_DIR + "settings.ini"
const VN_SPEAKERS_FILENAME: String = VN_DIR + "speakers.ini"

var vn_act_file: ConfigFile
var vn_settings_file: ConfigFile
var vn_speakers_file: ConfigFile

var speakers: Dictionary[String, VNSpeaker] = {}

enum ACTS {I, II, III} # represented as I.ini in file form

var current_section_id: int = 0 # the [section] eg [0] as .ini section

# default values TODO: these will be loaded from settings file
var default_speaking_rate: float = 25 

func load_vn_act_file(act: ACTS) -> void:
	var act_string: String = Util.enum_name_as_string(ACTS, act) # "I", "II" etc.
	vn_act_file = ConfigFile.new()
	var filename: String = VN_DIR + act_string + ".ini"
	var err: Error = vn_act_file.load(filename)
	if err != OK:
		push_error("failed to load vn act file " + "'" + filename + "'")
		
func load_vn_settings_file() -> void:
	vn_settings_file = ConfigFile.new()
	var err: Error = vn_settings_file.load(VN_SETTINGS_FILENAME)
	if err != OK:
		push_error("failed to load vn settings file " + "'" + VN_SETTINGS_FILENAME + "'")
		
func load_vn_speakers_file() -> void:
	vn_speakers_file = ConfigFile.new()
	var err: Error = vn_speakers_file.load(VN_SPEAKERS_FILENAME)
	if err != OK:
		push_error("failed to load vn speakers file " + "'" + VN_SPEAKERS_FILENAME + "'")
		return
	
	print("loading speakers")
	var speaker: VNSpeaker
	for section: String in vn_speakers_file.get_sections():
		
		var section_components: PackedStringArray = section.split(".")
		var speaker_key: String = section_components[0]
		
		if not section.contains("."): # if just the speaker name
			speaker = VNSpeaker.new()
			var display_name: String = vn_speakers_file.get_value(section, "display_name", "") # empty name if not specified
			var default_speaking_rate: float = vn_speakers_file.get_value(section, "default_speaking_rate", default_speaking_rate) # if left unspecified default speaking rate is 25
			speaker.setup(display_name, default_speaking_rate)
		
		if len(section_components) > 1:
			if section_components[1] == "mood": # setting each mood
				var speaking_rate: float = vn_speakers_file.get_value(section, "speaking_rate", default_speaking_rate)
				var texture: String = vn_speakers_file.get_value(section, "texture", default_speaking_rate)
				var mood_key: String = section_components[2]
				speaker.add_mood(mood_key, speaking_rate, texture)
			
			
			if section_components[1] == "end": # closing, creating speaker, adding to list. there's probably a better way to determine the end of a speaker?
				speakers[speaker_key] = speaker # not sure if .duplicate() is necessary here
				print("added speaker: " + str(speaker))
		print(section)
				
		print(speaker)
		

class VNOption:
	var text: String
	var next: int
	func _init(t: String, n: int) -> void:
		text = t
		next = n
	func _to_string() -> String:
		return 'VNOption(text = "{text}", next = {next})'.format({"text": text, "next": next})

class VNSection:
	# necessary to implement
	var str_id: String
	var dialog: String
	var speaker_str: String
	var auto_skip: bool
	var time: float
	var next: int 
	var sections: PackedStringArray
	var options: Array[VNOption]
	
	# NON NECESSARY / SCOPE CREEP STUFF / FOR THE FUTURE
	enum moods {DEFAULT, HAPPY, SAD} # TODO
	var mood: moods
	
	func _init(config_file: ConfigFile, id: int) -> void:
		parse_from_config(config_file, id)
		
	func parse_from_config(config_file: ConfigFile, id: int) -> void:
		if config_file:
			str_id = str(id)
			
			# NOTE: reference and explanation of .ini values:
			
			# dialog the speaker says
			# if not specified, dialog will be empty
			dialog = config_file.get_value(str_id, "dialog", "") 
			
			# string of the speaker, to be converted into speaker class TODO
			# if not specified, becomes narrator/diconnected voice?
			speaker_str = config_file.get_value(str_id, "speaker", "narrator")
			
			# "auto_skip": whether program will wait for user to press enter or ok.
			# if true, won't wait for and ok, and will skip after "time" in seconds.
			# true is intended to be something like an interruption or a soliloquy
			# if not specified, will default to false: program will have to wait for and ok
			auto_skip = config_file.get_value(str_id, "auto_skip", false) 
			
			# time in seconds text is displayed for until OK option is ready,
			# or whenever next event occurs
			# if not specified, defaults to skipping instantly
			time = config_file.get_value(str_id, "time", 0)
			
			# the section loaded after dialog finishes or ok occurs 
			# if not specified, will be treated as the final dialog
			# number for termination = -1, TODO what comes after that?
			next = config_file.get_value(str_id, "next", -1)
			
			# load options
			options = []
			sections = config_file.get_sections()
			for section: String in sections:
				if section.begins_with(str_id + ".option."): # option keys look like x.option.n eg 0.option.1 for first option
					
					# display text of option
					# if not specified, set to empty text
					var option_text: String = config_file.get_value(section, "text", "")
					
					# the section loaded when option selected
					# same as "next" value elsewhere
					
					#Util.dprint("trying to load 'next' for section '" + section + "'")
					var option_next: int = config_file.get_value(section, "next", -1)	
				
					var option: VNOption = VNOption.new(option_text, option_next)
					options.append(option)
					
			
			# NON NECESSARY / SCOPE CREEP STUFF TODO
			# convert mood name to value. for example "HAPPY" will become 1
			var mood_str: String = config_file.get_value(str_id, "mood", Util.enum_name_as_string(moods, moods.DEFAULT))
			var mood_value: moods = moods.get(mood_str) # this is an int
			mood = mood_value
	
	func _to_string() -> String:
		return "VNSection(\n\tdialog = {dialog}\n\tspeaker = {speaker}\n\tauto_skip = {auto_skip}\n\ttime = {time}\n\tnext = {next}\n\tsections = {sections}\n\toptions = {options}\n\tmood = {mood}\n)".format(
			{
				"dialog": dialog,
				"speaker": speaker_str,
				"auto_skip": auto_skip,
				"time": time,
				"next": next,
				"sections": sections,
				"options": options,
				
				"mood": mood
			}
		)

class VNSpeaker:
	var display_name: String
	var default_speaking_rate: float
	var moods: Dictionary[String, VNMood]
		
	func setup(dn: String, dsr: float) -> void:
		display_name = dn
		default_speaking_rate = dsr
	
	func add_mood(key: String, speaking_rate: float, texture: String):
		moods[key] = VNMood.new(key, speaking_rate, texture)
		
	func _to_string() -> String:
		return "VNSpeaker(\n\tdisplay_name = {display_name}\n\tdefault_speaking_rate = {default_speaking_rate})\n\tmoods = {moods}\n".format({
			"display_name": display_name,
			"default_speaking_rate": default_speaking_rate,
			"moods": moods
		})

class VNMood:
	var key: String
	var speaking_rate: float
	var texture: String
	func _init(k: String, sr: float, t: String) -> void:
		key = k
		speaking_rate = speaking_rate
		texture = t
	# TODO

func _enter_tree() -> void:
	print("VN MANAGER ENTERED TREE")

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(VN_DIR))
	
	print("starting loading vn files")
	load_vn_settings_file()
	load_vn_speakers_file()
	print(speakers)
	load_vn_act_file(ACTS.I)
	print("finished loading vn files")
	
	#load_vn_script(ACTS.I)
	#var vn_section0: VNSection = VNSection.new(vn_config_file, 0) 
	#
	#print(vn_section0)
	
	#Util.dprint("option 1 next = " + str(vn_section0.options[0].next))
	#var vn_section1: VNSection = VNSection.new(vn_config_file, vn_section0.options[0].next)
	
