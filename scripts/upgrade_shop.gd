extends Control
## UpgradeShop — layar toko (overlay): upgrade, skin kertas, gem dummy, pengaturan getar/suara.
## Dibangun lewat kode; daftar dibangun ulang tiap data berubah (kecil, jadi murah).

signal closed

const UiKit := preload("res://scripts/ui_kit.gd")

## Diisi oleh Main supaya pembelian berbunyi.
var sfx = null

var _list: VBoxContainer
var _lbl_coins: Label
var _lbl_gems: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim) # mouse_filter default STOP -> menahan sentuhan ke belakang

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.style(Color("251f2e"), 26, UiKit.C_YELLOW, 4, 16))
	margin.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	var head := HBoxContainer.new()
	v.add_child(head)
	var title := UiKit.label("TOKO", 32, UiKit.C_YELLOW, 6, HORIZONTAL_ALIGNMENT_LEFT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := UiKit.button("X", Color("e5483c"), 24, Vector2(56, 48))
	close.pressed.connect(close_shop)
	head.add_child(close)

	var cur := HBoxContainer.new()
	cur.add_theme_constant_override("separation", 20)
	v.add_child(cur)
	cur.add_child(UiKit.dot(Color("ffc83d")))
	_lbl_coins = UiKit.label("0", 22, Color.WHITE, 3)
	cur.add_child(_lbl_coins)
	cur.add_child(UiKit.dot(Color("5dd6ff")))
	_lbl_gems = UiKit.label("0", 22, Color.WHITE, 3)
	cur.add_child(_lbl_gems)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)

	GameManager.data_changed.connect(func(): if visible: _refresh())


func open() -> void:
	_refresh()
	visible = true


func close_shop() -> void:
	visible = false
	closed.emit()


func _refresh() -> void:
	for ch in _list.get_children():
		_list.remove_child(ch)
		ch.queue_free()
	_lbl_coins.text = str(GameManager.get_coins())
	_lbl_gems.text = str(GameManager.get_gems())

	_list.add_child(UiKit.label("UPGRADE", 18, UiKit.C_YELLOW, 0, HORIZONTAL_ALIGNMENT_LEFT))
	for id in GameManager.UPGRADES.keys():
		var u: Dictionary = GameManager.UPGRADES[id]
		var lvl := GameManager.upgrade_level(id)
		var b: Button
		if GameManager.upgrade_maxed(id):
			b = UiKit.button("MAX", Color("4a4455"), 20)
			b.disabled = true
		else:
			var cost := GameManager.upgrade_cost(id)
			b = UiKit.button("%d KOIN" % cost, Color("34c759"), 18)
			b.disabled = GameManager.get_coins() < cost
			b.pressed.connect(func(): _buy_upgrade(id))
		_list.add_child(_row(str(u["name"]), str(u["desc"]), "Level %d / %d" % [lvl, int(u["max"])], b))

	_list.add_child(UiKit.label("SKIN KERTAS", 18, UiKit.C_YELLOW, 0, HORIZONTAL_ALIGNMENT_LEFT))
	for s in GameManager.SKINS:
		var sid: String = s["id"]
		var b2: Button
		if GameManager.equipped_skin() == sid:
			b2 = UiKit.button("DIPAKAI", Color("4a4455"), 18)
			b2.disabled = true
		elif GameManager.owns_skin(sid):
			b2 = UiKit.button("PAKAI", Color("4f8cff"), 18)
			b2.pressed.connect(func(): _equip(sid))
		else:
			var cost2: int = int(s["cost"])
			var is_gem: bool = s["currency"] == "gems"
			b2 = UiKit.button("%d %s" % [cost2, "GEM" if is_gem else "KOIN"], Color("ff9f1c"), 18)
			b2.disabled = (GameManager.get_gems() if is_gem else GameManager.get_coins()) < cost2
			b2.pressed.connect(func(): _buy_skin(sid))
		_list.add_child(_row(str(s["name"]), "", "", b2, Color(s["color"])))

	_list.add_child(UiKit.label("LAINNYA", 18, UiKit.C_YELLOW, 0, HORIZONTAL_ALIGNMENT_LEFT))
	var gem := UiKit.button("+10 GEM (DUMMY)", Color("2bb3d6"), 18)
	gem.pressed.connect(func(): GameManager.add_gems(10))
	_list.add_child(gem)
	var note := UiKit.label("Gem hanya dummy untuk uji coba. Tidak ada pembayaran asli.", 13, Color("b9aed0"))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_list.add_child(note)

	var opts := HBoxContainer.new()
	opts.add_theme_constant_override("separation", 8)
	_list.add_child(opts)
	var hap := GameManager.haptic_on()
	var hb := UiKit.button("GETAR: %s" % ("ON" if hap else "OFF"), Color("7a5cff") if hap else Color("5a5566"), 18)
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.pressed.connect(func(): GameManager.set_haptic(not GameManager.haptic_on()))
	opts.add_child(hb)
	var snd := GameManager.sound_on()
	var sb := UiKit.button("SUARA: %s" % ("ON" if snd else "OFF"), Color("7a5cff") if snd else Color("5a5566"), 18)
	sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sb.pressed.connect(func(): GameManager.set_sound(not GameManager.sound_on()))
	opts.add_child(sb)


func _row(title: String, desc: String, info: String, btn: Button, swatch: Color = Color(0, 0, 0, 0)) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.style(Color("3a2f45"), 14))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	panel.add_child(h)
	if swatch.a > 0.0:
		var sw := Panel.new()
		sw.custom_minimum_size = Vector2(36, 36)
		sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sw.add_theme_stylebox_override("panel", UiKit.style(swatch, 8, swatch.darkened(0.4), 3, 0))
		h.add_child(sw)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UiKit.label(title, 19, Color.WHITE, 0, HORIZONTAL_ALIGNMENT_LEFT))
	if desc != "":
		var d := UiKit.label(desc, 13, Color("b9aed0"), 0, HORIZONTAL_ALIGNMENT_LEFT)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(d)
	if info != "":
		v.add_child(UiKit.label(info, 14, UiKit.C_GREEN, 0, HORIZONTAL_ALIGNMENT_LEFT))
	btn.custom_minimum_size = Vector2(120, 52)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(btn)
	return panel


func _buy_upgrade(id: String) -> void:
	if GameManager.buy_upgrade(id) and sfx != null:
		sfx.buy()


func _buy_skin(id: String) -> void:
	if GameManager.buy_skin(id) and sfx != null:
		sfx.buy()


func _equip(id: String) -> void:
	GameManager.equip_skin(id)
	if sfx != null:
		sfx.click()
