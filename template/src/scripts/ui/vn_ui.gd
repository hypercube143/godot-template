extends Control

@onready var bg_texture_rect: TextureRect = $BGTextureRect
@onready var speaker_name_label: Label = $SpeakerNameLabel
@onready var dialog_label: RichTextLabel = $DialogLabel
@onready var next_button: TextureButton = $NextButton

var current_vn_section: VNM.VNSection

var active_tweens: Array[Tween] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	## TODO move to more appropriate section later
	VNM.load_vn_act_file(VNM.ACTS.I)
	var vn_section: VNM.VNSection = VNM.VNSection.new(0)
	print(vn_section)
	
	speaker_name_label.text = vn_section.vn_speaker.display_name
	#dialog_label.text = vn_section.dialog
	#
	#dialog_label.visible_ratio = 0.0
	#var speaking_rate: float = vn_section.vn_mood.speaking_rate
	#var total_dialog_chars: int = len(vn_section.dialog)
	#var total_parsed_dialog_chars: int = len(dialog_label.get_parsed_text())
	#var dialog_time: float = (1.0 / speaking_rate) * total_parsed_dialog_chars
	#create_tween().tween_property(dialog_label, "visible_ratio", 1.0, dialog_time)
	
	run_typewriter_code(vn_section)
	
	
	
	pass
	
func run_typewriter_code(vn_section: VNM.VNSection):
	
	# TODO get below values
	# MAKE SURE to use dialog_label.get_parsed_text()
	var dialog: String = vn_section.dialog
	var code: String = vn_section.typewriter_code 
	
	var char_cursor: int = 0
	
	dialog_label.visible_ratio = 0.0
	dialog_label.text = dialog
	
	for component: String in code.split(","):
		var a: PackedStringArray = component.split(":")
		var mode: String = a[0]
		var val: int
		
		var chars_per_second: int
		var visible_ratio: float = 0.0
		
		var dialog_length: int = len(dialog_label.get_parsed_text())
		
		if len(a) > 2:
			chars_per_second = int(a[2])
		if len(a) > 1:
			val = int(a[1])
		else:
			chars_per_second = vn_section.vn_speaker.default_speaking_rate
			val = -1 # no value was provided, default to -1
		print(component + " = " + "mode=" + mode + ", val=" + str(val))
		
		if mode == "t": # typewrite for val chars
			if val == -1: # typewrite until the end
				visible_ratio = 1.0
				val = dialog_length - char_cursor 
			else: # typewrite until val
				char_cursor += val
				visible_ratio = char_cursor / float(dialog_length)
				print(visible_ratio)
				print(char_cursor)
				print(dialog_length)
			var time: float = (1.0 / chars_per_second) * val # time it takes to typewrite 'val' many chars according to 'chars_per_second'
			var dialog_tween: Tween = create_tween()
			
			active_tweens.append(dialog_tween)
			dialog_tween.tween_property(dialog_label, "visible_ratio", visible_ratio, time)
			dialog_tween.finished.connect(func(): active_tweens.erase(dialog_tween))
			await get_tree().create_timer(time).timeout
		if mode == "p": # pause for val seconds
			await get_tree().create_timer(val).timeout
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func kill_all_tweens():
	for tween: Tween in active_tweens:
		tween.kill()
	active_tweens.clear()
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("accept"):
		print("interrupt")
		kill_all_tweens()
		
		
		
