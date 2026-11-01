extends Control

@onready var bg_texture_rect: TextureRect = $BGTextureRect
@onready var speaker_name_label: Label = $SpeakerNameLabel
@onready var dialog_label: RichTextLabel = $DialogLabel
@onready var next_button: TextureButton = $NextButton

@onready var options_container: VBoxContainer = $Options/VBoxContainer

@onready var speaker_anchor: Node2D = $SpeakerAnchor
@onready var speaker_sprite: Sprite2D = $SpeakerSprite

@onready var vn_ui_option_scene: PackedScene = preload("res://src/scenes/ui/vn_ui_option.tscn")

var current_vn_section: VNM.VNSection

#var active_tweens: Array[Tween] = []

var dialog_revealed: bool = false

# Tweens MAKE SURE THESE ALL GET KILLED IN kill_all_tweens()
var dialog_tween: Tween 
var speaker_entry_anim_tween: Tween
var speaker_anim_tween: Tween

# speaker
var speaker_texture_size: Vector2
var speaker_anchor_pos: Vector2
var bottom_of_screen_speaker_pos: Vector2
var speaker_anim_delay: float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	speaker_texture_size = speaker_sprite.texture.get_size()
	speaker_anchor_pos = speaker_anchor.global_position
	bottom_of_screen_speaker_pos = Vector2(speaker_anchor_pos.x, speaker_anchor_pos.y + speaker_texture_size.y)
	
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
	dialog_tween.tween_interval(current_vn_section.typewrite_delay)
	dialog_tween.finished.connect(on_dialog_finished)
	
	# VISUAL SETUP
	speaker_name_label.text = current_vn_section.vn_speaker.display_name
	
	speaker_sprite.texture = load(current_vn_section.vn_mood.texture_path)
	
	play_speaker_entry_animation() # this will start the repeating speaker animation later
	hide_next_button()
	hide_options()
	
	# TWEENING, FUNCTIONING
	run_typewriter_code(current_vn_section)
	load_options()
	
func play_speaker_entry_animation():
	var anim: VNM.VNSection.speaker_entry_animations = current_vn_section.speaker_entry_animation
	speaker_entry_anim_tween = create_tween()
	match anim:
		VNM.VNSection.speaker_entry_animations.JUMP_FROM_BOTTOM:
			speaker_sprite.global_position = bottom_of_screen_speaker_pos # just off screen at the bottom
			speaker_entry_anim_tween.tween_property(speaker_sprite, "global_position:y", speaker_anchor.global_position.y, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		VNM.VNSection.speaker_entry_animations.JUMP_WEAK:
			#speaker_sprite.global_position = Vector2(speaker_anchor_pos.x, (bottom_of_screen_speaker_pos.y + speaker_anchor_pos.y) / 3.0) # top 3rd section
			var jump_offset: float = 25
			speaker_entry_anim_tween.tween_property(speaker_sprite, "global_position:y", speaker_anchor.global_position.y - jump_offset, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			speaker_entry_anim_tween.tween_property(speaker_sprite, "global_position:y", speaker_anchor.global_position.y, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		VNM.VNSection.speaker_entry_animations.JUMP_STRONG:
			var jump_offset: float = 100
			# speaker_sprite.global_position = Vector2(speaker_anchor_pos.x, (bottom_of_screen_speaker_pos.y + speaker_anchor_pos.y) / 3.0) # top 3rd section
			speaker_entry_anim_tween.tween_property(speaker_sprite, "global_position:y", speaker_anchor.global_position.y - jump_offset, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			speaker_entry_anim_tween.tween_property(speaker_sprite, "global_position:y", speaker_anchor.global_position.y, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	# if speaker has a repeating anim, play it once entry animation is over after a delay
	if current_vn_section.speaker_animation != VNM.VNSection.speaker_animations.NONE:
		speaker_entry_anim_tween.finished.connect(func():
			await get_tree().create_timer(speaker_anim_delay).timeout # delay
			play_speaker_animation()
		)
	
func play_speaker_animation(): # these anims are meant to run over and over; repeating
	var anim: VNM.VNSection.speaker_animations = current_vn_section.speaker_animation
	speaker_anim_tween = create_tween()
	match anim:
		VNM.VNSection.speaker_animations.BOB_WEAK:
			var amplitude: float = 2.5
			var frequency: float = 2.0
			var bottom_y: float = speaker_anchor_pos.y + amplitude
			var top_y: float = speaker_anchor_pos.y - amplitude
			speaker_anim_tween.tween_property(speaker_sprite, "global_position:y", top_y, frequency).set_trans(Tween.TRANS_CUBIC)
			speaker_anim_tween.tween_property(speaker_sprite, "global_position:y", bottom_y, frequency).set_trans(Tween.TRANS_CUBIC)
	
	speaker_anim_tween.finished.connect(play_speaker_animation) # run over and over

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
	
	#active_tweens.append(dialog_tween)
	
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
	#active_tweens.erase(dialog_tween)
	
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
	#for tween: Tween in active_tweens:
		#tween.kill()
	#active_tweens.clear()
	if dialog_tween: dialog_tween.kill()
	if speaker_entry_anim_tween: speaker_entry_anim_tween.kill()
	if speaker_anim_tween: speaker_anim_tween.kill()


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
		
		
