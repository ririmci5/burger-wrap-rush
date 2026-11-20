extends Control
## TableView — meja kayu tampak dari atas dengan perspektif (papan menyempit ke atas) + piring.
## Digambar lewat kode. Posisi piring mengikuti rumus burger di UiKit.

const UiKit := preload("res://scripts/ui_kit.gd")

const WOOD: Array = [Color("c98a4b"), Color("bd7d3f"), Color("c4843f")]
const SEAM := Color("7a4a22")

var view_offset: Vector2 = Vector2.ZERO:
	set(v):
		view_offset = v
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var w := size.x
	var h := size.y
	var o := view_offset
	# Digambar lebih besar dari area supaya tidak ada celah saat layar bergetar.
	var yt := -40.0 + o.y
	var yb := h + 40.0 + o.y
	var cx := w * 0.5 + o.x
	var st := w * 0.17   # lebar papan di atas
	var sb := w * 0.34   # lebar papan di bawah (lebih lebar = terasa dekat)

	draw_rect(Rect2(-60, -60, w + 120, h + 120), Color("5a3a1e"))
	for i in range(-8, 8):
		var pts := PackedVector2Array([
			Vector2(cx + i * st, yt), Vector2(cx + (i + 1) * st, yt),
			Vector2(cx + (i + 1) * sb, yb), Vector2(cx + i * sb, yb)])
		draw_colored_polygon(pts, WOOD[posmod(i, 3)])
		draw_line(pts[0], pts[3], SEAM, 3.0)

	# Bayangan sisi belakang meja (efek kedalaman)
	for k in 5:
		draw_rect(Rect2(-60, -60, w + 120, 60 + h * 0.012 * float(5 - k)), Color(0, 0, 0, 0.07))

	var c := UiKit.burger_center(size) + o
	var r := UiKit.burger_radius(size)

	# Sorotan lembut di tengah
	draw_colored_polygon(UiKit.ellipse_points(c, w * 0.62, w * 0.4, 24), Color(1, 1, 1, 0.07))

	# Piring
	var pc := c + Vector2(0, 0.62 * r)
	draw_colored_polygon(UiKit.ellipse_points(pc + Vector2(0, 0.1 * r), 1.42 * r, 0.46 * r, 24), Color(0, 0, 0, 0.25))
	draw_colored_polygon(UiKit.ellipse_points(pc, 1.38 * r, 0.44 * r, 24), Color("d7d2c8"))
	draw_colored_polygon(UiKit.ellipse_points(pc, 1.22 * r, 0.36 * r, 24), Color("f1ede4"))
