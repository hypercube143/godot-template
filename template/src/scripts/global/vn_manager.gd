extends Node

const VN_DIR: String = "data/vn/"

var vn_config_file: ConfigFile

enum ACTS {I, II, III} # represented as I.ini in file form

var current_section_id: int = 0 # the [section] eg [0] as .ini section

func load_vn_script(act: ACTS) -> void:
	var act_string: String = Util.enum_name_as_string(ACTS, act) # "I", "II" etc.
	vn_config_file = ConfigFile.new()
	var filename: String = VN_DIR + act_string + ".ini"
	var err: Error = vn_config_file.load(filename)
	if err != OK:
		push_error("couldn't load vn file " + "'" + filename + "'")

class VNOption:
	var text: String
	var next: int
	func _init(t: String, n: int) -> void:
		text = t
		next = n
	func _to_string() -> String:
		return 'VNOption(text = "{text}", next = {next})'.format({"text": text, "next": next})

class VNSection:
	var str_id: String
	var dialog: String
	var speaker_str: String
	var auto_skip: bool
	var time: float
	var next: int 
	var sections: PackedStringArray
	var options: Array[VNOption]
	
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
					
					Util.dprint("tyring to load 'next' for section '" + section + "'")
					var option_next: int = config_file.get_value(section, "next", -1)	
				
					var option: VNOption = VNOption.new(option_text, option_next)
					options.append(option)
			
			print("vn vals:\ndialog = {dialog}\nspeaker = {speaker}\nauto_skip = {auto_skip}\ntime = {time}\nnext = {next}\nsections = {sections}\noptions = {options}\n".format(
				{
					"dialog": dialog,
					"speaker": speaker_str,
					"auto_skip": auto_skip,
					"time": time,
					"next": next,
					"sections": sections,
					"options": options
				}
			))


func _ready() -> void:
	load_vn_script(ACTS.I)
	var vn_section0: VNSection = VNSection.new(vn_config_file, 0) 
	Util.dprint("option 1 next = " + str(vn_section0.options[0].next))
	var vn_section1: VNSection = VNSection.new(vn_config_file, vn_section0.options[0].next)
	
