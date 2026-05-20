extends Node
## Audio playback hub. Two channels (music, SFX) and a pool of one-shot SFX
## players to allow overlapping plays.
##
## All AudioStream slots default to null and get a procedurally-generated
## placeholder tone on _ready so the pipeline is audible without external
## assets. Drop real .wav / .ogg files into the slots later via the
## inspector or via AudioManager.<name>_sfx = preload("...").

@export_group("Streams (drop in real audio later)")
@export var attack_swing_sfx: AudioStream
@export var hit_normal_sfx: AudioStream
@export var hit_crit_sfx: AudioStream
@export var skill_cast_sfx: AudioStream
@export var pickup_gold_sfx: AudioStream
@export var pickup_item_sfx: AudioStream
@export var level_up_sfx: AudioStream
@export var enemy_death_sfx: AudioStream
@export var boss_defeat_sfx: AudioStream
@export var shapeshift_sfx: AudioStream
@export var ui_click_sfx: AudioStream

@export_group("Music")
@export var hub_music: AudioStream
@export var dungeon_music: AudioStream
@export var boss_music: AudioStream

@export_group("Mix")
@export_range(0.0, 1.0) var master_volume: float = 0.7
@export_range(0.0, 1.0) var sfx_volume: float = 0.85
@export_range(0.0, 1.0) var music_volume: float = 0.5

const SFX_POOL_SIZE: int = 8

var _music_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_round_robin: int = 0


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	add_child(_music_player)
	for _i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_pool.append(p)

	# Procedural placeholders for any unset stream slots
	if attack_swing_sfx == null:  attack_swing_sfx = _make_swoosh(0.07)
	if hit_normal_sfx == null:    hit_normal_sfx = _make_tone(180.0, 0.10, 0.55)
	if hit_crit_sfx == null:      hit_crit_sfx = _make_tone(330.0, 0.16, 0.25, 0.2)
	if skill_cast_sfx == null:    skill_cast_sfx = _make_sweep(220.0, 660.0, 0.20)
	if pickup_gold_sfx == null:   pickup_gold_sfx = _make_tone(900.0, 0.08, 0.4, 0.1)
	if pickup_item_sfx == null:   pickup_item_sfx = _make_tone(720.0, 0.12, 0.35, 0.1)
	if level_up_sfx == null:      level_up_sfx = _make_arpeggio([523.25, 659.25, 783.99], 0.45)
	if enemy_death_sfx == null:   enemy_death_sfx = _make_tone(140.0, 0.18, 0.7, 0.4)
	if boss_defeat_sfx == null:   boss_defeat_sfx = _make_sweep(220.0, 60.0, 0.6)
	if shapeshift_sfx == null:    shapeshift_sfx = _make_sweep(120.0, 480.0, 0.5)
	if ui_click_sfx == null:      ui_click_sfx = _make_tone(880.0, 0.04, 0.6)

	# Wire to gameplay signals
	EventBus.sfx_attack_swing.connect(func(): play_sfx(attack_swing_sfx, 0.45))
	EventBus.sfx_hit_landed.connect(_on_hit_landed)
	EventBus.sfx_skill_cast.connect(func(_id): play_sfx(skill_cast_sfx, 0.6))
	EventBus.player_gold_changed.connect(_on_gold_changed)
	EventBus.item_picked_up.connect(func(_item): play_sfx(pickup_item_sfx, 0.5))
	EventBus.player_leveled_up.connect(func(_lvl): play_sfx(level_up_sfx, 0.85))
	EventBus.enemy_died.connect(func(_e, _p): play_sfx(enemy_death_sfx, 0.55))
	EventBus.boss_defeated.connect(func(_b): play_sfx(boss_defeat_sfx, 0.9))
	EventBus.player_shapeshifted.connect(func(_name, active): if active: play_sfx(shapeshift_sfx, 0.85))


# --- Public ---------------------------------------------------------

func play_sfx(stream: AudioStream, volume_scale: float = 1.0) -> void:
	if stream == null:
		return
	var player := _sfx_pool[_sfx_round_robin]
	_sfx_round_robin = (_sfx_round_robin + 1) % SFX_POOL_SIZE
	player.stream = stream
	player.volume_db = linear_to_db(master_volume * sfx_volume * volume_scale)
	player.play()


func play_music(stream: AudioStream) -> void:
	if stream == null:
		_music_player.stop()
		return
	if _music_player.stream == stream and _music_player.playing:
		return
	_music_player.stream = stream
	_music_player.volume_db = linear_to_db(master_volume * music_volume)
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()


# --- Listeners ------------------------------------------------------

var _last_gold_total: int = -1


func _on_hit_landed(is_crit: bool) -> void:
	if is_crit:
		play_sfx(hit_crit_sfx, 0.85)
	else:
		play_sfx(hit_normal_sfx, 0.55)


func _on_gold_changed(new_total: int) -> void:
	if _last_gold_total >= 0 and new_total > _last_gold_total:
		play_sfx(pickup_gold_sfx, 0.35)
	_last_gold_total = new_total


# --- Procedural sound synthesis -----------------------------------

const _SAMPLE_RATE: int = 44100


## Sine tone with exponential decay envelope. Optional noise blend.
func _make_tone(freq: float, duration: float, decay: float, noise_amount: float = 0.0) -> AudioStreamWAV:
	var sample_count := int(_SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t: float = float(i) / _SAMPLE_RATE
		var env: float = exp(-t * (10.0 / max(0.001, duration)) * decay)
		var tone: float = sin(t * freq * TAU)
		var noise: float = randf() * 2.0 - 1.0
		var s: float = (tone * (1.0 - noise_amount) + noise * noise_amount) * env
		data.encode_s16(i * 2, int(clamp(s, -1.0, 1.0) * 32767.0))
	return _wrap_wav(data)


## White-noise burst with fast attack and decay — sword swing.
func _make_swoosh(duration: float) -> AudioStreamWAV:
	var sample_count := int(_SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t: float = float(i) / _SAMPLE_RATE
		# Attack-decay envelope
		var attack: float = min(t / (duration * 0.2), 1.0)
		var decay: float = exp(-(t - duration * 0.2) * 25.0) if t > duration * 0.2 else 1.0
		var env: float = attack * decay
		var noise: float = randf() * 2.0 - 1.0
		# Low-pass-ish: average a couple of samples to mellow the noise
		data.encode_s16(i * 2, int(noise * env * 32767.0 * 0.7))
	return _wrap_wav(data)


## Frequency sweep from start to end Hz with exponential decay.
func _make_sweep(freq_start: float, freq_end: float, duration: float) -> AudioStreamWAV:
	var sample_count := int(_SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var phase: float = 0.0
	for i in range(sample_count):
		var t: float = float(i) / _SAMPLE_RATE
		var u: float = t / duration
		var freq: float = lerp(freq_start, freq_end, u)
		phase += freq * TAU / _SAMPLE_RATE
		var env: float = exp(-t * 4.0 / duration)
		var s: float = sin(phase) * env
		data.encode_s16(i * 2, int(s * 32767.0 * 0.8))
	return _wrap_wav(data)


## Three-note rising arpeggio — used for level up.
func _make_arpeggio(freqs: Array, duration: float) -> AudioStreamWAV:
	var sample_count := int(_SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var slice: int = sample_count / freqs.size()
	for i in range(sample_count):
		var idx: int = min(int(i / slice), freqs.size() - 1)
		var t_in_slice: float = float(i - idx * slice) / float(slice)
		var freq: float = float(freqs[idx])
		var env: float = exp(-t_in_slice * 3.0)
		var s: float = sin(float(i) / _SAMPLE_RATE * freq * TAU) * env
		data.encode_s16(i * 2, int(s * 32767.0 * 0.8))
	return _wrap_wav(data)


func _wrap_wav(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = _SAMPLE_RATE
	stream.stereo = false
	return stream
