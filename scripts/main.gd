extends Control
## Main — merakit UI dan menghubungkan GameManager, TimerSystem, ClickCounter, BurgerView, UpgradeShop.
## Alur: IDLE (siap, tap pertama memulai) -> PLAYING (20 dtk) -> RESULT (hasil, "Main Lagi" -> IDLE).

enum State { IDLE, PLAYING, RESULT }

const UiKit := preload("res://scripts/ui_kit.gd")
const TimerSystem := preload("res://scripts/timer_system.gd")
const ClickCounter := preload("res://scripts/click_counter.gd")
const BurgerView := preload("res://scripts/burger_view.gd")
const TableView := preload("res://scripts/table_view.gd")
const UpgradeShop := preload("res://scripts/upgrade_shop.gd")
const Sfx := preload("res://scripts/sfx.gd")

var state: int = State.IDLE
var burgers: int = 0
var run_coins: float = 0.0

var _timer = null
var _clicks = null
var _sfx = null
var _shake: float = 0.0
var _last_haptic: int = 0
var _time_low: bool = false
var _blockers: Array = []   # tombol: tap di atasnya tidak dihitung sebagai tap burger

var _play: Control
var _burger_view = null
var _table_view = null
var _idle_box: Control
var _hint: Label
var _result_box: Control
var _result_panel: Control
var _shop = null

var _lbl_level: Label
var _bar_xp: ProgressBar
var _lbl_coins: Label
var _lbl_gems: Label
var _lbl_subtitle: Label
var _val_time: Label
var _val_burgers: Label
var _val_cps: Label
var _val_best: Label
var _res_record: Label
var _res_burgers: Label
var _res_coins: Label
var _res_xp: Label
var _res_gems: Label
var _res_level: Label


func _ready() -> void:
	_clicks = ClickCounter.new()
	_timer = TimerSystem.new()
	add_child(_timer)
	_timer.tick.connect(_on_tick)
	_timer.finished.connect(_on_round_finished)
	_sfx = Sfx.new()
	add_child(_sfx)

	_build_ui()
	GameManager.data_changed.connect(_refresh_hud)
	_enter_idle()


# =============================================================== Input
func _input(event: InputEvent) -> void:
	# Hanya sentuhan (multitouch: tiap jari = 1 event). Mouse di desktop ikut terhitung lewat
	# pengaturan emulate_touch_from_mouse di project.godot.
	var te := event as InputEventScreenTouch
	if te == null or not te.pressed:
		return
	if _shop.visible or state == State.RESULT:
		return
	var local: Vector2 = (_burger_view.make_input_local(te) as InputEventScreenTouch).position
	if not Rect2(Vector2.ZERO, _burger_view.size).has_point(local):
		return
	for b in _blockers:
		if b.is_visible_in_tree():
			var bl: Vector2 = (b.make_input_local(te) as InputEventScreenTouch).position
			if Rect2(Vector2.ZERO, b.size).has_point(bl):
				return
	if state == State.IDLE:
		_start_round()
	if state == State.PLAYING:
		_do_tap(local)


func _do_tap(local: Vector2) -> void:
	burgers += 1
	run_coins += GameManager.coin_value()
	_clicks.register_tap()
	_burger_view.tap(local)
	_shake = 5.0
	_sfx.tap()
	_haptic()
	_val_burgers.text = str(burgers)
	_update_coins()


func _haptic() -> void:
	if not GameManager.haptic_on():
		return
	var now := Time.get_ticks_msec()
	if now - _last_haptic < 40: # dibatasi agar tap cepat tidak membebani motor getar
		return
	_last_haptic = now
	Input.vibrate_handheld(15)


# =============================================================== Alur ronde
func _enter_idle() -> void:
	state = State.IDLE
	burgers = 0
	run_coins = 0.0
	_clicks.reset()
	_timer.stop()
	_time_low = false
	_val_time.add_theme_color_override("font_color", UiKit.C_YELLOW)
	_val_burgers.text = "0"
	_val_cps.text = "0.0"
	_lbl_subtitle.text = "Bungkus burger secepat mungkin!"
	_result_box.visible = false
	_idle_box.visible = true
	_refresh_hud()


func _start_round() -> void:
	state = State.PLAYING
	burgers = 0
	run_coins = 0.0
	_clicks.reset()
	_idle_box.visible = false
	_lbl_subtitle.text = "TAP TAP TAP!"
	_timer.start(GameManager.round_time())


func _on_tick(t: float) -> void:
	_val_time.text = "%.1f" % t
	var low := t < 5.0
	if low != _time_low:
		_time_low = low
		_val_time.add_theme_color_override("font_color", UiKit.C_RED if low else UiKit.C_YELLOW)


func _on_round_finished() -> void:
	state = State.RESULT
	_val_time.text = "0.0"
	_val_cps.text = "0.0"
	_lbl_subtitle.text = "Ronde selesai!"
	var res: Dictionary = GameManager.finish_round(burgers, run_coins) # simpan langsung
	_sfx.end()
	await get_tree().create_timer(0.45).timeout
	_show_result(res)


func _show_result(res: Dictionary) -> void:
	_res_burgers.text = str(res["burgers"])
	_res_record.visible = bool(res["new_best"])
	_res_coins.text = "KOIN  +%d" % int(res["coins"])
	_res_xp.text = "XP  +%d" % int(res["xp"])
	_res_gems.visible = int(res["gems"]) > 0
	_res_gems.text = "GEM  +%d" % int(res["gems"])
	_res_level.visible = int(res["levels_gained"]) > 0
	_res_level.text = "LEVEL UP!  Lv %d" % int(res["level"])
	_result_box.visible = true
	_hint.visible = false
	if bool(res["new_best"]):
		_sfx.win()
		_burger_view.burst(50)
	# Animasi muncul (bouncy)
	await get_tree().process_frame
	_result_panel.pivot_offset = _result_panel.size / 2.0
	_result_panel.scale = Vector2(0.6, 0.6)
	var tw := create_tween()
	tw.tween_property(_result_panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_play_again() -> void:
	_sfx.click()
	_enter_idle()
	_hint.visible = true


func _open_shop() -> void:
	_sfx.click()
	_shop.open()


# =============================================================== Per frame
func _process(delta: float) -> void:
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - 40.0 * delta)
		var off := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake
		_burger_view.view_offset = off
		_table_view.view_offset = off
	if state == State.PLAYING:
		_val_cps.text = "%.1f" % _clicks.cps()
	if _idle_box.visible:
		_hint.modulate.a = 0.65 + 0.35 * sin(Time.get_ticks_msec() * 0.006)


# =============================================================== HUD
func _refresh_hud() -> void:
	var lvl := GameManager.get_level()
	var need := GameManager.xp_needed(lvl)
	_lbl_level.text = "LV %d   %d / %d XP" % [lvl, GameManager.get_xp(), need]
	_bar_xp.max_value = need
	_bar_xp.value = GameManager.get_xp()
	_update_coins()
	_lbl_gems.text = str(GameManager.get_gems())
	_val_best.text = str(GameManager.get_best())
	_burger_view.set_skin(GameManager.get_skin_color())
	if state == State.IDLE:
		_val_time.text = "%.1f" % GameManager.round_time()


func _update_coins() -> void:
	var shown := GameManager.get_coins()
	if state == State.PLAYING:
		shown += int(round(run_coins))
	_lbl_coins.text = _fmt(shown)


func _fmt(n: int) -> String:
	if n >= 1000000:
		return "%.1fM" % (n / 1000000.0)
	if n >= 10000:
		return "%.1fK" % (n / 1000.0)
	return str(n)


# =============================================================== Membangun UI
func _safe_inset() -> Vector2: # (atas, bawah) untuk notch / bar navigasi, dalam unit viewport
	if not (OS.has_feature("android") or OS.has_feature("ios")):
		return Vector2.ZERO
	var win := DisplayServer.window_get_size()
	var vp := get_viewport_rect().size
	if win.y <= 0 or vp.y <= 0.0:
		return Vector2.ZERO
	var sc := float(win.y) / vp.y
	var safe := DisplayServer.get_display_safe_area()
	var top := maxf(0.0, float(safe.position.y)) / sc
	var bottom := maxf(0.0, float(win.y) - float(safe.position.y + safe.size.y)) / sc
	return Vector2(clampf(top, 0.0, 80.0), clampf(bottom, 0.0, 80.0))


func _pill(ratio: float) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.style(Color("1d1a24e6"), 22, Color("ffffff30"), 2, 10))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_stretch_ratio = ratio
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func _stat_cell(grid: GridContainer, caption: String, color: Color) -> Label:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", -2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.add_child(v)
	v.add_child(UiKit.label(caption, 13, Color("9d93b5")))
	var val := UiKit.label("0", 40, color, 6)
	v.add_child(val)
	return val


func _build_ui() -> void:
	var inset := _safe_inset()

	var bg := ColorRect.new()
	bg.color = Color("2b2233")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# ---- Pill bar: Level+XP, Koin, Gem
	var top := MarginContainer.new()
	top.add_theme_constant_override("margin_left", 14)
	top.add_theme_constant_override("margin_right", 14)
	top.add_theme_constant_override("margin_top", 12 + int(inset.x))
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)
	var pills := HBoxContainer.new()
	pills.add_theme_constant_override("separation", 8)
	pills.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(pills)

	var lv_pill := _pill(2.0)
	var lv_box := VBoxContainer.new()
	lv_box.add_theme_constant_override("separation", 4)
	lv_pill.add_child(lv_box)
	_lbl_level = UiKit.label("LV 1   0 / 140 XP", 16, Color.WHITE, 3)
	lv_box.add_child(_lbl_level)
	_bar_xp = ProgressBar.new()
	_bar_xp.show_percentage = false
	_bar_xp.custom_minimum_size = Vector2(0, 8)
	_bar_xp.add_theme_stylebox_override("background", UiKit.style(Color("45395a"), 4, Color(0, 0, 0, 0), 0, 0))
	_bar_xp.add_theme_stylebox_override("fill", UiKit.style(UiKit.C_GREEN, 4, Color(0, 0, 0, 0), 0, 0))
	_bar_xp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lv_box.add_child(_bar_xp)
	pills.add_child(lv_pill)

	var coin_pill := _pill(1.2)
	var coin_row := HBoxContainer.new()
	coin_row.alignment = BoxContainer.ALIGNMENT_CENTER
	coin_row.add_theme_constant_override("separation", 6)
	coin_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin_pill.add_child(coin_row)
	coin_row.add_child(UiKit.dot(Color("ffc83d")))
	_lbl_coins = UiKit.label("0", 18, Color.WHITE, 3)
	coin_row.add_child(_lbl_coins)
	pills.add_child(coin_pill)

	var gem_pill := _pill(1.0)
	var gem_row := HBoxContainer.new()
	gem_row.alignment = BoxContainer.ALIGNMENT_CENTER
	gem_row.add_theme_constant_override("separation", 6)
	gem_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gem_pill.add_child(gem_row)
	gem_row.add_child(UiKit.dot(Color("5dd6ff")))
	_lbl_gems = UiKit.label("0", 18, Color.WHITE, 3)
	gem_row.add_child(_lbl_gems)
	pills.add_child(gem_pill)

	# ---- Judul
	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", -2)
	title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(title_box)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_box.add_child(gap)
	title_box.add_child(UiKit.label("BURGER WRAP RUSH", 34, UiKit.C_YELLOW, 8))
	_lbl_subtitle = UiKit.label("", 16, Color("e8dcff"), 4)
	title_box.add_child(_lbl_subtitle)

	# ---- Area bermain (meja + burger)
	_play = Control.new()
	_play.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_play.clip_contents = true
	_play.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_play)
	_table_view = TableView.new()
	_play.add_child(_table_view)
	_table_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_burger_view = BurgerView.new()
	_play.add_child(_burger_view)
	_burger_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Overlay IDLE: petunjuk + tombol toko
	var idle := VBoxContainer.new()
	idle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	idle.alignment = BoxContainer.ALIGNMENT_END
	idle.add_theme_constant_override("separation", 12)
	idle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_play.add_child(idle)
	_idle_box = idle
	_hint = UiKit.label("TAP UNTUK MULAI!", 30, UiKit.C_YELLOW, 8)
	idle.add_child(_hint)
	var shop_row := CenterContainer.new()
	shop_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	idle.add_child(shop_row)
	var shop_btn := UiKit.button("TOKO UPGRADE", Color("4f8cff"), 22, Vector2(260, 56))
	shop_btn.pressed.connect(_open_shop)
	shop_row.add_child(shop_btn)
	_blockers.append(shop_btn)
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(0, 14)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	idle.add_child(pad)

	_build_result()

	# ---- Panel statistik bawah
	var bottom := PanelContainer.new()
	var sb := UiKit.style(Color("17131d"), 28, Color("ffd23f55"), 3, 14)
	sb.corner_radius_bottom_left = 0
	sb.corner_radius_bottom_right = 0
	bottom.add_theme_stylebox_override("panel", sb)
	root.add_child(bottom)
	var bv := VBoxContainer.new()
	bottom.add_child(bv)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	bv.add_child(grid)
	_val_time = _stat_cell(grid, "TIME LEFT", UiKit.C_YELLOW)
	_val_burgers = _stat_cell(grid, "BURGERS", UiKit.C_GREEN)
	_val_cps = _stat_cell(grid, "CLICKS/S", UiKit.C_YELLOW)
	_val_best = _stat_cell(grid, "BEST", UiKit.C_GREEN)
	var bpad := Control.new()
	bpad.custom_minimum_size = Vector2(0, inset.y)
	bv.add_child(bpad)

	# ---- Toko (overlay paling atas)
	_shop = UpgradeShop.new()
	_shop.sfx = _sfx
	_shop.closed.connect(_refresh_hud)
	add_child(_shop)


func _build_result() -> void:
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.visible = false
	_play.add_child(cc)
	_result_box = cc

	_result_panel = PanelContainer.new()
	_result_panel.custom_minimum_size = Vector2(380, 0)
	_result_panel.add_theme_stylebox_override("panel", UiKit.style(Color("1d1a24f2"), 26, UiKit.C_YELLOW, 4, 18))
	cc.add_child(_result_panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	_result_panel.add_child(v)
	v.add_child(UiKit.label("WAKTU HABIS!", 30, UiKit.C_YELLOW, 6))
	_res_record = UiKit.label("REKOR BARU!", 24, UiKit.C_GREEN, 5)
	v.add_child(_res_record)
	_res_burgers = UiKit.label("0", 76, UiKit.C_GREEN, 8)
	v.add_child(_res_burgers)
	v.add_child(UiKit.label("BURGER DIBUNGKUS", 14, Color("b9aed0")))
	_res_coins = UiKit.label("", 22, Color("ffe27a"), 4)
	v.add_child(_res_coins)
	_res_xp = UiKit.label("", 22, Color("c9a7ff"), 4)
	v.add_child(_res_xp)
	_res_gems = UiKit.label("", 22, Color("5dd6ff"), 4)
	v.add_child(_res_gems)
	_res_level = UiKit.label("", 26, UiKit.C_GREEN, 5)
	v.add_child(_res_level)

	var again := UiKit.button("MAIN LAGI", Color("34c759"), 28, Vector2(0, 62))
	again.pressed.connect(_on_play_again)
	v.add_child(again)
	var shop_btn := UiKit.button("TOKO UPGRADE", Color("4f8cff"), 20, Vector2(0, 48))
	shop_btn.pressed.connect(_open_shop)
	v.add_child(shop_btn)
	_blockers.append_array([again, shop_btn])
