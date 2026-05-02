extends PanelContainer

@onready var title_label: Label = %TitleLabel
@onready var body: VBoxContainer = %Body


func configure(title: String, title_color: Color) -> VBoxContainer:
	_bind_nodes()
	title_label.text = title
	title_label.add_theme_color_override("font_color", title_color)
	return body


func _bind_nodes() -> void:
	if title_label == null:
		title_label = get_node("%TitleLabel") as Label
	if body == null:
		body = get_node("%Body") as VBoxContainer
