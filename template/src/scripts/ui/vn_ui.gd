extends Control

@onready var bg_texture_rect: TextureRect = $BGTextureRect
@onready var speaker_name_label: Label = $SpeakerNameLabel
@onready var dialog_label: RichTextLabel = $DialogLabel
@onready var next_button: TextureButton = $NextButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	## TODO move to more appropriate section later
	#VNM.load_vn_act_file(VNM.ACTS.I)
	#var vn_section: VNM.VNSection = VNM.VNSection.new(0)
	#print(vn_section)
	#
	#speaker_name_label.text = vn_section.vn_speaker.display_name
	#dialog_label.text = vn_section.dialog
	#
	#dialog_label.visible_ratio = 0.0
	#var speaking_rate: float = vn_section.vn_mood.speaking_rate
	#var total_dialog_chars: int = len(vn_section.dialog)
	#var total_parsed_dialog_chars: int = len(dialog_label.get_parsed_text())
	#var dialog_time: float = (1.0 / speaking_rate) * total_parsed_dialog_chars
	#create_tween().tween_property(dialog_label, "visible_ratio", 1.0, dialog_time)
	
	run_typewriter_code(null)
	
	
	
	pass
	
func run_typewriter_code(vn_section: VNM.VNSection):
	
	# TODO get below values
	# MAKE SURE to use dialog_label.get_parsed_text()
	var dialog: String = "[color=green]this is ... a test[/color]"
	var chars_per_second: int = 10
	var code: String = "t:8,p:1,t:1,p:1,t:1,p:1,t:1,p:1,t"
	
	var char_cursor: int = 0
	
	dialog_label.visible_ratio = 0.0
	dialog_label.text = dialog
	
	for component: String in code.split(","):
		var a: PackedStringArray = component.split(":")
		var mode: String = a[0]
		var val: int
		if len(a) > 1:
			val = int(a[1])
		else:
			val = -1 # no value was provided, default to -1
		print(component + " = " + "mode=" + mode + ", val=" + str(val))
		
		if mode == "t": # typewrite for val chars
			if val == -1: # typewrite until the end
				var visible_ratio: float = 1.0
				var chars_left: int = len(dialog) - char_cursor 
				var time: float = (1.0 / chars_per_second) * chars_left
				create_tween().tween_property(dialog_label, "visible_ratio", visible_ratio, time)
			else:
				var time: float = (1.0 / chars_per_second) * val # time it takes to typewrite 'val' many chars according to 'chars_per_second'
				char_cursor += val
				var visible_ratio: float = char_cursor / float(len(dialog))
				print(visible_ratio)
				print(char_cursor)
				print(len(dialog))
				create_tween().tween_property(dialog_label, "visible_ratio", visible_ratio, time)
			
			
		if mode == "p": # pause for val seconds
			await get_tree().create_timer(val).timeout
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
