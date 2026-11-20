extends RefCounted
## ClickCounter — total tap ronde ini + Clicks/s (jumlah tap dalam 1 detik terakhir).

const WINDOW_MS := 1000

var total: int = 0
var _stamps: Array[int] = []


func reset() -> void:
	total = 0
	_stamps.clear()


func register_tap() -> void:
	total += 1
	_stamps.append(Time.get_ticks_msec())


func cps() -> float:
	var now := Time.get_ticks_msec()
	while not _stamps.is_empty() and now - _stamps[0] > WINDOW_MS:
		_stamps.pop_front()
	return float(_stamps.size())
