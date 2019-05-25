extends PanelContainer

onready var diag_state = $diag_state
onready var label = $faders/label
onready var button = $button
onready var border = $faders/fancy_borders

var fade_amount = 0

var texts
var current_text = 0

func _ready():
	button.grab_focus()
	var screen_size = get_viewport_rect().size
	border.rect_size = screen_size
	diag_state.switch_state_immediately("appearing")
	
func init(texts):
	self.texts = texts

func _process(delta):
	diag_state.update(delta)
	
	material.set_shader_param("fade_amount", fade_amount)
	$faders.modulate = Color(1,1,1, fade_amount)

func _on_Button_pressed():
	diag_state.state.on_next()
