extends Control

@onready var bg_texture_rect: TextureRect = $BGTextureRect
@onready var speaker_name_label: Label = $SpeakerNameLabel
@onready var dialog_label: RichTextLabel = $DialogLabel
@onready var next_button: TextureButton = $NextButton

@onready var options_container: VBoxContainer = $Options/VBoxContainer

@onready var vn_ui_option_scene: PackedScene = preload("res://src/scenes/ui/vn_ui_option.tscn")

var current_vn_section: VNM.VNSection

var active_tweens: Array[Tween] = []

var dialog_revealed: bool = false

# Tweens
var dialog_tween: Tween 


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# on next button press, go to next section
	next_button.pressed.connect(move_to_next_section)
	
	next_button.visible = false
	options_container.visible = false
	VNM.load_vn_act_file(VNM.ACTS.I)
	activate_vn_section(0)
	
	
func activate_vn_section(id: int):
	current_vn_section = VNM.VNSection.new(id)
	
	# Tweens
	dialog_tween = create_tween()
	dialog_tween.finished.connect(on_dialog_finished)
	
	
	# VISUAL SETUP
	speaker_name_label.text = current_vn_section.vn_speaker.display_name
	
	hide_next_button()
	hide_options()
	
	# TWEENING, FUNCTIONING
	run_typewriter_code(current_vn_section)
	load_options()


func run_typewriter_code(vn_section: VNM.VNSection):
	
	print("running typewriter code")
	
	
	# TODO get below values
	# MAKE SURE to use dialog_label.get_parsed_text()
	var dialog: String = vn_section.dialog
	var code: String = vn_section.typewriter_code 
	
	var char_cursor: int = 0
	
	dialog_label.visible_ratio = 0.0
	dialog_label.text = dialog
	# all of dialog is hidden at this stage
	dialog_revealed = false
	
	active_tweens.append(dialog_tween)
	
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
			
			var time: float = (1.0 / chars_per_second) * val # time it takes to typewrite 'val' many chars according to 'chars_per_second'
			
			dialog_tween.tween_property(dialog_label, "visible_ratio", visible_ratio, time)
			
		if mode == "p": # pause for val seconds
			dialog_tween.tween_interval(val)

func on_dialog_finished():
	
	Util.dprint("dialog finished!")
	
	dialog_revealed = true
	# dialog tween is no longer active
	active_tweens.erase(dialog_tween)
	
	if current_vn_section.has_next:
		show_next_button()
	
	if current_vn_section.has_options:
		show_options()
	

func hide_next_button():
	# TODO animation here maybe
	next_button.visible = false
	
func show_next_button():
	# TODO animatioin here maybe
	next_button.visible = true
	
func show_options():
	# TODO animation here
	options_container.visible = true
		
func load_options():
	for option: VNM.VNOption in current_vn_section.options:
		var vn_ui_option: VN_UI_Option = vn_ui_option_scene.instantiate()
		options_container.add_child(vn_ui_option)
		
		vn_ui_option.setup(option.text, option.next)
		vn_ui_option.texture_button.pressed.connect(func(): option_pressed(option))
	
		
func hide_options():
	# TODO animation here
	for vn_ui_option: VN_UI_Option in options_container.get_children():
		vn_ui_option.queue_free()
		
func option_pressed(vn_option: VNM.VNOption):
	Util.dprint("vn option pressed: " + vn_option.text)
	activate_vn_section(vn_option.next)

func kill_all_tweens():
	for tween: Tween in active_tweens:
		tween.kill()
	active_tweens.clear()


func skip_current_dialog_typewriting():
	kill_all_tweens()
	# cannot skip if not skippable
	if not current_vn_section.skippable:
		print("tried to skip but this VNSection is unskippable")
		return
	
	print("forcing text to load")
	dialog_label.visible_ratio = 1.0
	dialog_revealed = true
	
	if not next_button.visible and current_vn_section.has_next:
		show_next_button()


func move_to_next_section():
	kill_all_tweens()
	if current_vn_section.has_next:
		activate_vn_section(current_vn_section.next)
	else:
		print("nothing next - options maybe?")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("accept"):
		
		print("interrupt")
		
		# move on to next section
		if dialog_revealed:
			move_to_next_section()
		else: # impatiently pressing enter to skip typewriting
			skip_current_dialog_typewriting()
		
		
