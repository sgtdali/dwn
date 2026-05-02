extends PanelContainer

@onready var title_label: Label = %TitleLabel
@onready var value_label: Label = %ValueLabel


func configure(title: String, value: String, value_color: Color, title_color: Color) -> void:
	_bind_nodes()
	title_label.text = title
	title_label.add_theme_color_override("font_color", title_color)
	value_label.text = value
	value_label.add_theme_color_override("font_color", value_color)


func _bind_nodes() -> void:
	if title_label == null:
		title_label = get_node("%TitleLabel") as Label
	if value_label == null:
		value_label = get_node("%ValueLabel") as Label
