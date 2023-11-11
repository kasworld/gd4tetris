extends PanelContainer

func init(rt :Rect2, ver :String)->void:
	position = rt.position
	size = rt.size
	$VBoxContainer/VersionLabel.text = ver
	theme.default_font_size = rt.size.y /4

func show_message(msg :String, sec :float = 3)->void:
	$VBoxContainer/Label.text = msg
	visible = true
	$Timer.start(sec)

func _on_timer_timeout() -> void:
	visible = false
