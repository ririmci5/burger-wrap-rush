extends Node
## TimerSystem — hitung mundur ronde. Memancarkan `tick` tiap frame dan `finished` saat habis.

signal tick(time_left: float)
signal finished

var time_left: float = 0.0
var running: bool = false


func _ready() -> void:
	set_process(false)


func start(duration: float) -> void:
	time_left = duration
	running = true
	set_process(true)
	tick.emit(time_left)


func stop() -> void:
	running = false
	set_process(false)


func add_time(seconds: float) -> void:
	time_left += seconds


func _process(delta: float) -> void:
	if not running:
		return
	time_left = maxf(0.0, time_left - delta)
	tick.emit(time_left)
	if time_left <= 0.0:
		stop()
		finished.emit()
