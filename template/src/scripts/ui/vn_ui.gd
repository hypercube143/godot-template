extends Control

@onready var bg_texture_rect: TextureRect = $BGTextureRect
@onready var speaker_name_label: Label = $SpeakerNameLabel
@onready var dialog_label: RichTextLabel = $DialogLabel
@onready var next_button: TextureButton = $NextButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#VNManager.load_vn_script(VNManager.ACTS.I)
	#var vn_section: VNManager.VNSection = VNManager.VNSection.new(VNManager.vn_config_file, 0) 
	#
	#speaker_name_label.text = vn_section.speaker_str
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
