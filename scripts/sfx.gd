extends Node
## Sfx — efek suara yang dibuat lewat kode (tanpa file audio -> APK lebih kecil, tanpa isu lisensi).
## Nada sederhana (sinus + sedikit noise) disintesis sekali saat start, lalu diputar dari pool pemutar.

const RATE := 22050

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _s_tap: AudioStreamWAV
var _s_click: AudioStreamWAV
var _s_buy: AudioStreamWAV
var _s_end: AudioStreamWAV
var _s_win: AudioStreamWAV


func _ready() -> void:
	for i in 8: # 8 suara bisa tumpang tindih -> aman untuk tap cepat
		var p := AudioStreamPlayer.new()
		p.volume_db = -4.0
		add_child(p)
		_players.append(p)
	_s_tap = _tone([[520.0, 200.0, 0.07]], 0.6, 0.18)
	_s_click = _tone([[800.0, 650.0, 0.05]], 0.5, 0.0)
	_s_buy = _tone([[660.0, 990.0, 0.08], [990.0, 1320.0, 0.14]], 0.5, 0.0)
	_s_end = _tone([[440.0, 330.0, 0.14], [330.0, 220.0, 0.28]], 0.5, 0.0)
	_s_win = _tone([[523.0, 523.0, 0.11], [659.0, 659.0, 0.11], [784.0, 784.0, 0.11], [1047.0, 1047.0, 0.35]], 0.5, 0.0)


func tap() -> void: _play(_s_tap, randf_range(0.9, 1.2))
func click() -> void: _play(_s_click, 1.0)
func buy() -> void: _play(_s_buy, 1.0)
func end() -> void: _play(_s_end, 1.0)
func win() -> void: _play(_s_win, 1.0)


func _play(stream: AudioStream, pitch: float) -> void:
	if not GameManager.sound_on() or _players.is_empty():
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.pitch_scale = pitch
	p.play()


## notes: [[freq_awal, freq_akhir, durasi_detik], ...]
func _tone(notes: Array, vol: float, noise: float) -> AudioStreamWAV:
	var counts: Array[int] = []
	var total := 0
	for n in notes:
		var c := int(float(n[2]) * RATE)
		counts.append(c)
		total += c
	var bytes := PackedByteArray()
	bytes.resize(total * 2)
	var idx := 0
	var phase := 0.0
	for ni in notes.size():
		var n: Array = notes[ni]
		var cnt: int = counts[ni]
		for i in cnt:
			var k := float(i) / float(cnt)
			var f := lerpf(float(n[0]), float(n[1]), k)
			phase += TAU * f / float(RATE)
			var env := minf(1.0, float(i) / 40.0) * pow(1.0 - k, 1.6)
			var s := sin(phase) * (1.0 - noise) + randf_range(-1.0, 1.0) * noise
			bytes.encode_s16(idx * 2, int(clampf(s * env * vol, -1.0, 1.0) * 32767.0))
			idx += 1
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	return w
