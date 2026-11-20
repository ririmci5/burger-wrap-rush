extends Control
## BurgerView — menggambar burger, animasi bungkus, partikel, dan teks melayang.
## Semuanya lewat _draw() (tanpa aset gambar) supaya ringan di HP spek rendah.

const UiKit := preload("res://scripts/ui_kit.gd")

const WRAP_TIME := 0.55      # lama animasi satu bungkusan
const MAX_EFFECTS := 8       # batas bungkusan yang tampil bersamaan
const MAX_PARTICLES := 160
const MAX_TEXTS := 12
const TEXT_LIFE := 0.75

const BUN_TOP := Color("eba94f")
const BUN_LIGHT := Color("f6c26b")
const BUN_SHADE := Color("c98530")
const BUN_BOTTOM := Color("c98530")
const BUN_BOTTOM_TOP := Color("dc9d44")
const PATTY_D := Color("4a2812")
const PATTY_L := Color("6b3a1e")
const LETTUCE := Color("6fd04a")
const TOMATO := Color("e5483c")
const CHEESE := Color("ffcf33")
const SEED := Color("fff3d6")
const SEEDS: Array = [Vector2(-0.45, -0.62), Vector2(-0.1, -0.82), Vector2(0.3, -0.7),
		Vector2(0.6, -0.45), Vector2(-0.65, -0.35), Vector2(0.0, -0.5),
		Vector2(0.35, -0.3), Vector2(-0.3, -0.25)]
const CONFETTI: Array = [Color("ff5d5d"), Color("ffd23f"), Color("6fe36f"), Color("5db8ff"), Color("ff8be0")]

## Offset guncangan layar (diatur oleh Main).
var view_offset: Vector2 = Vector2.ZERO:
	set(v):
		view_offset = v
		queue_redraw()

var skin_color: Color = Color.WHITE
var _effects: Array = []     # bungkusan yang sedang beranimasi
var _particles: Array = []
var _texts: Array = []
var _bump: float = 0.0       # 1 saat tap, turun ke 0 -> efek "pop"
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.randomize()
	resized.connect(queue_redraw)


func set_skin(c: Color) -> void:
	skin_color = c
	queue_redraw()


# ------------------------------------------------------------------ API publik
## Dipanggil Main setiap tap. local_pos = posisi tap di view ini.
func tap(local_pos: Vector2) -> void:
	_bump = 1.0
	if _effects.size() >= MAX_EFFECTS:
		_effects.pop_front()
	_effects.append({"t": 0.0, "dir": _rng.randi_range(0, 2), "jx": _rng.randf_range(-0.12, 0.12)})
	_spawn(8, false)
	if _texts.size() >= MAX_TEXTS:
		_texts.pop_front()
	var p := Vector2(
		clampf(local_pos.x, 120.0, maxf(120.0, size.x - 120.0)),
		clampf(local_pos.y - 40.0, 70.0, maxf(70.0, size.y - 20.0)))
	_texts.append({"p": p, "t": 0.0})
	queue_redraw()


## Ledakan konfeti (rekor baru).
func burst(count: int) -> void:
	_spawn(count, true)
	queue_redraw()


# ------------------------------------------------------------------ Update
func _spawn(count: int, confetti: bool) -> void:
	var c := UiKit.burger_center(size)
	var r := UiKit.burger_radius(size)
	for i in count:
		if _particles.size() >= MAX_PARTICLES:
			_particles.pop_front()
		var kind := 2 if confetti else (0 if _rng.randf() < 0.6 else 1)
		var col: Color = SEED
		if kind == 1:
			col = BUN_SHADE
		elif kind == 2:
			col = CONFETTI[_rng.randi() % CONFETTI.size()]
		var v := Vector2(_rng.randf_range(-260.0, 260.0), _rng.randf_range(-560.0, -200.0))
		if confetti:
			v *= 1.4
		_particles.append({
			"p": c + Vector2(_rng.randf_range(-0.5, 0.5) * r, -0.5 * r),
			"v": v,
			"life": _rng.randf_range(0.55, 0.95),
			"kind": kind,
			"col": col,
		})


func _process(delta: float) -> void:
	var busy := false

	if _bump > 0.0:
		_bump = maxf(0.0, _bump - delta * 6.0)
		busy = true

	if not _effects.is_empty():
		for e in _effects:
			e["t"] = float(e["t"]) + delta
		_effects = _effects.filter(func(e): return float(e["t"]) < WRAP_TIME)
		busy = true

	var i := _particles.size() - 1
	while i >= 0:
		var p: Dictionary = _particles[i]
		p["life"] = float(p["life"]) - delta
		if float(p["life"]) <= 0.0:
			_particles.remove_at(i)
		else:
			var v: Vector2 = p["v"]
			v.y += 900.0 * delta
			p["v"] = v
			p["p"] = (p["p"] as Vector2) + v * delta
		i -= 1
	if not _particles.is_empty():
		busy = true

	i = _texts.size() - 1
	while i >= 0:
		var t: Dictionary = _texts[i]
		t["t"] = float(t["t"]) + delta
		if float(t["t"]) >= TEXT_LIFE:
			_texts.remove_at(i)
		i -= 1
	if not _texts.is_empty():
		busy = true

	if busy:
		queue_redraw()


# ------------------------------------------------------------------ Gambar
func _draw() -> void:
	var c := UiKit.burger_center(size) + view_offset
	var r := UiKit.burger_radius(size)

	# Burger utama: "pop" (melebar & memipih sebentar) tiap tap.
	draw_set_transform(c, 0.0, Vector2(1.0 + 0.05 * _bump, 1.0 - 0.10 * _bump))
	_draw_burger(r, 1.0, true)

	# Bungkusan yang terbang ke atas sambil melipat.
	for e in _effects:
		var a: float = e["t"]
		var k: float = a / WRAP_TIME
		var rise: float = 1.0 - pow(1.0 - k, 3.0)
		var jx: float = e["jx"]
		var pos := c + Vector2(jx * r * 3.0 * rise, -0.15 * r - rise * 1.35 * r)
		var s := lerpf(0.78, 0.5, k)
		var alpha := 1.0 - smoothstep(0.55, 1.0, k)
		draw_set_transform(pos, jx * 2.0 * rise, Vector2(s, s))
		_draw_wrapping(r, a, int(e["dir"]), alpha)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Partikel wijen / remah / konfeti
	for p in _particles:
		var pos: Vector2 = p["p"]
		var col: Color = p["col"]
		col.a = clampf(float(p["life"]) / 0.25, 0.0, 1.0)
		match int(p["kind"]):
			0:
				draw_colored_polygon(PackedVector2Array([
					pos + Vector2(-5, 0), pos + Vector2(0, -3), pos + Vector2(5, 0), pos + Vector2(0, 3)]), col)
			1:
				draw_rect(Rect2(pos - Vector2(3, 3), Vector2(6, 6)), col)
			_:
				draw_rect(Rect2(pos - Vector2(5, 3), Vector2(10, 6)), col)

	# Teks melayang "+1 BURGER"
	var font := ThemeDB.fallback_font
	for t in _texts:
		var k: float = float(t["t"]) / TEXT_LIFE
		var p: Vector2 = t["p"]
		p.y -= 90.0 * (1.0 - pow(1.0 - k, 2.0))
		var alpha := 1.0 - smoothstep(0.55, 1.0, k)
		var fs := int(lerpf(40.0, 30.0, minf(k * 6.0, 1.0)))
		var o := Vector2(p.x - 130.0, p.y)
		draw_string_outline(font, o, "+1 BURGER", HORIZONTAL_ALIGNMENT_CENTER, 260.0, fs, 8,
				Color(0.16, 0.1, 0.06, alpha))
		draw_string(font, o, "+1 BURGER", HORIZONTAL_ALIGNMENT_CENTER, 260.0, fs,
				Color(1.0, 0.82, 0.25, alpha))


func _al(col: Color, a: float) -> Color:
	return Color(col.r, col.g, col.b, col.a * a)


func _ellipse(center: Vector2, rx: float, ry: float, col: Color, segs: int = 14) -> void:
	draw_colored_polygon(UiKit.ellipse_points(center, rx, ry, segs), col)


## Burger low-poly dilihat dari sudut atas. Titik (0,0) = pusat; r = radius.
func _draw_burger(r: float, a: float, shadow: bool) -> void:
	if shadow:
		_ellipse(Vector2(0, 0.78 * r), 1.08 * r, 0.2 * r, Color(0, 0, 0, 0.25 * a), 16)

	# Roti bawah
	_ellipse(Vector2(0, 0.60 * r), 0.95 * r, 0.2 * r, _al(BUN_BOTTOM, a))
	draw_rect(Rect2(-0.95 * r, 0.42 * r, 1.9 * r, 0.18 * r), _al(BUN_BOTTOM, a))
	_ellipse(Vector2(0, 0.42 * r), 0.95 * r, 0.2 * r, _al(BUN_BOTTOM_TOP, a))

	# Patty
	_ellipse(Vector2(0, 0.40 * r), 0.98 * r, 0.2 * r, _al(PATTY_D, a))
	draw_rect(Rect2(-0.98 * r, 0.26 * r, 1.96 * r, 0.14 * r), _al(PATTY_D, a))
	_ellipse(Vector2(0, 0.26 * r), 0.98 * r, 0.2 * r, _al(PATTY_L, a))

	# Selada (bergerigi)
	var pts := PackedVector2Array()
	for i in 16:
		var th := TAU * float(i) / 16.0
		var k := 1.0 + 0.07 * sin(th * 7.0)
		pts.append(Vector2(cos(th) * 1.1 * r * k, 0.17 * r + sin(th) * 0.26 * r * k))
	draw_colored_polygon(pts, _al(LETTUCE, a))

	# Tomat & keju
	_ellipse(Vector2(0, 0.12 * r), 0.9 * r, 0.2 * r, _al(TOMATO, a))
	_ellipse(Vector2(0, 0.07 * r), 0.98 * r, 0.2 * r, _al(CHEESE, a), 4)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.62 * r, 0.12 * r), Vector2(0.98 * r, 0.1 * r), Vector2(0.86 * r, 0.42 * r)]),
		_al(CHEESE.darkened(0.1), a))

	# Roti atas (kubah) + facet low-poly
	var dome := PackedVector2Array()
	for i in 15:
		var th := PI + PI * float(i) / 14.0
		dome.append(Vector2(cos(th) * r, sin(th) * 0.9 * r))
	var full := PackedVector2Array(dome)
	for i in range(1, 8):
		var th2 := PI * float(i) / 8.0
		full.append(Vector2(cos(th2) * r, sin(th2) * 0.18 * r))
	draw_colored_polygon(full, _al(BUN_TOP, a))
	draw_colored_polygon(PackedVector2Array([dome[2], dome[3], dome[4], dome[5], dome[6],
			Vector2(-0.1 * r, -0.3 * r)]), _al(BUN_LIGHT, a))
	draw_colored_polygon(PackedVector2Array([dome[10], dome[11], dome[12], dome[13], dome[14],
			Vector2(0.85 * r, 0.02 * r), Vector2(0.4 * r, -0.2 * r)]), _al(BUN_SHADE, a))
	for s in SEEDS:
		_ellipse((s as Vector2) * r, 0.07 * r, 0.04 * r, _al(SEED, a), 6)


## Satu bungkusan: kertas melipat dari kiri/kanan/atas (urutan acak), lalu jadi kotak.
func _draw_wrapping(r: float, a: float, dir: int, alpha: float) -> void:
	var hw := 1.1 * r
	var hh := 0.62 * r
	var sheet := _al(skin_color, alpha)
	var shade := _al(skin_color.darkened(0.08), alpha)
	var light := _al(skin_color.lightened(0.04), alpha)
	var edge := _al(skin_color.darkened(0.35), alpha)

	var base := PackedVector2Array([
		Vector2(-hw * 0.92, -hh), Vector2(hw * 0.92, -hh), Vector2(hw, hh), Vector2(-hw, hh)])
	draw_colored_polygon(base, sheet)

	# Burger di atas kertas memudar saat lipatan menutup
	var closing := clampf(a / 0.28, 0.0, 1.0)
	if closing < 1.0:
		_draw_burger(r * 0.72, alpha * (1.0 - closing), false)

	# Delay lipatan [kiri, kanan, atas] tergantung arah acak
	var delays: Array = [[0.0, 0.07, 0.14], [0.07, 0.0, 0.14], [0.14, 0.07, 0.0]]
	var d: Array = delays[dir]
	var pl := _fold(a - float(d[0]))
	var pr := _fold(a - float(d[1]))
	var pt := _fold(a - float(d[2]))

	var xr := lerpf(-hw, 0.08 * r, pl)
	if xr + hw > 2.0:
		draw_colored_polygon(PackedVector2Array([
			Vector2(-hw * 0.92, -hh), Vector2(xr, -hh), Vector2(xr, hh), Vector2(-hw, hh)]), shade)
		draw_line(Vector2(xr, -hh), Vector2(xr, hh), edge, 2.0)
	var xl := lerpf(hw, -0.08 * r, pr)
	if hw - xl > 2.0:
		draw_colored_polygon(PackedVector2Array([
			Vector2(xl, -hh), Vector2(hw * 0.92, -hh), Vector2(hw, hh), Vector2(xl, hh)]), light)
		draw_line(Vector2(xl, -hh), Vector2(xl, hh), edge, 2.0)
	var yb := lerpf(-hh, 0.12 * hh, pt)
	if yb + hh > 2.0:
		draw_colored_polygon(PackedVector2Array([
			Vector2(-hw * 0.92, -hh), Vector2(hw * 0.92, -hh), Vector2(hw * 0.96, yb), Vector2(-hw * 0.96, yb)]),
			_al(skin_color.darkened(0.04), alpha))
		draw_line(Vector2(-hw * 0.96, yb), Vector2(hw * 0.96, yb), edge, 2.0)

	# Kontur kotak + stiker merah kecil setelah rapat
	draw_polyline(PackedVector2Array([base[0], base[1], base[2], base[3], base[0]]), edge, 3.0)
	if minf(pl, minf(pr, pt)) >= 1.0:
		draw_rect(Rect2(-0.28 * r, -0.1 * r, 0.56 * r, 0.2 * r), _al(TOMATO, alpha))


func _fold(x: float) -> float:
	var t := clampf(x / 0.14, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
