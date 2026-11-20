extends Node
## SaveSystem (autoload) — penyimpanan lokal berformat JSON di user://.
## Tanpa internet. Disimpan tiap akhir ronde, tiap pembelian, dan saat app di-pause.

const SAVE_PATH := "user://burger_wrap_save.json"
const SAVE_VERSION := 1

## Seluruh data permainan hidup di sini. Tulis lewat GameManager, bukan langsung.
var data: Dictionary = {}


func _ready() -> void:
	load_game()


func _default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"best": 0,
		"level": 1,
		"xp": 0,
		"coins": 0,
		"gems": 10,          # gem premium (dummy, tanpa pembayaran asli)
		"rounds": 0,
		"total_burgers": 0,
		"upgrades": {"coin_value": 0, "time_bonus": 0, "multiplier": 0},
		"skins_owned": ["white"],
		"skin": "white",
		"haptic": true,
		"sound": true,
	}


func load_game() -> void:
	data = _default_data()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return # file rusak -> pakai default

	# Gabungkan dengan default supaya save lama tetap kompatibel saat ada field baru.
	for key in data.keys():
		if not parsed.has(key):
			continue
		match key:
			"upgrades":
				if typeof(parsed[key]) == TYPE_DICTIONARY:
					for u in data["upgrades"].keys():
						if parsed[key].has(u):
							data["upgrades"][u] = int(parsed[key][u])
			"skins_owned":
				if typeof(parsed[key]) == TYPE_ARRAY and not parsed[key].is_empty():
					data[key] = parsed[key]
			_:
				data[key] = parsed[key]

	# JSON menyimpan angka sebagai float -> kembalikan ke int.
	for k in ["best", "level", "xp", "coins", "gems", "rounds", "total_burgers"]:
		data[k] = int(data[k])
	data["level"] = maxi(1, data["level"])


func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("SaveSystem: gagal menulis %s" % SAVE_PATH)
		return
	f.store_string(JSON.stringify(data))
	f.close()


func _notification(what: int) -> void:
	# Android: app dipindah ke background / ditutup -> simpan.
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
