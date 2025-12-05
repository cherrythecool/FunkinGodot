class_name NoteField extends Node2D


@export_category('Gameplay')
@export var takes_input: bool = false
@export_enum('Opponent', 'Player') var side: int = 0
@export var note_types: Dictionary[StringName, PackedScene] = {}
@export var conductor: Conductor = null

@export_category('Visuals')
@export var use_note_splashes: bool = true
@export var default_note_splash: PackedScene = null
@export var scroll_speed: float = 1.0
@export var ignore_speed_changes: bool = false
@export var skin: NoteSkin = null

@onready var underlay: ColorRect = %underlay
@onready var receptors_node: Node2D = $receptors
@onready var receptors: Array = []
var lane_count: int = 0

@onready var note_container: Node2D = $notes
var notes: Array[Note] = []
var note_data: Array[NoteData] = []
var note_data_index: int = 0

var scroll_speed_modifier: float = 1.0

var game: Game = null
var note_splash_alpha: float = 0.6
var target_character: Character = null

signal note_hit(note: Note)
signal note_miss(note: Note)


func _ready() -> void:
	if is_instance_valid(Game.instance):
		game = Game.instance
		game.scroll_speed_changed.connect(_on_scroll_speed_changed)
	if is_instance_valid(Conductor.instance):
		conductor = Conductor.instance
	
	note_splash_alpha = Config.get_value('interface', 'note_splash_alpha') / 100.0

	if note_types.is_empty():
		note_types[&"default"] = load(Note.DEFAULT_PATH)

	# If you have another node in here that isn't a Node2D
	# that is just currently not supported.
	receptors = receptors_node.get_children()
	lane_count = receptors.size()

	for receptor: Receptor in receptors:
		receptor.play_anim(&'static')
		receptor.takes_input = takes_input
		receptor.automatically_play_static = not takes_input

	reload_skin()


func _process(delta: float) -> void:
	try_spawning()
	if not takes_input:
		auto_input()

	var receptor_ys: PackedFloat64Array = []
	for i: int in lane_count:
		receptor_ys.push_back(receptors[i].position.y)

	for note: Note in notes:
		update_note(note, delta)

	if not (takes_input and is_instance_valid(target_character)):
		return
	for receptor: Receptor in receptors:
		if not receptor.pressed:
			continue

		target_character.sing_timer = 0.0
		break


func update_note(note: Note, delta: float = 0.0) -> void:
	var receptor: Receptor = get_receptor_from_lane(note.lane)
	note.position.y = receptor.position.y
	note.position.y -= (conductor.time - note.data.time) * 1000.0 * 0.45 * get_scroll_speed()

	if note.is_sustain and note.hit:
		if not is_receptor_held(note.lane):
			note.sustain_timer -= delta
		else:
			note.sustain_timer = conductor.sustain_release_delta
			note.sustain_release_when_hit = conductor.sustain_release_delta
			if (
				receptor.play_confirm and
				receptor.last_anim != &"confirm"
			):
				receptor.hit_note(null)
		
		if note.sustain_timer <= 0.0:
			miss_note(note)
			return

	if note.hit:
		return
	var difference: float = note.data.time - conductor.time
	if difference < -note.hit_window:
		miss_note(note)


func auto_input() -> void:
	for note: Note in notes:
		if conductor.time < note.data.time:
			break
		if note.hit:
			continue
		var receptor: Receptor = receptors[note.lane]
		if receptor.play_confirm:
			receptor.play_anim(&'confirm', true)
		hit_note(note)


func _unhandled_input(event: InputEvent) -> void:
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

	for note: Note in notes:
		var before_zone: bool = conductor.time < note.data.time - note.hit_window
		if before_zone:
			break
		if note.hit:
			continue
		if note.lane != receptor.lane:
			continue

		var after_zone: bool = conductor.time > note.data.time + note.hit_window
		if not (before_zone or after_zone):
			receptor.hit_note(note)
			hit_note(note)
		break


func receptor_release(receptor: Receptor) -> void:
	receptor.pressed = false
	receptor.play_anim(&'static')

	for note: Note in notes:
		var before_zone: bool = conductor.time < note.data.time - note.hit_window
		if before_zone:
			break
		if note.is_sustain:
			continue
		if not note.hit:
			continue
		if note.lane != receptor.lane:
			continue

		if takes_input:
			miss_note(note)
		else:
			hit_note(note)


func hit_note(note: Note) -> void:
	var target: Character = target_character
	if is_instance_valid(note.character):
		target = note.character
	if is_instance_valid(target):
		target.sing(note, true)

	if note.hit:
		return

	note_hit.emit(note)
	if note.is_sustain:
		note.sustain_end_time = note.data.time + note.data.length
		note.sustain_length_offset = note.data.time - conductor.time
	
	note.note_hit()
	note.hit = true
	note._process(0.0)


func miss_note(note: Note) -> void:
	var target: Character = target_character
	if is_instance_valid(note.character):
		target = note.character
	if is_instance_valid(target):
		target.sing_miss(note, true)

	note_miss.emit(note)
	note.note_miss()
	remove_note(note)


func remove_note(note: Note, instant: bool = false) -> void:
	notes.erase(note)

	if instant:
		note.free()
	else:
		note.hide()
		note.queue_free()


func clear_notes() -> void:
	while notes.size() > 0:
		remove_note(note_container.get_child(0), true)


func append_chart(chart: Chart) -> void:
	note_data.append_array(chart.notes)
	note_data.sort_custom(func(a: NoteData, b: NoteData) -> bool:
		return a.time < b.time)


func spawn_note(data: NoteData) -> void:
	var note_side: int = 1
	if data.direction > 3:
		note_side = 0

	if note_side != side:
		return

	data = data.duplicate()
	if data.length > 0.0 and data.length < conductor.step_delta:
		data.length = 0.0

	var scene: PackedScene = note_types.get(data.type.to_snake_case())
	if not is_instance_valid(scene):
		scene = note_types.get(&'default')
	if not is_instance_valid(scene):
		printerr('Note field is missing both "%s" and "default" as a note type, it needs either to at least spawn something!' % [data.type])
		return

	var note: Note = scene.instantiate()
	note.field = self
	note.data = data
	note.lane = absi(data.direction) % lane_count
	note.position.x = receptors[note.lane].position.x
	note.position.y = -100000.0
	if not is_instance_valid(note.splash):
		note.splash = default_note_splash
	if not use_note_splashes:
		note.splash = null

	note_container.add_child(note)
	notes.append(note)
	apply_skin_to_note(note)
	note.update_sustain()


func try_spawning(skip: bool = false) -> void:
	if note_data.is_empty():
		return
	if note_data_index > note_data.size() - 1:
		return

	var speed_modifier: float = absf(get_scroll_speed())
	var spawn_time: float = 800.0 / (450.0 * speed_modifier)
	while true:
		if note_data_index > note_data.size() - 1:
			return
		if note_data[note_data_index].time - conductor.time > spawn_time:
			return
		if skip:
			note_data_index += 1
			continue
		spawn_note(note_data[note_data_index])
		note_data_index += 1


func get_receptor_from_lane(lane: int) -> Receptor:
	if receptors.is_empty():
		return null
	
	return receptors[clampi(lane, 0, receptors.size() - 1)]


func is_receptor_held(lane: int) -> bool:
	if not takes_input:
		return true
	
	var receptor: Receptor = get_receptor_from_lane(lane)
	if is_instance_valid(receptor):
		return Input.is_action_pressed(&"input_%s" % [
			receptor.direction
		])
	
	return false


func reload_skin() -> void:
	if not is_instance_valid(skin):
		return

	for receptor: Receptor in receptors:
		receptor.sprite.sprite_frames = skin.get_strum_frames()
		receptor.sprite.scale = skin.strum_scale
		receptor.sprite.texture_filter = skin.strum_filter
		receptor.play_anim(receptor.last_anim)

	for note: Note in notes:
		apply_skin_to_note(note)


func apply_skin_to_note(note: Note) -> void:
	if not is_instance_valid(skin):
		return
	if not note.use_skin:
		return

	var animation: StringName = note.sprite.animation
	note.sprite.sprite_frames = skin.get_note_frames()
	note.scale = skin.note_scale
	note.sprite.texture_filter = skin.note_filter
	note.sprite.play(animation)
	note.sprite.frame = 0

	if note.is_sustain:
		note.reload_sustain_sprites(skin)
		note.update_sustain()


func get_scroll_speed() -> float:
	return (scroll_speed * scroll_speed_modifier) / conductor.rate


func _on_scroll_speed_changed(value: float) -> void:
	if ignore_speed_changes:
		return
	scroll_speed = value
