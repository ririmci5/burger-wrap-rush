extends Node
## GameManager (autoload) — aturan ekonomi: koin, XP, level, gem, upgrade, skin.
## Semua perubahan data lewat sini, lalu memancarkan `data_changed` agar UI menyegarkan diri.

signal data_changed

const ROUND_TIME: float = 20.0

## Definisi upgrade. Biaya level n = base_cost * growth^n.
const UPGRADES: Dictionary = {
	"coin_value": {"name": "Harga Burger", "desc": "+1 koin untuk setiap burger", "base_cost": 40, "growth": 1.5, "max": 50},
	"time_bonus": {"name": "Bonus Waktu", "desc": "+0.5 detik di setiap ronde", "base_cost": 120, "growth": 1.65, "max": 20},
	"multiplier": {"name": "Multiplier Koin", "desc": "+10% semua koin yang didapat", "base_cost": 200, "growth": 1.75, "max": 30},
}

## Skin kertas pembungkus. currency: "coins" atau "gems".
const SKINS: Array = [
	{"id": "white", "name": "Putih Klasik", "color": "ffffff", "cost": 0, "currency": "coins"},
	{"id": "sky", "name": "Biru Langit", "color": "bfe6ff", "cost": 250, "currency": "coins"},
	{"id": "mint", "name": "Hijau Mint", "color": "c6f5d8", "cost": 600, "currency": "coins"},
	{"id": "pink", "name": "Pink Permen", "color": "ffc4dd", "cost": 15, "currency": "gems"},
	{"id": "gold", "name": "Emas Mewah", "color": "ffd966", "cost": 40, "currency": "gems"},
]

const GEMS_PER_LEVEL_UP := 5
const GEMS_PER_NEW_BEST := 2


# ---------------------------------------------------------------- Akses data
func get_best() -> int: return int(SaveSystem.data["best"])
func get_level() -> int: return int(SaveSystem.data["level"])
func get_xp() -> int: return int(SaveSystem.data["xp"])
func get_coins() -> int: return int(SaveSystem.data["coins"])
func get_gems() -> int: return int(SaveSystem.data["gems"])
func haptic_on() -> bool: return bool(SaveSystem.data["haptic"])
func sound_on() -> bool: return bool(SaveSystem.data["sound"])


## XP yang dibutuhkan untuk naik dari level `lvl` ke level berikutnya (level 1 = 140).
func xp_needed(lvl: int) -> int:
	return int(round(140.0 * pow(1.3, lvl - 1)))


# ---------------------------------------------------------------- Upgrade
func upgrade_level(id: String) -> int:
	return int(SaveSystem.data["upgrades"][id])


func upgrade_cost(id: String) -> int:
	var u: Dictionary = UPGRADES[id]
	return int(float(u["base_cost"]) * pow(float(u["growth"]), upgrade_level(id)))


func upgrade_maxed(id: String) -> bool:
	return upgrade_level(id) >= int(UPGRADES[id]["max"])


## Koin per burger (float agar multiplier kecil tetap terasa; dibulatkan di akhir ronde).
func coin_value() -> float:
	return (1.0 + upgrade_level("coin_value")) * (1.0 + 0.1 * upgrade_level("multiplier"))


func round_time() -> float:
	return ROUND_TIME + 0.5 * upgrade_level("time_bonus")


func buy_upgrade(id: String) -> bool:
	if upgrade_maxed(id) or not _spend_coins(upgrade_cost(id)):
		return false
	SaveSystem.data["upgrades"][id] = upgrade_level(id) + 1
	_commit()
	return true


# ---------------------------------------------------------------- Skin
func owns_skin(id: String) -> bool:
	return id in SaveSystem.data["skins_owned"]


func equipped_skin() -> String:
	return str(SaveSystem.data["skin"])


func get_skin_color() -> Color:
	for s in SKINS:
		if s["id"] == equipped_skin():
			return Color(s["color"])
	return Color.WHITE


func equip_skin(id: String) -> void:
	if owns_skin(id):
		SaveSystem.data["skin"] = id
		_commit()


func buy_skin(id: String) -> bool:
	if owns_skin(id):
		return false
	for s in SKINS:
		if s["id"] != id:
			continue
		var cost: int = int(s["cost"])
		var ok: bool = _spend_coins(cost) if s["currency"] == "coins" else _spend_gems(cost)
		if not ok:
			return false
		SaveSystem.data["skins_owned"].append(id)
		SaveSystem.data["skin"] = id
		_commit()
		return true
	return false


# ---------------------------------------------------------------- Gem (dummy)
## Dummy: dipakai tombol "+10 GEM" di toko. Tidak ada pembayaran asli.
func add_gems(n: int) -> void:
	SaveSystem.data["gems"] = get_gems() + n
	_commit()


func set_haptic(on: bool) -> void:
	SaveSystem.data["haptic"] = on
	_commit()


func set_sound(on: bool) -> void:
	SaveSystem.data["sound"] = on
	_commit()


# ---------------------------------------------------------------- Akhir ronde
## Dipanggil sekali per ronde. Mengembalikan ringkasan untuk layar hasil.
func finish_round(burgers: int, coins_earned: float) -> Dictionary:
	var d: Dictionary = SaveSystem.data
	var res: Dictionary = {
		"burgers": burgers,
		"coins": int(round(coins_earned)),
		"xp": 10 + burgers,
		"new_best": false,
		"levels_gained": 0,
		"gems": 0,
		"level": get_level(),
		"best": get_best(),
	}

	if burgers > get_best():
		d["best"] = burgers
		res["new_best"] = true
		res["gems"] += GEMS_PER_NEW_BEST

	d["coins"] = get_coins() + int(res["coins"])
	d["rounds"] = int(d["rounds"]) + 1
	d["total_burgers"] = int(d["total_burgers"]) + burgers

	# XP & level (bisa naik lebih dari satu level sekaligus)
	d["xp"] = get_xp() + int(res["xp"])
	while d["xp"] >= xp_needed(get_level()):
		d["xp"] = int(d["xp"]) - xp_needed(get_level())
		d["level"] = get_level() + 1
		res["levels_gained"] += 1
		res["gems"] += GEMS_PER_LEVEL_UP

	d["gems"] = get_gems() + int(res["gems"])
	res["level"] = get_level()
	res["best"] = get_best()
	_commit()
	return res


# ---------------------------------------------------------------- Internal
func _spend_coins(n: int) -> bool:
	if get_coins() < n:
		return false
	SaveSystem.data["coins"] = get_coins() - n
	return true


func _spend_gems(n: int) -> bool:
	if get_gems() < n:
		return false
	SaveSystem.data["gems"] = get_gems() - n
	return true


func _commit() -> void:
	SaveSystem.save_game()
	data_changed.emit()
