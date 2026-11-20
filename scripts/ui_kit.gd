extends RefCounted
## UiKit — helper statis untuk membuat tampilan (style, label, tombol) lewat kode,
## plus rumus posisi burger yang dipakai bersama oleh TableView dan BurgerView.

const C_YELLOW := Color("ffd23f")
const C_GREEN := Color("6fe36f")
const C_RED := Color("ff4d4d")


static func style(bg: Color, radius: int = 16, border: Color = Color(0, 0, 0, 0),
		border_w: int = 0, margin: int = 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	if border_w > 0:
		s.border_color = border
		s.set_border_width_all(border_w)
	s.set_content_margin_all(margin)
	return s


static func label(text: String, size: int, color: Color, outline: int = 0,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", Color("2a1a10"))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func button(text: String, color: Color, size: int = 22,
		min_size: Vector2 = Vector2(0, 52)) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color("8a8396"))
	b.add_theme_color_override("font_outline_color", Color("2a1a10"))
	b.add_theme_constant_override("outline_size", 4)
	b.add_theme_stylebox_override("normal", style(color, 14, color.darkened(0.35), 3))
	b.add_theme_stylebox_override("hover", style(color.lightened(0.12), 14, color.darkened(0.35), 3))
	b.add_theme_stylebox_override("pressed", style(color.darkened(0.15), 14, color.darkened(0.45), 3))
	b.add_theme_stylebox_override("disabled", style(Color("4a4455"), 14, Color("38333f"), 3))
	return b


## Lingkaran kecil berwarna (ikon koin / gem).
static func dot(color: Color, px: int = 18) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(px, px)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", style(color, px / 2, color.darkened(0.4), 2, 0))
	return p


static func ellipse_points(center: Vector2, rx: float, ry: float, segs: int = 14) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segs:
		var th := TAU * float(i) / float(segs)
		pts.append(center + Vector2(cos(th) * rx, sin(th) * ry))
	return pts


## Radius burger (dalam piksel) dan titik tengahnya di area bermain.
static func burger_radius(area: Vector2) -> float:
	return minf(area.x * 0.34, area.y * 0.27)


static func burger_center(area: Vector2) -> Vector2:
	return Vector2(area.x * 0.5, area.y * 0.5)
