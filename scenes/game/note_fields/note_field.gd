class_name NoteField extends Node2D


@export var takes_input: bool = false
@export_enum('Opponent', 'Player') var side: int = 0
@export var ignore_speed_changes: bool = false
@export var default_note_splash: PackedScene = null

@onready var _receptors_node: Node2D = $receptors
@onready var _receptors: Array = []
@onready var _notes: Node2D = $notes

var _note_index: int = 0
var _chart: Chart = null
var _scroll_speed: float = -1.0
var _scroll_speed_modifier: float = 1.0
var _default_character: Character = null
var _note_types: NoteTypes = null
var _note_splash_alpha: float = 0.6
var _lane_count: int
var _game: Game = null
var _force_no_chart: bool = false
var _skin: NoteSkin = null

signal note_hit(note: Note)
signal note_miss(note: Note)


func _ready() -> void:
	if is_instance_valid(Game.instance):
		_game = Game.instance
		_game.scroll_speed_changed.connect(_on_scroll_speed_changed)

		if not is_instance_valid(_note_types):
			_note_types = _game.note_types
	if is_instance_valid(Game.chart):
		_chart = Game.chart
	if _scroll_speed <= 0.0:
		_scroll_speed = Game.scroll_speed
	_note_splash_alpha = Config.get_value('interface', 'note_splash_alpha') / 100.0

	# If you have another node in here that isn't a Node2D
	# that is just currently not supported.
	_receptors = _receptors_node.get_children()
	_lane_count = _receptors.size()

	for receptor: Receptor in _receptors:
		receptor.play_anim(&'static')
		receptor.takes_input = takes_input
		receptor._automatically_play_static = not takes_input

	reload_skin()


func _process(_delta: float) -> void:
	if (not _force_no_chart) and \
			(not is_instance_valid(_chart)) and is_instance_valid(Game.chart):
		_chart = Game.chart
	if Config.get_value('performance', 'threaded_note_spawning') and is_inside_tree(): # multithreading weirdness
		call_deferred_thread_group(&'_try_spawning')
	elif not Config.get_value('performance', 'threaded_note_spawning'):
		_try_spawning()

	var receptor_ys: Array[float] = [
		_receptors[0].position.y,
		_receptors[1].position.y,
		_receptors[2].position.y,
		_receptors[3].position.y,
	]
	for note: Note in _notes.get_children():
		note.position.y = receptor_ys[note.lane]
		note.position.y -= (Conductor.time - note.data.time) * 1000.0 * 0.45 \
				* _scroll_speed * _scroll_speed_modifier

		if (not note._hit) and (note.data.time + note.data.length
				- Conductor.time < -Receptor.input_zone):
			miss_note(note)

	if not takes_input:
		_auto_input()

	if not (takes_input and is_instance_valid(_default_character)):
		return

	for receptor: Receptor in _receptors:
		if not receptor.pressed:
			continue

		_default_character._sing_timer = 0.0
		break


func _auto_input() -> void:
	for note: Note in _notes.get_children():
		if Conductor.time < note.data.time:
			break
		if note._hit:
			continue
		var receptor: Receptor = _receptors[note.lane]
		if receptor.play_confirm:
			receptor.play_anim(&'confirm', true)
		_on_hit_note(note)


func _input(event: InputEvent) -> void:
	if not takes_input:
		return
	if event.is_echo():
		return
	var receptor: Receptor = null
	for selected: Receptor in _receptors:
		if event.is_action(&'input_%s' % selected.direction):
			receptor = selected
			break
	if not is_instance_valid(receptor):
		return

	var pressed: bool = event.is_pressed()
	if not pressed:
		_receptor_release(receptor)
		return

	_receptor_press(receptor)


func _receptor_press(receptor: Receptor) -> void:
	receptor.pressed = true
	receptor.play_anim(&'press')
	receptor._automatically_play_static = false

	for note: Note in _notes.get_children():
		var before_zone: bool = Conductor.time < note.data.time - Receptor.input_zone
		if before_zone:
			break
		if note._hit:
			continue
		if note.lane != receptor.lane:
			continue

		var after_zone: bool = Conductor.time > note.data.time + Receptor.input_zone
		if not (before_zone or after_zone):
			receptor.hit_note(note)
			_on_hit_note(note)
			break
		break


func _receptor_release(receptor: Receptor) -> void:
	receptor.pressed = false
	receptor.play_anim(&'static')

	for note: Note in _notes.get_children():
		var before_zone: bool = Conductor.time < note.data.time - Receptor.input_zone
		if before_zone:
			break
		if not note._hit:
			continue
		if note.lane != receptor.lane:
			continue

		var lee_way: float = maxf(Conductor.beat_delta / 4.0, 0.1)
		# give a bit of lee-way
		if note.length < lee_way:
			# we do this because the animations get funky sometimes lol
			receptor._automatically_play_static = true
			continue

		miss_note(note)


func _on_hit_note(note: Note) -> void:
	if (not is_instance_valid(note._character)) and \
			is_instance_valid(_default_character):
		_default_character.sing(note, true)

	if note._hit:
		return

	note_hit.emit(note)
	note._hit = true

	if note.length > 0.0:
		note.length -= Conductor.time - note.data.time
		note.data.length = note.length
		note._sustain_offset = -(Conductor.time - note.data.time)
		note._update_sustain()


func miss_note(note: Note) -> void:
	if (not is_instance_valid(note._character)) and \
			is_instance_valid(_default_character):
		_default_character.sing_miss(note, true)

	note_miss.emit(note)
	note.queue_free()


func _try_spawning() -> void:
	if (not is_instance_valid(_chart)) or _note_index > _chart.notes.size() - 1:
		return
	var spawn_time: float = 800.0 / (450.0 * _scroll_speed * absf(_scroll_speed_modifier))
	while _note_index < _chart.notes.size() and \
			_chart.notes[_note_index].time - Conductor.time < spawn_time:
		if _note_index > _chart.notes.size() - 1:
			return
		var data: NoteData = _chart.notes[_note_index]
		var skip: bool = data.direction < 0 or \
				(data.direction < 4 if side == 0 else data.direction > 3)
		if skip:# or data.time > Conductor.time + 0.5:
			_note_index += 1
			continue

		data = data.duplicate()
		if data.length > 0.0 and data.length < Conductor.beat_delta / 4.0:
			data.length = 0.0

		var note: Note = _note_types.types.get(data.type, _note_types.types['default']).instantiate()
		note._field = self
		note.data = data
		note.lane = absi(data.direction) % _lane_count
		note.position.x = _receptors[0].position.x + 112.0 * (note.lane % _lane_count)
		note.position.y = -100000.0
		if not is_instance_valid(note.splash):
			note.splash = default_note_splash

		_notes.add_child(note)

		if note.use_skin and is_instance_valid(_skin):
			note.sprite.sprite_frames = _skin.note_frames
			note.scale = _skin.note_scale
			note.sprite.texture_filter = _skin.note_filter

			if is_instance_valid(note.sustain):
				note.clip_rect.scale.x = 1.0 / note.scale.x
				note.sustain.modulate.a = _skin.sustain_alpha
				note.sustain.texture_filter = note.sprite.texture_filter
				note.tail.texture_filter = note.sprite.texture_filter
				note.reload_sustain_sprites()
		note._update_sustain()

		_note_index += 1


func _on_scroll_speed_changed() -> void:
	if ignore_speed_changes:
		return
	_scroll_speed = Game.scroll_speed


func get_receptor_from_lane(lane: int) -> Receptor:
	for receptor: Receptor in _receptors:
		if receptor.lane == lane:
			return receptor
	return null


func reload_skin() -> void:
	if not is_instance_valid(_skin):
		return

	for receptor: Receptor in _receptors:
		receptor.sprite.sprite_frames = _skin.strum_frames
		receptor.sprite.scale = _skin.strum_scale
		receptor.sprite.texture_filter = _skin.strum_filter
		receptor.play_anim(receptor._last_anim)

	for note: Note in _notes.get_children():
		if note.use_skin:
			var animation: StringName = note.sprite.animation
			note.sprite.sprite_frames = _skin.note_frames
			note.sprite.scale = _skin.note_scale
			note.sprite.texture_filter = _skin.note_filter
			note.sprite.play(animation)
			note.sprite.frame = 0
