class_name NoteField extends Node2D


@export var takes_input: bool = false
@export_enum('Opponent', 'Player') var side: int = 0
@export var ignore_speed_changes: bool = false
@export var default_note_splash: PackedScene = null

@onready var receptors_node: Node2D = $receptors
@onready var receptors: Array = []
@onready var notes: Node2D = $notes

var note_index: int = 0
var chart: Chart = null
var scroll_speed: float = -1.0
var scroll_speed_modifier: float = 1.0
var default_character: Character = null
var note_types: NoteTypes = null
var note_splash_alpha: float = 0.6
var lane_count: int
var game: Game = null
var skin: NoteSkin = null

signal note_hit(note: Note)
signal note_miss(note: Note)


func _ready() -> void:
	if is_instance_valid(Game.instance):
		game = Game.instance
		game.scroll_speed_changed.connect(_on_scroll_speed_changed)

		if not is_instance_valid(note_types):
			note_types = game.note_types
	if is_instance_valid(Game.chart):
		chart = Game.chart
	if scroll_speed <= 0.0:
		scroll_speed = Game.scroll_speed
	note_splash_alpha = Config.get_value('interface', 'note_splash_alpha') / 100.0

	# If you have another node in here that isn't a Node2D
	# that is just currently not supported.
	receptors = receptors_node.get_children()
	lane_count = receptors.size()

	for receptor: Receptor in receptors:
		receptor.play_anim(&'static')
		receptor.takes_input = takes_input
		receptor.automatically_play_static = not takes_input

	reload_skin()


func _process(_delta: float) -> void:
	try_spawning()

	if not takes_input:
		auto_input()

	var receptor_ys: Array[float] = []
	for i: int in lane_count:
		receptor_ys.push_back(receptors[i].position.y)

	for note: Note in notes.get_children():
		note.position.y = receptor_ys[note.lane]
		note.position.y -= (Conductor.time - note.data.time) * 1000.0 * 0.45 \
				* scroll_speed * scroll_speed_modifier

		if note.hit:
			continue
		var difference: float = (
			(note.data.time + note.data.length)
			- Conductor.time
		)

		if difference < -Receptor.input_zone:
			miss_note(note)

	if not (takes_input and is_instance_valid(default_character)):
		return
	for receptor: Receptor in receptors:
		if not receptor.pressed:
			continue

		default_character.sing_timer = 0.0
		break


func auto_input() -> void:
	for note: Note in notes.get_children():
		if Conductor.time < note.data.time:
			break
		if note.hit:
			continue
		var receptor: Receptor = receptors[note.lane]
		if receptor.play_confirm:
			receptor.play_anim(&'confirm', true)
		hit_note(note)


func _input(event: InputEvent) -> void:
	if not takes_input:
		return
	if event.is_echo():
		return
	var receptor: Receptor = null
	for selected: Receptor in receptors:
		if event.is_action(&'input_%s' % selected.direction):
			receptor = selected
			break
	if not is_instance_valid(receptor):
		return

	var pressed: bool = event.is_pressed()
	if not pressed:
		receptor_release(receptor)
		return

	receptor_press(receptor)


func receptor_press(receptor: Receptor) -> void:
	receptor.pressed = true
	receptor.play_anim(&'press')
	receptor.automatically_play_static = false

	for note: Note in notes.get_children():
		var before_zone: bool = Conductor.time < note.data.time - Receptor.input_zone
		if before_zone:
			break
		if note.hit:
			continue
		if note.lane != receptor.lane:
			continue

		var after_zone: bool = Conductor.time > note.data.time + Receptor.input_zone
		if not (before_zone or after_zone):
			receptor.hit_note(note)
			hit_note(note)
		break


func receptor_release(receptor: Receptor) -> void:
	receptor.pressed = false
	receptor.play_anim(&'static')

	for note: Note in notes.get_children():
		var before_zone: bool = Conductor.time < note.data.time - Receptor.input_zone
		if before_zone:
			break
		if not note.hit:
			continue
		if note.lane != receptor.lane:
			continue

		var lee_way: float = maxf(Conductor.beat_delta / 4.0, 0.1)
		# give a bit of lee-way
		if note.length < lee_way:
			# we do this because the animations get funky sometimes lol
			receptor.automatically_play_static = true
			continue

		if takes_input:
			miss_note(note)
		else:
			hit_note(note)


func hit_note(note: Note) -> void:
	var target: Character = default_character
	if is_instance_valid(note.character):
		target = note.character

	if is_instance_valid(target):
		target.sing(note, true)

	if note.hit:
		return

	note_hit.emit(note)
	note.hit = true

	if note.length > 0.0:
		note.length -= Conductor.time - note.data.time
		note.data.length = note.length
		note.sustain_offset = -(Conductor.time - note.data.time)
		note._update_sustain()


func miss_note(note: Note) -> void:
	var target: Character = default_character
	if is_instance_valid(note.character):
		target = note.character

	if is_instance_valid(target):
		target.sing_miss(note, true)

	note_miss.emit(note)
	note.hide()
	note.queue_free()


func try_spawning(skip: bool = false) -> void:
	if not is_instance_valid(chart):
		return
	if note_index > chart.notes.size() - 1:
		return

	var speed_modifier: float = scroll_speed * absf(scroll_speed_modifier)
	var spawn_time: float = 800.0 / (450.0 * speed_modifier)
	while true:
		if note_index > chart.notes.size() - 1:
			return
		if chart.notes[note_index].time - Conductor.time > spawn_time:
			return
		if skip:
			note_index += 1
			continue

		var data: NoteData = chart.notes[note_index]
		var note_side: int = 1
		if data.direction > 3:
			note_side = 0

		if note_side != side:
			note_index += 1
			continue

		data = data.duplicate()
		if data.length > 0.0 and data.length < Conductor.step_delta:
			data.length = 0.0

		var scene: PackedScene = note_types.types.get(data.type)
		if not is_instance_valid(scene):
			note_types.types.get('default')
		assert(is_instance_valid(scene), 'You don\'t have any valid note types.')

		var note: Note = scene.instantiate()
		note.field = self
		note.data = data
		note.lane = absi(data.direction) % lane_count
		note.position.x = receptors[note.lane].position.x
		note.position.y = -100000.0
		if not is_instance_valid(note.splash):
			note.splash = default_note_splash

		notes.add_child(note)

		if note.use_skin and is_instance_valid(skin):
			note.sprite.sprite_frames = skin.note_frames
			note.scale = skin.note_scale
			note.sprite.texture_filter = skin.note_filter

			if is_instance_valid(note.sustain):
				note.clip_rect.scale.x = 1.0 / note.scale.x
				note.sustain.modulate.a = skin.sustain_alpha
				note.sustain.texture_filter = note.sprite.texture_filter
				note.tail.texture_filter = note.sprite.texture_filter
				note.reload_sustain_sprites()
		note._update_sustain()
		note_index += 1


func clear_notes() -> void:
	while notes.get_child_count() > 0:
		var note: Note = notes.get_child(0)
		note.queue_free()
		notes.remove_child(note)


func _on_scroll_speed_changed() -> void:
	if ignore_speed_changes:
		return
	scroll_speed = Game.scroll_speed


func get_receptor_from_lane(lane: int) -> Receptor:
	for receptor: Receptor in receptors:
		if receptor.lane == lane:
			return receptor
	return null


func reload_skin() -> void:
	if not is_instance_valid(skin):
		return

	for receptor: Receptor in receptors:
		receptor.sprite.sprite_frames = skin.strum_frames
		receptor.sprite.scale = skin.strum_scale
		receptor.sprite.texture_filter = skin.strum_filter
		receptor.play_anim(receptor._last_anim)

	for note: Note in notes.get_children():
		if note.use_skin:
			var animation: StringName = note.sprite.animation
			note.sprite.sprite_frames = skin.note_frames
			note.sprite.scale = skin.note_scale
			note.sprite.texture_filter = skin.note_filter
			note.sprite.play(animation)
			note.sprite.frame = 0
