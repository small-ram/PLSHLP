extends Node
class_name AudioManagerSingleton   # <-- NEW name avoids clash

var _cache : Dictionary = {}

@onready var _player := AudioStreamPlayer.new()

func _ready() -> void:
	add_child(_player)

func play_sfx(name : String) -> void:
	var stream : AudioStream = _cache.get(name)
	if not stream:
		var path := "res://assets/sounds/%s.ogg" % name
		if not FileAccess.file_exists(path):
			push_warning("Missing SFX: " + path)
			return
		stream = load(path)
		_cache[name] = stream
	_player.stream = stream
	_player.play()
