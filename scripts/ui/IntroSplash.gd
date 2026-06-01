extends Control

const MAIN_SCENE := "res://scenes/main/Main.tscn"
const LOGO_VIDEO := "res://assets/intro/CleanestSYSTEM_logoAnimation.ogv"
const LOGO_POSTER := "res://assets/intro/CleanestSYSTEM_logoAnimation.mp4.png"
const LOGO_SOUND := "res://assets/intro/851333__newlocknew__muscstngr_cinematic-logo-designimpactbright-chord.mp3"
const FALLBACK_SECONDS := 3.0

@onready var _video: VideoStreamPlayer = %LogoVideo
@onready var _poster: TextureRect = %LogoPoster
@onready var _sound: AudioStreamPlayer = %LogoSound
@onready var _fallback_label: Label = %FallbackLabel

var _transitioning := false


func _ready() -> void:
	_fallback_label.visible = false
	_poster.visible = false
	_video.finished.connect(_go_to_game)
	_sound.finished.connect(_on_sound_finished)
	var sound_stream := load(LOGO_SOUND)
	if sound_stream:
		_sound.stream = sound_stream
		_sound.play()
	var video_stream := load(LOGO_VIDEO) if ResourceLoader.exists(LOGO_VIDEO, "VideoStream") else null
	if video_stream != null:
		_video.stream = video_stream
		_video.speed_scale = 2.0
		_video.play()
	else:
		var poster_texture := load(LOGO_POSTER)
		if poster_texture:
			_poster.texture = poster_texture
			_poster.visible = true
		_fallback_label.visible = true
		get_tree().create_timer(FALLBACK_SECONDS).timeout.connect(_go_to_game)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed():
		_go_to_game()


func _on_sound_finished() -> void:
	if _video.stream == null:
		_go_to_game()


func _go_to_game() -> void:
	if _transitioning:
		return
	_transitioning = true
	get_tree().change_scene_to_file(MAIN_SCENE)
