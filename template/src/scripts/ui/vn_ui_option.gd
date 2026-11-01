class_name VN_UI_Option extends Control

@onready var texture_button: TextureButton = $TextureButton
@onready var rich_text_label: RichTextLabel = $RichTextLabel

var text: String
var next_id: int
	
func setup(t: String, ni: int) -> void:
	# TODO add mode? say, one bg is green, the other red for example?
	text = t
	next_id = ni
	rich_text_label.text = text
	
