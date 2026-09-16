extends RefCounted
## Shared visual tokens and UI primitives. No game state.

const INK := Color("080f1c")
const PANEL := Color("101e30")
const EDGE := Color("294055")
const TEXT := Color("e1e9f0")
const MUTED := Color("94a9bc")
const GOLD := Color("e8be73")
const CYAN := Color("70d5e5")
const RED := Color("ee8e82")


static func style(color: Color, border: Color = EDGE, padding: int = 16) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(8)
	box.content_margin_left = padding
	box.content_margin_right = padding
	box.content_margin_top = padding
	box.content_margin_bottom = padding
	return box


static func create() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 16
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("default_color", "RichTextLabel", MUTED)
	theme.set_stylebox("panel", "PanelContainer", style(PANEL))
	theme.set_constant("separation", "VBoxContainer", 8)
	theme.set_constant("separation", "HBoxContainer", 14)
	theme.set_stylebox("normal", "Button", style(Color("182b40"), EDGE, 12))
	theme.set_stylebox("hover", "Button", style(Color("294156"), GOLD, 12))
	theme.set_stylebox("pressed", "Button", style(Color("354853"), GOLD, 12))
	theme.set_stylebox("focus", "Button", style(Color(0, 0, 0, 0), GOLD, 2))
	theme.set_stylebox("disabled", "Button", style(Color("101925"), Color("1a2837"), 12))
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_disabled_color", "Button", Color("52677b"))
	theme.set_stylebox("background", "ProgressBar", style(Color("233247"), Color.TRANSPARENT, 0))
	theme.set_stylebox("fill", "ProgressBar", style(GOLD, GOLD, 0))
	return theme


static func label(text: String, size: int = 16, color: Color = TEXT) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	return node


static func paragraph(text: String, color: Color = MUTED) -> Label:
	var node := label(text, 16, color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return node


static func button(text: String, action: Callable, primary: bool = false) -> Button:
	var node := Button.new()
	node.text = text
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.pressed.connect(action)
	if primary:
		node.add_theme_stylebox_override("normal", style(GOLD, GOLD, 12))
		node.add_theme_color_override("font_color", INK)
	return node


static func panel(parent: Node, width: float = 0) -> VBoxContainer:
	var frame := PanelContainer.new()
	frame.custom_minimum_size.x = width
	parent.add_child(frame)
	var column := VBoxContainer.new()
	frame.add_child(column)
	return column


static func bar(value: float) -> ProgressBar:
	var node := ProgressBar.new()
	node.value = value
	node.show_percentage = false
	node.custom_minimum_size.y = 5
	return node
