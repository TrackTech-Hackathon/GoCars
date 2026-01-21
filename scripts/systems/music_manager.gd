extends Node

var music_player: AudioStreamPlayer
var normal_volume_db: float = -5.0
var lowered_volume_db: float = -10.0  # Much quieter for sub-menus
var game_volume_db: float = -15.0  # Very quiet during gameplay

var music_tracks: Array = []
var current_track_index: int = 0

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.bus = "Master"
	music_player.volume_db = normal_volume_db
	
	# Load both music tracks
	music_tracks.append(load("res://assets/audio/BGMUSIC.mp3"))
	music_tracks.append(load("res://assets/audio/BGMUSIC2.mp3"))
	
	# Connect to finished signal to alternate tracks
	music_player.finished.connect(_on_music_finished)

func play_menu_music() -> void:
	if not music_player.playing:
		music_player.stream = music_tracks[current_track_index]
		music_player.play()

func _on_music_finished() -> void:
	# Alternate between the two tracks
	current_track_index = (current_track_index + 1) % music_tracks.size()
	music_player.stream = music_tracks[current_track_index]
	music_player.play()

func stop_music() -> void:
	music_player.stop()

func is_playing() -> bool:
	return music_player.playing

func lower_volume() -> void:
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", lowered_volume_db, 0.3)

func restore_volume() -> void:
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", normal_volume_db, 0.3)

func set_game_volume() -> void:
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", game_volume_db, 0.4)
