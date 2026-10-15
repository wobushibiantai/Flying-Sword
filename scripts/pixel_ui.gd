class_name PixelUI
extends RefCounted
## Nine-patch frames and controls exported from layered Aseprite source sprites.
const PANEL = preload("res://assets/pixel/ui/panel.png")
const BUTTON = preload("res://assets/pixel/ui/button.png")
const HOVER = preload("res://assets/pixel/ui/button_hover.png")
const PRESSED = preload("res://assets/pixel/ui/button_pressed.png")
const TAB = preload("res://assets/pixel/ui/tab.png")
const TAB_SELECTED = preload("res://assets/pixel/ui/tab_selected.png")
const TRACK = preload("res://assets/pixel/ui/track.png")
const TRACK_FILL = preload("res://assets/pixel/ui/track_fill.png")
const THUMB = preload("res://assets/pixel/ui/thumb.png")
const CHECK_OFF = preload("res://assets/pixel/ui/check_off.png")
const CHECK_ON = preload("res://assets/pixel/ui/check_on.png")
const ARROW = preload("res://assets/pixel/ui/arrow.png")
const ICON_SWORD = preload("res://assets/pixel/ui/icon_sword.png")
const ICON_BLOOM = preload("res://assets/pixel/ui/icon_bloom.png")
const ICON_RIVER = preload("res://assets/pixel/ui/icon_river.png")
const ICON_RISE = preload("res://assets/pixel/ui/icon_rise.png")
const ICON_LAND = preload("res://assets/pixel/ui/icon_land.png")

static func frame(texture: Texture2D, margin: int = 8) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = texture
	box.texture_margin_left = margin
	box.texture_margin_right = margin
	box.texture_margin_top = margin
	box.texture_margin_bottom = margin
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box

static func panel() -> StyleBoxTexture:
	var box := frame(PANEL)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box

static func button(color: Color) -> StyleBoxTexture:
	if color.r >= 0.14: return frame(PRESSED)
	if color.r >= 0.10: return frame(HOVER)
	return frame(BUTTON)

static func make_theme(font: Font) -> Theme:
	var theme := Theme.new()
	theme.default_font = font
	for style in ["normal", "focus"]: theme.set_stylebox(style, "Button", frame(BUTTON))
	theme.set_stylebox("hover", "Button", frame(HOVER))
	theme.set_stylebox("pressed", "Button", frame(PRESSED))
	theme.set_stylebox("hover_pressed", "Button", frame(PRESSED))
	theme.set_stylebox("disabled", "Button", frame(PANEL))
	theme.set_stylebox("panel", "PanelContainer", panel())
	theme.set_stylebox("panel", "TabContainer", panel())
	theme.set_stylebox("tab_unselected", "TabBar", frame(TAB))
	theme.set_stylebox("tab_selected", "TabBar", frame(TAB_SELECTED))
	theme.set_stylebox("tab_hovered", "TabBar", frame(HOVER))
	theme.set_stylebox("tab_disabled", "TabBar", frame(PANEL))
	theme.set_stylebox("normal", "OptionButton", frame(BUTTON))
	theme.set_stylebox("hover", "OptionButton", frame(HOVER))
	theme.set_stylebox("pressed", "OptionButton", frame(PRESSED))
	theme.set_icon("arrow", "OptionButton", ARROW)
	theme.set_icon("checked", "CheckButton", CHECK_ON)
	theme.set_icon("unchecked", "CheckButton", CHECK_OFF)
	for state in ["normal", "hover", "pressed", "disabled"]:
		theme.set_stylebox(state, "CheckButton", frame(PANEL))
	theme.set_stylebox("slider", "HSlider", frame(TRACK, 3))
	theme.set_stylebox("grabber_area", "HSlider", frame(TRACK_FILL, 3))
	theme.set_stylebox("grabber_area_highlight", "HSlider", frame(TRACK_FILL, 3))
	theme.set_icon("grabber", "HSlider", THUMB)
	theme.set_icon("grabber_highlight", "HSlider", THUMB)
	theme.set_stylebox("panel", "PopupMenu", panel())
	theme.set_stylebox("panel", "Window", panel())
	return theme
