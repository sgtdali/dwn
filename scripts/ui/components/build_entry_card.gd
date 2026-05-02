extends PanelContainer

signal selected(entry_id: String)

@onready var name_label: Label = %NameLabel
@onready var quantity_label: Label = %QuantityLabel
@onready var description_label: Label = %DescriptionLabel
@onready var role_label: Label = %RoleLabel
@onready var output_label: Label = %OutputLabel
@onready var cost_label: Label = %CostLabel
@onready var status_label: Label = %StatusLabel
@onready var select_button: Button = %SelectButton

var entry_id: String = ""


func _ready() -> void:
	_bind_nodes()
	if not select_button.pressed.is_connected(_emit_selected):
		select_button.pressed.connect(_emit_selected)


func configure(entry: Dictionary, is_selected: bool, text_color: Color, muted_color: Color, accent_color: Color) -> void:
	_bind_nodes()
	entry_id = str(entry.id)
	name_label.text = str(entry.name)
	quantity_label.text = "x%s" % int(entry.quantity)
	description_label.text = str(entry.description)
	role_label.text = "Role: %s" % str(entry.capacity)
	output_label.text = "Output: %s" % str(entry.output)
	cost_label.text = "Cost: %s" % str(entry.cost)
	status_label.text = str(entry.status)
	select_button.text = "Selected" if is_selected else "Select"

	name_label.add_theme_color_override("font_color", text_color)
	quantity_label.add_theme_color_override("font_color", muted_color)
	description_label.add_theme_color_override("font_color", muted_color)
	role_label.add_theme_color_override("font_color", muted_color)
	output_label.add_theme_color_override("font_color", muted_color)
	cost_label.add_theme_color_override("font_color", muted_color)
	status_label.add_theme_color_override("font_color", accent_color if is_selected else muted_color)


func _emit_selected() -> void:
	selected.emit(entry_id)


func _bind_nodes() -> void:
	if name_label == null:
		name_label = get_node("%NameLabel") as Label
	if quantity_label == null:
		quantity_label = get_node("%QuantityLabel") as Label
	if description_label == null:
		description_label = get_node("%DescriptionLabel") as Label
	if role_label == null:
		role_label = get_node("%RoleLabel") as Label
	if output_label == null:
		output_label = get_node("%OutputLabel") as Label
	if cost_label == null:
		cost_label = get_node("%CostLabel") as Label
	if status_label == null:
		status_label = get_node("%StatusLabel") as Label
	if select_button == null:
		select_button = get_node("%SelectButton") as Button
