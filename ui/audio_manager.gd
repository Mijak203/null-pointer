extends Node

@onready var music_player: AudioStreamPlayer = $MusicPlayer

func play_music(new_stream: AudioStream):
	if music_player.stream == new_stream and music_player.playing:
		return 
	
	if music_player.playing:
		var tween_out = create_tween()
		tween_out.tween_property(music_player, "volume_db", -80.0, 1.0)
		await tween_out.finished
	
	music_player.stream = new_stream
	music_player.volume_db = -80.0
	music_player.play()
	var tween_in = create_tween()
	tween_in.tween_property(music_player, "volume_db", 0.0, 1.0)

func stop_music():
	music_player.stop()
