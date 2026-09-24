extends Control

const CASES_PATH := "res://data/cases.json"
const SAVE_PATH := "user://wishful_thinking_save.json"

# ============================================================
# PALETTE
# ============================================================

const WALL := Color("#66665e")
const WALL_LOW := Color("#57574f")
const WALL_TRIM := Color("#3c3d38")

const DESK := Color("#5a3d29")
const DESK_LIGHT := Color("#704d33")
const DESK_DARK := Color("#342318")
const DESK_BLACK := Color("#211711")

const CRT_PLASTIC := Color("#9a927a")
const CRT_LIGHT := Color("#b8ad91")
const CRT_DARK := Color("#4b4639")
const CRT_SCREEN := Color("#101a12")
const CRT_GREEN := Color("#9ebc83")
const CRT_DIM := Color("#607456")

const PHONE := Color("#343631")
const PHONE_LIGHT := Color("#464942")
const PHONE_DARK := Color("#171916")

const PAPER := Color("#d4cbb2")
const PAPER_LIGHT := Color("#e1d9c2")
const PAPER_EDGE := Color("#948b74")
const INK := Color("#292922")

const BINDER := Color("#31463a")
const BINDER_LIGHT := Color("#405a4a")
const BINDER_DARK := Color("#19281f")

const RED := Color("#853a35")
const GREEN := Color("#6f865a")
const AMBER := Color("#a7894c")
const BRASS := Color("#9e8853")


# ============================================================
# GAME STATE
# ============================================================

var cases: Array = []
var case_index := 0
var case_data: Dictionary = {}

var strikes := 0
var calls_completed := 0

var asked_questions: Array[int] = []
var selected_resolution := ""
var selected_rules: Array[String] = []

var case_finished := false
var paperwork_open := false
var waiting_for_case_8_second_step := false

var case_20_callback_unlocked := false
var case_20_callback_used := false

var player_notes: Dictionary = {}
var pending_returns: Array = []

var handbook_rules: Array[String] = [
	"Records Are Always Right.",
	"One Wish Per Person.",
	"Wishes Are Literal.",
	"A Wish Must Be Fulfilled.",
	"Nothing Comes From Nothing.",
	"Ambiguity Does Not Invalidate a Wish.",
	"Identification Is Literal.",
	"Wishes Follow Their Subject.",
	"Death Ends a Wish.",
	"The Wisher Has Authority.",
	"Cancellation Stops; It Does Not Undo.",
	"Cancellation Must Be Requested.",
	"One Wish May Unwish Another.",
	"Free Will Has Consequences.",
	"The Wisher Must Make Their Own Wish.",
	"Wishes Are Restricted Before Age 25.",
	"People Under 25 Are Protected.",
	"Wishes Cannot Be Used to Kill or Torture.",
	"A Broken or Defective Stick Does Not Consume a Wish."
]


# ============================================================
# UI REFERENCES
# ============================================================

var record_labels: Dictionary = {}

var case_number_label: Label
var case_title_label: Label

var phone_dialogue_panel: PanelContainer
var phone_dialogue_label: Label
var phone_status_label: Label
var phone_light: ColorRect

var answer_button: Button
var callback_button: Button

var question_buttons: Array[Button] = []

var worksheet_button: Button
var submit_tray_button: Button
var handbook_button: Button
var drawer_button: Button
var door_button: Button

var strikes_label: Label

var worksheet_overlay: Control
var notes_box: TextEdit
var submit_status_label: Label

var resolution_buttons: Array[Button] = []
var rule_buttons: Array[Button] = []

# Atmosphere / audio
var room_flicker_overlay: ColorRect
var crt_flicker_overlay: ColorRect
var ambient_player: AudioStreamPlayer
var ring_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var audio_streams: Dictionary = {}
var atmosphere_running := true
var lamp_on := true
var lamp_glow: ColorRect
var lamp_bulb: ColorRect
var tutorial_needed := true
var inspect_message: Label
var inspect_panel: PanelContainer


# ============================================================
# START
# ============================================================

func _ready() -> void:
	randomize()

	load_cases()
	load_save()

	build_office()
	setup_audio()
	start_atmosphere()
	load_current_case()
	if tutorial_needed:
		show_tutorial()


# ============================================================
# DATA
# ============================================================

func load_cases() -> void:
	var file := FileAccess.open(
		CASES_PATH,
		FileAccess.READ
	)

	if file == null:
		push_error("Could not open cases.json")
		return

	var parsed = JSON.parse_string(
		file.get_as_text()
	)

	if parsed == null:
		push_error("cases.json contains invalid JSON")
		return

	cases = parsed


func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	tutorial_needed = false

	var file := FileAccess.open(
		SAVE_PATH,
		FileAccess.READ
	)

	if file == null:
		return

	var parsed = JSON.parse_string(
		file.get_as_text()
	)

	if typeof(parsed) != TYPE_DICTIONARY:
		return

	case_index = int(
		parsed.get("case_index", 0)
	)

	strikes = int(
		parsed.get("strikes", 0)
	)

	calls_completed = int(
		parsed.get("calls_completed", 0)
	)

	case_20_callback_used = bool(
		parsed.get(
			"case_20_callback_used",
			false
		)
	)

	player_notes = parsed.get(
		"player_notes",
		{}
	)

	pending_returns = parsed.get(
		"pending_returns",
		[]
	)

	if case_index < 0 or case_index >= cases.size():
		case_index = 0

	if case_index >= 19:
		add_departure_rule()


func save_game() -> void:
	var data := {
		"case_index": case_index,
		"strikes": strikes,
		"calls_completed": calls_completed,
		"case_20_callback_used": case_20_callback_used,
		"player_notes": player_notes,
		"pending_returns": pending_returns
	}

	var file := FileAccess.open(
		SAVE_PATH,
		FileAccess.WRITE
	)

	if file != null:
		file.store_string(
			JSON.stringify(data)
		)


# ============================================================
# OFFICE BUILD
# ============================================================

func build_office() -> void:
	build_room()
	build_poster()
	build_door()
	build_desk()
	build_monitor()
	build_phone()
	build_handbook()
	build_worksheet_stack()
	build_submission_tray()
	build_lamp()
	build_drawers()
	build_small_details()


# ============================================================
# ROOM
# ============================================================

func build_room() -> void:
	var wall := ColorRect.new()
	wall.color = WALL
	wall.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	add_child(wall)

	# Sickly overhead fluorescent cast.
	var ceiling_light := ColorRect.new()
	ceiling_light.color = Color(
		0.84,
		0.85,
		0.72,
		0.055
	)
	ceiling_light.anchor_left = 0.22
	ceiling_light.anchor_right = 0.78
	ceiling_light.anchor_bottom = 0.42
	ceiling_light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ceiling_light)

	# Dirty ceiling shadow.
	var ceiling_shadow := ColorRect.new()
	ceiling_shadow.color = Color(
		0.05,
		0.055,
		0.05,
		0.18
	)
	ceiling_shadow.anchor_right = 1.0
	ceiling_shadow.anchor_bottom = 0.065
	ceiling_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ceiling_shadow)

	# Lower wall.
	var lower_wall := ColorRect.new()
	lower_wall.color = WALL_LOW
	lower_wall.anchor_top = 0.55
	lower_wall.anchor_right = 1.0
	lower_wall.anchor_bottom = 0.64
	lower_wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lower_wall)

	var trim_shadow := ColorRect.new()
	trim_shadow.color = Color(
		0,
		0,
		0,
		0.25
	)
	trim_shadow.anchor_top = 0.545
	trim_shadow.anchor_right = 1.0
	trim_shadow.anchor_bottom = 0.565
	trim_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(trim_shadow)

	var trim := ColorRect.new()
	trim.color = WALL_TRIM
	trim.anchor_top = 0.548
	trim.anchor_right = 1.0
	trim.anchor_bottom = 0.558
	trim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(trim)

	# Subtle wall stains.
	for data in [
		[0.19, 0.12, 0.23, 0.38],
		[0.72, 0.07, 0.76, 0.33],
		[0.79, 0.31, 0.82, 0.53]
	]:
		var stain := ColorRect.new()
		stain.color = Color(
			0.16,
			0.16,
			0.13,
			0.045
		)

		stain.anchor_left = data[0]
		stain.anchor_top = data[1]
		stain.anchor_right = data[2]
		stain.anchor_bottom = data[3]
		stain.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(stain)

	# Vignette-ish side darkness.
	var left_dark := ColorRect.new()
	left_dark.color = Color(
		0.02,
		0.025,
		0.02,
		0.16
	)
	left_dark.anchor_right = 0.025
	left_dark.anchor_bottom = 1.0
	left_dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(left_dark)

	var right_dark := ColorRect.new()
	right_dark.color = Color(
		0.02,
		0.025,
		0.02,
		0.18
	)
	right_dark.anchor_left = 0.975
	right_dark.anchor_right = 1.0
	right_dark.anchor_bottom = 1.0
	right_dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(right_dark)

	var employee := Label.new()
	employee.text = "WISH DEPARTMENT  •  EMPLOYEE 04"
	employee.anchor_left = 0.39
	employee.anchor_top = 0.025
	employee.anchor_right = 0.67
	employee.anchor_bottom = 0.055
	employee.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	employee.add_theme_font_size_override(
		"font_size",
		8
	)
	employee.add_theme_color_override(
		"font_color",
		Color("#aaa894")
	)
	add_child(employee)

	# Full-room fluorescent flicker layer. Nearly invisible most of the time.
	room_flicker_overlay = ColorRect.new()
	room_flicker_overlay.color = Color(0.82, 0.86, 0.70, 0.0)
	room_flicker_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	room_flicker_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room_flicker_overlay.z_index = 40
	add_child(room_flicker_overlay)


# ============================================================
# POSTER
# ============================================================

func build_poster() -> void:
	# Cheap framed motivational poster: a cat hanging from a branch by its paws.
	var root := Control.new()
	root.anchor_left = 0.032
	root.anchor_top = 0.06
	root.anchor_right = 0.178
	root.anchor_bottom = 0.355
	root.rotation = -0.018
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var shadow := Panel.new()
	shadow.anchor_left = 0.035
	shadow.anchor_top = 0.035
	shadow.anchor_right = 1.03
	shadow.anchor_bottom = 1.03
	shadow.add_theme_stylebox_override("panel", make_style(Color(0,0,0,0.30), Color(0,0,0,0), 0, 2))
	root.add_child(shadow)

	var frame := Panel.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_stylebox_override("panel", make_style(Color("#2b251e"), Color("#17130f"), 7, 2))
	root.add_child(frame)

	var paper := Panel.new()
	paper.anchor_left = 0.075
	paper.anchor_top = 0.065
	paper.anchor_right = 0.925
	paper.anchor_bottom = 0.935
	paper.add_theme_stylebox_override("panel", make_style(Color("#d4c9a7"), Color("#8d8269"), 2, 1))
	root.add_child(paper)

	var picture := ColorRect.new()
	picture.color = Color("#8e9f98")
	picture.anchor_left = 0.08
	picture.anchor_top = 0.07
	picture.anchor_right = 0.92
	picture.anchor_bottom = 0.52
	paper.add_child(picture)

	# Branch across the upper part of the picture. The cat hangs BELOW it.
	var branch := ColorRect.new()
	branch.color = Color("#58432d")
	branch.anchor_left = 0.08
	branch.anchor_top = 0.28
	branch.anchor_right = 0.92
	branch.anchor_bottom = 0.34
	picture.add_child(branch)

	# Two forelegs/paws wrapped over the branch.
	for x in [0.42, 0.56]:
		var arm := ColorRect.new()
		arm.color = Color("#302c25")
		arm.anchor_left = x
		arm.anchor_top = 0.18
		arm.anchor_right = x + 0.07
		arm.anchor_bottom = 0.48
		picture.add_child(arm)

	var head := Panel.new()
	head.anchor_left = 0.40
	head.anchor_top = 0.40
	head.anchor_right = 0.64
	head.anchor_bottom = 0.68
	head.add_theme_stylebox_override("panel", make_style(Color("#302c25"), Color("#302c25"), 0, 11))
	picture.add_child(head)

	for x in [0.405, 0.565]:
		var ear := ColorRect.new()
		ear.color = Color("#302c25")
		ear.anchor_left = x
		ear.anchor_top = 0.34
		ear.anchor_right = x + 0.07
		ear.anchor_bottom = 0.50
		ear.rotation = -0.25 if x < 0.5 else 0.25
		picture.add_child(ear)

	var body := Panel.new()
	body.anchor_left = 0.44
	body.anchor_top = 0.61
	body.anchor_right = 0.60
	body.anchor_bottom = 0.96
	body.add_theme_stylebox_override("panel", make_style(Color("#302c25"), Color("#302c25"), 0, 9))
	picture.add_child(body)

	# Tiny eyes make the silhouette read as a cat without turning into ASCII art.
	for x in [0.465, 0.555]:
		var eye := ColorRect.new()
		eye.color = Color("#b9b28e")
		eye.anchor_left = x
		eye.anchor_top = 0.51
		eye.anchor_right = x + 0.018
		eye.anchor_bottom = 0.54
		picture.add_child(eye)

	var title := Label.new()
	title.text = "HANG IN THERE!"
	title.anchor_left = 0.05
	title.anchor_top = 0.57
	title.anchor_right = 0.95
	title.anchor_bottom = 0.73
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color("#343128"))
	paper.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "YOUR WORK MATTERS."
	subtitle.anchor_left = 0.08
	subtitle.anchor_top = 0.76
	subtitle.anchor_right = 0.92
	subtitle.anchor_bottom = 0.88
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 6)
	subtitle.add_theme_color_override("font_color", Color("#625b49"))
	paper.add_child(subtitle)

func build_door() -> void:
	var frame_shadow := ColorRect.new()
	frame_shadow.color = Color(
		0,
		0,
		0,
		0.36
	)
	frame_shadow.anchor_left = 0.842
	frame_shadow.anchor_top = 0.068
	frame_shadow.anchor_right = 0.979
	frame_shadow.anchor_bottom = 0.574
	add_child(frame_shadow)

	var frame := PanelContainer.new()
	frame.anchor_left = 0.835
	frame.anchor_top = 0.055
	frame.anchor_right = 0.97
	frame.anchor_bottom = 0.565

	var frame_style := make_style(
		Color("#302d27"),
		Color("#1d1b17"),
		4,
		1
	)

	frame.add_theme_stylebox_override(
		"panel",
		frame_style
	)
	add_child(frame)

	door_button = Button.new()
	door_button.text = ""

	var normal := make_style(
		Color("#4d4537"),
		Color("#29251f"),
		3,
		1
	)

	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#574d3d")

	var disabled: StyleBoxFlat = normal.duplicate() as StyleBoxFlat

	door_button.add_theme_stylebox_override(
		"normal",
		normal
	)
	door_button.add_theme_stylebox_override(
		"hover",
		hover
	)
	door_button.add_theme_stylebox_override(
		"disabled",
		disabled
	)

	door_button.disabled = true
	door_button.pressed.connect(open_door)
	frame.add_child(door_button)

	for values in [
		[0.10, 0.40],
		[0.56, 0.89]
	]:
		var panel := PanelContainer.new()
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.anchor_left = 0.12
		panel.anchor_right = 0.88
		panel.anchor_top = values[0]
		panel.anchor_bottom = values[1]

		var panel_style := make_style(
			Color("#463e31"),
			Color("#3a3329"),
			2,
			1
		)

		panel.add_theme_stylebox_override(
			"panel",
			panel_style
		)

		door_button.add_child(panel)

	var plaque := Label.new()
	plaque.text = "HEAD OFFICE"
	plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plaque.anchor_left = 0.22
	plaque.anchor_top = 0.44
	plaque.anchor_right = 0.78
	plaque.anchor_bottom = 0.51
	plaque.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plaque.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plaque.add_theme_font_size_override(
		"font_size",
		8
	)
	plaque.add_theme_color_override(
		"font_color",
		Color("#c0ae75")
	)
	door_button.add_child(plaque)

	var knob_shadow := ColorRect.new()
	knob_shadow.color = Color(
		0,
		0,
		0,
		0.45
	)
	knob_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	knob_shadow.anchor_left = 0.80
	knob_shadow.anchor_top = 0.48
	knob_shadow.anchor_right = 0.85
	knob_shadow.anchor_bottom = 0.51
	door_button.add_child(knob_shadow)

	var knob := ColorRect.new()
	knob.color = BRASS
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	knob.anchor_left = 0.785
	knob.anchor_top = 0.47
	knob.anchor_right = 0.835
	knob.anchor_bottom = 0.50
	door_button.add_child(knob)


# ============================================================
# DESK
# ============================================================

func build_desk() -> void:
	# Thick battered desktop, intentionally old and institutional.
	var desk_shadow := ColorRect.new()
	desk_shadow.color = Color(0,0,0,0.42)
	desk_shadow.anchor_left = 0.015
	desk_shadow.anchor_top = 0.585
	desk_shadow.anchor_right = 0.99
	desk_shadow.anchor_bottom = 0.835
	add_child(desk_shadow)

	var desk_top := PanelContainer.new()
	desk_top.anchor_left = 0.015
	desk_top.anchor_top = 0.59
	desk_top.anchor_right = 0.985
	desk_top.anchor_bottom = 0.82
	var desk_style := make_style(Color("#55351f"), Color("#25160e"), 6, 3)
	desk_style.shadow_color = Color(0,0,0,0.45)
	desk_style.shadow_size = 8
	desk_top.add_theme_stylebox_override("panel", desk_style)
	add_child(desk_top)

	# Uneven old wood grain and scratches.
	for i in range(16):
		var grain := ColorRect.new()
		grain.color = Color(0.12,0.055,0.025,0.18 if i % 3 else 0.28)
		grain.anchor_left = 0.025 + (i * 0.059)
		grain.anchor_top = 0.61 + ((i * 17) % 15) * 0.010
		grain.anchor_right = min(grain.anchor_left + 0.035 + ((i % 4) * 0.015), 0.97)
		grain.anchor_bottom = grain.anchor_top + 0.003
		grain.rotation = -0.04 + ((i % 5) * 0.018)
		grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(grain)

	# Chipped front lip.
	var lip := ColorRect.new()
	lip.color = Color("#24150e")
	lip.anchor_left = 0.012
	lip.anchor_top = 0.802
	lip.anchor_right = 0.988
	lip.anchor_bottom = 0.828
	add_child(lip)

	for i in range(8):
		var chip := ColorRect.new()
		chip.color = Color("#7a5131") if i % 2 == 0 else Color("#3a2417")
		chip.anchor_left = 0.06 + i * 0.115
		chip.anchor_top = 0.803
		chip.anchor_right = chip.anchor_left + 0.018
		chip.anchor_bottom = 0.810 + (0.004 if i % 3 == 0 else 0.0)
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(chip)

	var front := ColorRect.new()
	front.color = Color("#342217")
	front.anchor_left = 0.04
	front.anchor_top = 0.827
	front.anchor_right = 0.96
	front.anchor_bottom = 1.0
	add_child(front)

# ============================================================
# MONITOR
# ============================================================

func build_monitor() -> void:
	# Plain Controls/Panels prevent Container layout from stretching the CRT screen.
	var root := Control.new()
	root.anchor_left = 0.275
	root.anchor_top = 0.09
	root.anchor_right = 0.665
	root.anchor_bottom = 0.59
	add_child(root)

	var shadow := Panel.new()
	shadow.anchor_left = 0.02
	shadow.anchor_top = 0.025
	shadow.anchor_right = 1.025
	shadow.anchor_bottom = 1.035
	shadow.add_theme_stylebox_override("panel", make_style(Color(0,0,0,0.30), Color(0,0,0,0), 0, 12))
	root.add_child(shadow)

	var body := Panel.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.add_theme_stylebox_override("panel", make_style(CRT_PLASTIC, CRT_DARK, 6, 10))
	root.add_child(body)

	var screen := Panel.new()
	screen.anchor_left = 0.055
	screen.anchor_top = 0.075
	screen.anchor_right = 0.945
	screen.anchor_bottom = 0.79
	screen.clip_contents = true
	screen.add_theme_stylebox_override("panel", make_style(CRT_SCREEN, Color("#292f29"), 5, 12))
	root.add_child(screen)

	var glass := ColorRect.new()
	glass.color = Color(0.25,0.38,0.20,0.045)
	glass.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(glass)

	var margin := MarginContainer.new()
	margin.anchor_left = 0.035
	margin.anchor_top = 0.035
	margin.anchor_right = 0.965
	margin.anchor_bottom = 0.965
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	screen.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var record := VBoxContainer.new()
	record.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	record.add_theme_constant_override("separation", 5)
	scroll.add_child(record)

	var system := crt_label("WISH DEPARTMENT // CALLER DATABASE", 10)
	system.add_theme_color_override("font_color", CRT_DIM)
	record.add_child(system)
	case_number_label = crt_label("", 10)
	record.add_child(case_number_label)
	case_title_label = crt_label("", 17)
	case_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	record.add_child(case_title_label)
	record.add_child(HSeparator.new())
	add_record_field(record, "name", "NAME")
	add_record_field(record, "age", "AGE")
	add_record_field(record, "wish_status", "WISH STATUS")
	add_record_field(record, "recorded_wish", "RECORDED WISH")
	add_record_field(record, "previous_contacts", "PREVIOUS CONTACTS")
	add_record_field(record, "notes", "NOTES")

	# Subtle scanlines are behind the glitch layer and do not affect layout.
	for i in range(10):
		var scan := ColorRect.new()
		scan.color = Color(0,0,0,0.045)
		scan.anchor_left = 0.015
		scan.anchor_right = 0.985
		scan.anchor_top = 0.06 + i * 0.09
		scan.anchor_bottom = scan.anchor_top + 0.004
		scan.mouse_filter = Control.MOUSE_FILTER_IGNORE
		scan.z_index = 5
		screen.add_child(scan)

	crt_flicker_overlay = ColorRect.new()
	crt_flicker_overlay.color = Color(0.52,0.72,0.43,0.0)
	crt_flicker_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	crt_flicker_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crt_flicker_overlay.z_index = 8
	screen.add_child(crt_flicker_overlay)

	var vents := ColorRect.new()
	vents.color = Color("#5b5748")
	vents.anchor_left = 0.10
	vents.anchor_top = 0.91
	vents.anchor_right = 0.34
	vents.anchor_bottom = 0.925
	root.add_child(vents)
	var power := Label.new()
	power.text = "POWER"
	power.anchor_left = 0.79
	power.anchor_top = 0.885
	power.anchor_right = 0.88
	power.anchor_bottom = 0.94
	power.add_theme_font_size_override("font_size", 6)
	power.add_theme_color_override("font_color", Color("#4c493d"))
	root.add_child(power)
	var led := Panel.new()
	led.anchor_left = 0.90
	led.anchor_top = 0.895
	led.anchor_right = 0.925
	led.anchor_bottom = 0.925
	led.add_theme_stylebox_override("panel", make_style(GREEN, Color("#4a563e"), 1, 8))
	root.add_child(led)

	var neck := ColorRect.new()
	neck.color = CRT_DARK
	neck.anchor_left = 0.445
	neck.anchor_top = 0.59
	neck.anchor_right = 0.505
	neck.anchor_bottom = 0.635
	add_child(neck)
	var base := Panel.new()
	base.anchor_left = 0.365
	base.anchor_top = 0.625
	base.anchor_right = 0.565
	base.anchor_bottom = 0.66
	base.add_theme_stylebox_override("panel", make_style(CRT_PLASTIC, CRT_DARK, 3, 8))
	add_child(base)

func build_phone() -> void:
	# Chunky late-70s/80s house phone: simple sloped base, large handset, number pad.
	var root := Control.new()
	root.anchor_left = 0.675
	root.anchor_top = 0.655
	root.anchor_right = 0.825
	root.anchor_bottom = 0.805
	add_child(root)

	var shadow := Panel.new()
	shadow.anchor_left = 0.04
	shadow.anchor_top = 0.25
	shadow.anchor_right = 1.02
	shadow.anchor_bottom = 1.02
	shadow.add_theme_stylebox_override("panel", make_style(Color(0,0,0,0.32), Color(0,0,0,0), 0, 8))
	root.add_child(shadow)

	var body := Panel.new()
	body.anchor_left = 0.06
	body.anchor_top = 0.24
	body.anchor_right = 0.96
	body.anchor_bottom = 0.98
	body.add_theme_stylebox_override("panel", make_style(Color("#a39b83"), Color("#3f3b31"), 3, 9))
	root.add_child(body)

	var face := Panel.new()
	face.anchor_left = 0.17
	face.anchor_top = 0.43
	face.anchor_right = 0.83
	face.anchor_bottom = 0.92
	face.add_theme_stylebox_override("panel", make_style(Color("#8e8772"), Color("#514b3f"), 2, 5))
	root.add_child(face)

	# Twelve big physical keys.
	var nums := ["1","2","3","4","5","6","7","8","9","*","0","#"]
	for i in range(nums.size()):
		var key := Panel.new()
		var col: int = i % 3
		var row: int = i / 3
		key.anchor_left = 0.08 + col * 0.30
		key.anchor_right = key.anchor_left + 0.22
		key.anchor_top = 0.08 + row * 0.22
		key.anchor_bottom = key.anchor_top + 0.16
		key.add_theme_stylebox_override("panel", make_style(Color("#b3ad99"), Color("#4c493f"), 1, 3))
		face.add_child(key)
		var label := Label.new()
		label.text = nums[i]
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 6)
		label.add_theme_color_override("font_color", Color("#37352e"))
		key.add_child(label)

	phone_light = ColorRect.new()
	phone_light.color = RED
	phone_light.anchor_left = 0.86
	phone_light.anchor_top = 0.55
	phone_light.anchor_right = 0.90
	phone_light.anchor_bottom = 0.60
	root.add_child(phone_light)

	callback_button = dark_button("REDIAL")
	callback_button.anchor_left = 0.82
	callback_button.anchor_top = 0.70
	callback_button.anchor_right = 0.96
	callback_button.anchor_bottom = 0.88
	callback_button.add_theme_font_size_override("font_size", 5)
	callback_button.pressed.connect(call_back)
	root.add_child(callback_button)

	# Receiver is the answer control.
	answer_button = Button.new()
	answer_button.text = ""
	answer_button.anchor_left = 0.00
	answer_button.anchor_top = 0.00
	answer_button.anchor_right = 1.00
	answer_button.anchor_bottom = 0.34
	var rn := make_style(Color("#8b8572"), Color("#37342c"), 3, 14)
	var rh: StyleBoxFlat = rn.duplicate() as StyleBoxFlat
	rh.bg_color = Color("#9b947e")
	var rd: StyleBoxFlat = rn.duplicate() as StyleBoxFlat
	answer_button.add_theme_stylebox_override("normal", rn)
	answer_button.add_theme_stylebox_override("hover", rh)
	answer_button.add_theme_stylebox_override("disabled", rd)
	answer_button.pressed.connect(answer_phone)
	root.add_child(answer_button)
	for x in [0.015, 0.805]:
		var ear := Panel.new()
		ear.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ear.anchor_left = x
		ear.anchor_top = 0.02
		ear.anchor_right = x + 0.18
		ear.anchor_bottom = 0.98
		ear.add_theme_stylebox_override("panel", make_style(Color("#77715f"), Color("#37342c"), 2, 11))
		answer_button.add_child(ear)
	var grip := ColorRect.new()
	grip.color = Color(1,1,0.9,0.07)
	grip.anchor_left = 0.22
	grip.anchor_top = 0.16
	grip.anchor_right = 0.78
	grip.anchor_bottom = 0.24
	grip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	answer_button.add_child(grip)

	# Short coiled cord at the right edge.
	for i in range(7):
		var cord := ColorRect.new()
		cord.color = Color("#292923")
		cord.anchor_left = 0.818 + (0.006 if i % 2 else 0.0)
		cord.anchor_top = 0.70 + i * 0.013
		cord.anchor_right = cord.anchor_left + 0.008
		cord.anchor_bottom = cord.anchor_top + 0.005
		cord.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(cord)

	build_phone_dialogue()

func build_phone_dialogue() -> void:
	phone_dialogue_panel = PanelContainer.new()

	phone_dialogue_panel.anchor_left = 0.045
	phone_dialogue_panel.anchor_top = 0.35
	phone_dialogue_panel.anchor_right = 0.25
	phone_dialogue_panel.anchor_bottom = 0.645

	var style := make_style(
		Color("#252823"),
		Color("#10120f"),
		4,
		4
	)

	style.shadow_color = Color(
		0,
		0,
		0,
		0.45
	)
	style.shadow_size = 6

	phone_dialogue_panel.add_theme_stylebox_override(
		"panel",
		style
	)

	add_child(phone_dialogue_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override(
		"separation",
		4
	)
	phone_dialogue_panel.add_child(box)

	phone_status_label = Label.new()
	phone_status_label.text = "CONNECTED"
	phone_status_label.add_theme_font_size_override(
		"font_size",
		8
	)
	phone_status_label.add_theme_color_override(
		"font_color",
		Color("#a6a995")
	)
	box.add_child(phone_status_label)

	var display := PanelContainer.new()
	display.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var display_style := make_style(
		Color("#c7c1aa"),
		Color("#11130f"),
		3,
		2
	)

	display_style.content_margin_left = 8
	display_style.content_margin_right = 8
	display_style.content_margin_top = 7
	display_style.content_margin_bottom = 7

	display.add_theme_stylebox_override(
		"panel",
		display_style
	)
	box.add_child(display)

	var text_scroll := ScrollContainer.new()
	text_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	display.add_child(text_scroll)

	phone_dialogue_label = Label.new()
	phone_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	phone_dialogue_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	phone_dialogue_label.add_theme_font_size_override(
		"font_size",
		10
	)
	phone_dialogue_label.add_theme_color_override(
		"font_color",
		INK
	)
	text_scroll.add_child(phone_dialogue_label)

	var question_scroll := ScrollContainer.new()
	question_scroll.custom_minimum_size.y = 90
	box.add_child(question_scroll)

	var questions := VBoxContainer.new()
	questions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	questions.add_theme_constant_override(
		"separation",
		2
	)
	question_scroll.add_child(questions)

	for i in range(4):
		var button := dark_button("")
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override(
			"font_size",
			8
		)
		button.pressed.connect(
			ask_question.bind(i)
		)
		questions.add_child(button)
		question_buttons.append(button)

	# Hidden until the receiver is clicked.
	phone_dialogue_panel.visible = false


# ============================================================
# HANDBOOK
# ============================================================

func build_handbook() -> void:
	var shadow := ColorRect.new()
	shadow.color = Color(
		0,
		0,
		0,
		0.30
	)
	shadow.anchor_left = 0.055
	shadow.anchor_top = 0.705
	shadow.anchor_right = 0.17
	shadow.anchor_bottom = 0.805
	add_child(shadow)

	handbook_button = Button.new()
	handbook_button.text = ""

	# Entirely on desktop.
	handbook_button.anchor_left = 0.045
	handbook_button.anchor_top = 0.675
	handbook_button.anchor_right = 0.16
	handbook_button.anchor_bottom = 0.79

	var normal := make_style(
		BINDER,
		BINDER_DARK,
		4,
		4
	)

	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = BINDER_LIGHT
	hover.border_color = Color("#9f9874")

	handbook_button.add_theme_stylebox_override(
		"normal",
		normal
	)
	handbook_button.add_theme_stylebox_override(
		"hover",
		hover
	)

	handbook_button.pressed.connect(
		open_handbook
	)
	add_child(handbook_button)

	var spine := ColorRect.new()
	spine.color = BINDER_DARK
	spine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spine.anchor_left = 0.04
	spine.anchor_right = 0.14
	spine.anchor_bottom = 1.0
	handbook_button.add_child(spine)

	var stripe := ColorRect.new()
	stripe.color = Color(
		0.8,
		0.75,
		0.52,
		0.20
	)
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stripe.anchor_left = 0.75
	stripe.anchor_right = 0.82
	stripe.anchor_bottom = 1.0
	handbook_button.add_child(stripe)

	var title := Label.new()
	title.text = "WISH\nCODE"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.anchor_left = 0.18
	title.anchor_top = 0.13
	title.anchor_right = 0.88
	title.anchor_bottom = 0.63
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(
		"font_size",
		16
	)
	title.add_theme_color_override(
		"font_color",
		Color("#d2c79f")
	)
	handbook_button.add_child(title)

	var small := Label.new()
	small.text = "EMPLOYEE HANDBOOK"
	small.mouse_filter = Control.MOUSE_FILTER_IGNORE
	small.anchor_left = 0.16
	small.anchor_top = 0.72
	small.anchor_right = 0.90
	small.anchor_bottom = 0.90
	small.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	small.add_theme_font_size_override(
		"font_size",
		6
	)
	small.add_theme_color_override(
		"font_color",
		Color("#aaa27d")
	)
	handbook_button.add_child(small)


# ============================================================
# WORKSHEET STACK
# ============================================================

func build_worksheet_stack() -> void:
	for i in range(3):
		var backing := PanelContainer.new()

		backing.anchor_left = 0.50 + (i * 0.005)
		backing.anchor_top = 0.695 + (i * 0.006)
		backing.anchor_right = 0.655 + (i * 0.005)
		backing.anchor_bottom = 0.80 + (i * 0.006)

		var style := make_style(
			PAPER_EDGE,
			Color("#756e5d"),
			1,
			1
		)

		backing.add_theme_stylebox_override(
			"panel",
			style
		)
		add_child(backing)

	worksheet_button = Button.new()
	worksheet_button.text = ""

	worksheet_button.anchor_left = 0.49
	worksheet_button.anchor_top = 0.675
	worksheet_button.anchor_right = 0.65
	worksheet_button.anchor_bottom = 0.79

	var normal := make_style(
		PAPER,
		PAPER_EDGE,
		1,
		1
	)

	normal.shadow_color = Color(
		0,
		0,
		0,
		0.28
	)
	normal.shadow_size = 4

	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = PAPER_LIGHT
	hover.border_color = Color("#575346")

	var disabled: StyleBoxFlat = normal.duplicate() as StyleBoxFlat

	worksheet_button.add_theme_stylebox_override(
		"normal",
		normal
	)
	worksheet_button.add_theme_stylebox_override(
		"hover",
		hover
	)
	worksheet_button.add_theme_stylebox_override(
		"disabled",
		disabled
	)

	worksheet_button.pressed.connect(
		open_worksheet
	)

	add_child(worksheet_button)

	var department := Label.new()
	department.text = "WISH DEPARTMENT"
	department.mouse_filter = Control.MOUSE_FILTER_IGNORE
	department.anchor_left = 0.08
	department.anchor_top = 0.08
	department.anchor_right = 0.92
	department.anchor_bottom = 0.23
	department.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	department.add_theme_font_size_override(
		"font_size",
		6
	)
	department.add_theme_color_override(
		"font_color",
		INK
	)
	worksheet_button.add_child(department)

	var title := Label.new()
	title.text = "RESOLUTION\nWORKSHEET"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.anchor_left = 0.08
	title.anchor_top = 0.28
	title.anchor_right = 0.92
	title.anchor_bottom = 0.66
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(
		"font_size",
		11
	)
	title.add_theme_color_override(
		"font_color",
		INK
	)
	worksheet_button.add_child(title)

	for i in range(3):
		var line := ColorRect.new()
		line.color = Color(
			0.20,
			0.20,
			0.18,
			0.40
		)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.anchor_left = 0.18
		line.anchor_right = 0.82
		line.anchor_top = 0.71 + (i * 0.065)
		line.anchor_bottom = line.anchor_top + 0.008
		worksheet_button.add_child(line)


# ============================================================
# SUBMISSION TRAY
# ============================================================

func build_submission_tray() -> void:
	submit_tray_button = Button.new()
	submit_tray_button.text = ""

	submit_tray_button.anchor_left = 0.84
	submit_tray_button.anchor_top = 0.68
	submit_tray_button.anchor_right = 0.955
	submit_tray_button.anchor_bottom = 0.80

	var normal := make_style(
		Color("#292b27"),
		Color("#131512"),
		4,
		3
	)

	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#383a34")
	hover.border_color = Color("#64665b")

	var disabled: StyleBoxFlat = normal.duplicate() as StyleBoxFlat

	submit_tray_button.add_theme_stylebox_override(
		"normal",
		normal
	)
	submit_tray_button.add_theme_stylebox_override(
		"hover",
		hover
	)
	submit_tray_button.add_theme_stylebox_override(
		"disabled",
		disabled
	)

	submit_tray_button.pressed.connect(
		submit_paperwork
	)
	add_child(submit_tray_button)

	var back := ColorRect.new()
	back.color = Color("#1c1e1a")
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.anchor_left = 0.08
	back.anchor_top = 0.10
	back.anchor_right = 0.92
	back.anchor_bottom = 0.28
	submit_tray_button.add_child(back)

	var slot := ColorRect.new()
	slot.color = Color("#0b0c0a")
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.anchor_left = 0.15
	slot.anchor_top = 0.35
	slot.anchor_right = 0.85
	slot.anchor_bottom = 0.42
	submit_tray_button.add_child(slot)

	var label := Label.new()
	label.text = "HEAD OFFICE\nSUBMISSION"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.anchor_left = 0.08
	label.anchor_top = 0.48
	label.anchor_right = 0.92
	label.anchor_bottom = 0.77
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(
		"font_size",
		8
	)
	label.add_theme_color_override(
		"font_color",
		Color("#c7c5b7")
	)
	submit_tray_button.add_child(label)

	strikes_label = Label.new()
	strikes_label.text = "STRIKES 0 / 3"
	strikes_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strikes_label.anchor_left = 0.08
	strikes_label.anchor_top = 0.80
	strikes_label.anchor_right = 0.92
	strikes_label.anchor_bottom = 0.95
	strikes_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	strikes_label.add_theme_font_size_override(
		"font_size",
		7
	)
	strikes_label.add_theme_color_override(
		"font_color",
		Color("#a9a79a")
	)
	submit_tray_button.add_child(strikes_label)


# ============================================================
# LAMP
# ============================================================

func build_lamp() -> void:
	# Rear-left desk lamp, pushed back beside the monitor. Click shade/base to toggle.
	var root := Control.new()
	root.anchor_left = 0.205
	root.anchor_top = 0.47
	root.anchor_right = 0.335
	root.anchor_bottom = 0.685
	add_child(root)

	lamp_glow = ColorRect.new()
	lamp_glow.color = Color(0.95,0.72,0.35,0.10)
	lamp_glow.anchor_left = 0.28
	lamp_glow.anchor_top = 0.42
	lamp_glow.anchor_right = 1.55
	lamp_glow.anchor_bottom = 1.48
	lamp_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lamp_glow.z_index = -1
	root.add_child(lamp_glow)

	var base := Panel.new()
	base.anchor_left = 0.05
	base.anchor_top = 0.80
	base.anchor_right = 0.42
	base.anchor_bottom = 0.96
	base.add_theme_stylebox_override("panel", make_style(Color("#2b2e29"), Color("#141612"), 3, 10))
	root.add_child(base)

	var lower := ColorRect.new()
	lower.color = Color("#3b3e37")
	lower.anchor_left = 0.25
	lower.anchor_top = 0.43
	lower.anchor_right = 0.29
	lower.anchor_bottom = 0.84
	lower.rotation = -0.28
	root.add_child(lower)
	var joint := Panel.new()
	joint.anchor_left = 0.20
	joint.anchor_top = 0.39
	joint.anchor_right = 0.33
	joint.anchor_bottom = 0.52
	joint.add_theme_stylebox_override("panel", make_style(Color("#55584f"), Color("#1b1d19"), 2, 10))
	root.add_child(joint)
	var upper := ColorRect.new()
	upper.color = Color("#3b3e37")
	upper.anchor_left = 0.29
	upper.anchor_top = 0.40
	upper.anchor_right = 0.72
	upper.anchor_bottom = 0.445
	upper.rotation = -0.20
	root.add_child(upper)

	var shade := Panel.new()
	shade.anchor_left = 0.66
	shade.anchor_top = 0.20
	shade.anchor_right = 0.98
	shade.anchor_bottom = 0.48
	shade.rotation = -0.10
	shade.add_theme_stylebox_override("panel", make_style(Color("#30342d"), Color("#151713"), 3, 12))
	root.add_child(shade)
	lamp_bulb = ColorRect.new()
	lamp_bulb.color = Color(1.0,0.80,0.42,0.75)
	lamp_bulb.anchor_left = 0.18
	lamp_bulb.anchor_top = 0.76
	lamp_bulb.anchor_right = 0.82
	lamp_bulb.anchor_bottom = 0.90
	lamp_bulb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.add_child(lamp_bulb)

	var toggle := Button.new()
	toggle.text = ""
	toggle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	toggle.flat = true
	toggle.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	toggle.pressed.connect(toggle_lamp)
	root.add_child(toggle)

func toggle_lamp() -> void:
	lamp_on = not lamp_on
	if is_instance_valid(lamp_glow):
		lamp_glow.visible = lamp_on
	if is_instance_valid(lamp_bulb):
		lamp_bulb.color = Color(1.0,0.80,0.42,0.75) if lamp_on else Color("#49483f")
	play_sfx("click")

func build_drawers() -> void:
	# Three visible drawers on each side, like an old pedestal desk.
	build_cabinet(0.055, 0.805, 0.205, 0.995)
	build_cabinet(0.805, 0.805, 0.955, 0.995)

	# Case 25 secretly targets the top-right drawer.
	drawer_button = Button.new()
	drawer_button.text = ""
	drawer_button.anchor_left = 0.815
	drawer_button.anchor_top = 0.817
	drawer_button.anchor_right = 0.945
	drawer_button.anchor_bottom = 0.868
	var normal := make_style(Color(0,0,0,0), Color(0,0,0,0), 0, 0)
	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(1,1,1,0.035)
	var disabled: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	drawer_button.add_theme_stylebox_override("normal", normal)
	drawer_button.add_theme_stylebox_override("hover", hover)
	drawer_button.add_theme_stylebox_override("disabled", disabled)
	drawer_button.disabled = true
	drawer_button.pressed.connect(open_drawer)
	add_child(drawer_button)

func build_cabinet(
	left: float,
	top: float,
	right: float,
	bottom: float
) -> void:
	var cabinet := Panel.new()
	cabinet.anchor_left = left
	cabinet.anchor_top = top
	cabinet.anchor_right = right
	cabinet.anchor_bottom = bottom
	cabinet.add_theme_stylebox_override("panel", make_style(Color("#402d20"), DESK_BLACK, 3, 2))
	add_child(cabinet)

	for i in range(3):
		var drawer := Panel.new()
		drawer.anchor_left = 0.06
		drawer.anchor_right = 0.94
		drawer.anchor_top = 0.055 + i * 0.315
		drawer.anchor_bottom = 0.29 + i * 0.315
		drawer.add_theme_stylebox_override("panel", make_style(DESK_LIGHT, DESK_BLACK, 2, 2))
		cabinet.add_child(drawer)
		var inset := ColorRect.new()
		inset.color = Color(0.10,0.055,0.03,0.15)
		inset.anchor_left = 0.05
		inset.anchor_top = 0.08
		inset.anchor_right = 0.95
		inset.anchor_bottom = 0.14
		drawer.add_child(inset)
		var handle := Panel.new()
		handle.anchor_left = 0.38
		handle.anchor_top = 0.43
		handle.anchor_right = 0.62
		handle.anchor_bottom = 0.60
		handle.add_theme_stylebox_override("panel", make_style(Color("#211a14"), Color("#110d0a"), 1, 4))
		drawer.add_child(handle)

func build_small_details() -> void:
	# Monitor cable tucked behind paperwork.
	var cable := ColorRect.new()
	cable.color = Color(0.04,0.04,0.035,0.70)
	cable.anchor_left = 0.565
	cable.anchor_top = 0.655
	cable.anchor_right = 0.570
	cable.anchor_bottom = 0.72
	cable.rotation = 0.28
	cable.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cable)

	# Side-view ceramic mug: body + handle. No top-down coffee surface.
	var mug_shadow := Panel.new()
	mug_shadow.anchor_left = 0.355
	mug_shadow.anchor_top = 0.713
	mug_shadow.anchor_right = 0.405
	mug_shadow.anchor_bottom = 0.765
	mug_shadow.add_theme_stylebox_override("panel", make_style(Color(0,0,0,0.24), Color(0,0,0,0), 0, 8))
	add_child(mug_shadow)
	var mug := Panel.new()
	mug.anchor_left = 0.352
	mug.anchor_top = 0.675
	mug.anchor_right = 0.392
	mug.anchor_bottom = 0.752
	mug.add_theme_stylebox_override("panel", make_style(Color("#9b927a"), Color("#504b3e"), 2, 7))
	add_child(mug)
	var lip := ColorRect.new()
	lip.color = Color("#6d6757")
	lip.anchor_left = 0.08
	lip.anchor_top = 0.05
	lip.anchor_right = 0.92
	lip.anchor_bottom = 0.10
	mug.add_child(lip)
	var handle := Panel.new()
	handle.anchor_left = 0.78
	handle.anchor_top = 0.25
	handle.anchor_right = 1.28
	handle.anchor_bottom = 0.72
	handle.add_theme_stylebox_override("panel", make_style(Color(0,0,0,0), Color("#756e5c"), 3, 10))
	mug.add_child(handle)
	var drip := ColorRect.new()
	drip.color = Color(0.20,0.10,0.05,0.28)
	drip.anchor_left = 0.68
	drip.anchor_top = 0.16
	drip.anchor_right = 0.72
	drip.anchor_bottom = 0.52
	mug.add_child(drip)

	# One old coffee ring on the bare wood beside the mug.
	var ring := Panel.new()
	ring.anchor_left = 0.405
	ring.anchor_top = 0.72
	ring.anchor_right = 0.432
	ring.anchor_bottom = 0.76
	ring.add_theme_stylebox_override("panel", make_style(Color(0,0,0,0), Color(0.16,0.08,0.035,0.28), 2, 14))
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ring)

	# Controlled clutter: a pencil by the worksheet, two rubber bands, two clips.
	var pencil := ColorRect.new()
	pencil.color = Color("#b48a3f")
	pencil.anchor_left = 0.555
	pencil.anchor_top = 0.772
	pencil.anchor_right = 0.635
	pencil.anchor_bottom = 0.778
	pencil.rotation = 0.08
	pencil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pencil)
	for data in [[0.435,0.752,0.462,0.757,0.18],[0.448,0.764,0.477,0.769,-0.14]]:
		var band := ColorRect.new()
		band.color = Color("#a56b45")
		band.anchor_left = data[0]
		band.anchor_top = data[1]
		band.anchor_right = data[2]
		band.anchor_bottom = data[3]
		band.rotation = data[4]
		band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(band)
	for x in [0.535, 0.548]:
		var clip := Panel.new()
		clip.anchor_left = x
		clip.anchor_top = 0.765
		clip.anchor_right = x + 0.010
		clip.anchor_bottom = 0.785
		clip.add_theme_stylebox_override("panel", make_style(Color(0,0,0,0), Color("#8c8d82"), 1, 4))
		clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(clip)

	var sticky := Panel.new()
	sticky.anchor_left = 0.205
	sticky.anchor_top = 0.735
	sticky.anchor_right = 0.255
	sticky.anchor_bottom = 0.785
	sticky.rotation = 0.04
	sticky.add_theme_stylebox_override("panel", make_style(Color("#b5a66a"), Color("#756b43"), 1, 1))
	add_child(sticky)
	var sticky_text := Label.new()
	sticky_text.text = "CALL\nMAINT."
	sticky_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sticky_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sticky_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sticky_text.add_theme_font_size_override("font_size", 6)
	sticky_text.add_theme_color_override("font_color", Color("#4b4637"))
	sticky.add_child(sticky_text)

	var stapler := Panel.new()
	stapler.anchor_left = 0.635
	stapler.anchor_top = 0.755
	stapler.anchor_right = 0.682
	stapler.anchor_bottom = 0.782
	stapler.rotation = -0.04
	stapler.add_theme_stylebox_override("panel", make_style(Color("#252724"), Color("#11120f"), 2, 4))
	add_child(stapler)

	# Tally groups carved only into exposed wood left of the mug.
	for group in range(2):
		var gx := 0.265 + group * 0.040
		for mark in range(4):
			var cut := ColorRect.new()
			cut.color = Color(0.10,0.05,0.025,0.68)
			cut.anchor_left = gx + mark * 0.008
			cut.anchor_top = 0.735
			cut.anchor_right = cut.anchor_left + 0.002
			cut.anchor_bottom = 0.772
			cut.rotation = -0.025 + mark * 0.012
			cut.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(cut)
		var slash := ColorRect.new()
		slash.color = Color(0.09,0.045,0.02,0.72)
		slash.anchor_left = gx - 0.002
		slash.anchor_top = 0.748
		slash.anchor_right = gx + 0.034
		slash.anchor_bottom = 0.754
		slash.rotation = -0.55
		slash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(slash)

	# A few unrelated shallow scratches.
	for data in [[0.095,0.645,0.145,0.648,-0.08],[0.575,0.625,0.625,0.628,0.05],[0.885,0.760,0.925,0.763,-0.12]]:
		var scratch := ColorRect.new()
		scratch.color = Color(0.12,0.065,0.035,0.42)
		scratch.anchor_left = data[0]
		scratch.anchor_top = data[1]
		scratch.anchor_right = data[2]
		scratch.anchor_bottom = data[3]
		scratch.rotation = data[4]
		scratch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(scratch)

	# Invisible hotspots make the desk clutter inspectable without adding UI chrome.
	add_clutter_hotspot(Rect2(0.345, 0.665, 0.070, 0.105), "The mug is older than you think. The coffee stain is older than the mug.", "click")
	add_clutter_hotspot(Rect2(0.195, 0.720, 0.070, 0.075), "CALL MAINT. No extension is listed.", "paper")
	add_clutter_hotspot(Rect2(0.625, 0.742, 0.070, 0.055), "A heavy stapler. Property of the Wish Department. Do not remove.", "click")
	add_clutter_hotspot(Rect2(0.425, 0.735, 0.065, 0.055), "Two brittle rubber bands and a couple of bent paper clips.", "click")
	add_clutter_hotspot(Rect2(0.545, 0.755, 0.100, 0.040), "A chewed yellow pencil. Somebody has been nervous at this desk before.", "click")


func load_current_case() -> void:
	if cases.is_empty():
		return

	case_data = cases[case_index]

	asked_questions.clear()
	selected_rules.clear()

	selected_resolution = ""

	case_finished = false
	paperwork_open = false
	waiting_for_case_8_second_step = false
	case_20_callback_unlocked = false

	case_number_label.text = (
		"CASE %03d"
		% int(case_data["id"])
	)

	case_title_label.text = (
		str(case_data["title"]).to_upper()
	)

	clear_record()

	# No dialogue UI until phone answered.
	phone_dialogue_panel.visible = false
	phone_status_label.text = "CONNECTED"
	phone_dialogue_label.text = ""

	phone_light.color = RED

	answer_button.disabled = false
	callback_button.disabled = false

	for i in range(question_buttons.size()):
		if i < case_data["questions"].size():
			question_buttons[i].text = str(
				case_data["questions"][i]["question"]
			)

			question_buttons[i].visible = true
			question_buttons[i].disabled = true
		else:
			question_buttons[i].visible = false

	worksheet_button.disabled = false
	submit_tray_button.disabled = true

	strikes_label.text = (
		"STRIKES %d / 3"
		% strikes
	)

	door_button.disabled = strikes < 3
	drawer_button.disabled = true

	play_sfx("ring")


# ============================================================
# RECORD
# ============================================================

func clear_record() -> void:
	for key in record_labels:
		var label: Label = record_labels[key]

		label.text = (
			str(label.get_meta("heading"))
			+ ":\n—"
		)


func populate_record() -> void:
	set_record(
		"name",
		str(case_data["name"])
	)

	set_record(
		"age",
		format_number(case_data["age"])
	)

	set_record(
		"wish_status",
		str(case_data["wish_status"])
	)

	var wish := str(
		case_data["recorded_wish"]
	)

	if wish == "":
		wish = "—"

	set_record(
		"recorded_wish",
		wish
	)

	set_record(
		"previous_contacts",
		format_number(
			case_data["previous_contacts"]
		)
	)

	set_record(
		"notes",
		str(case_data["notes"])
	)


func add_record_field(
	container: VBoxContainer,
	key: String,
	heading: String
) -> void:
	var label := crt_label(
		heading + ":\n—",
		11
	)

	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	label.set_meta(
		"heading",
		heading
	)

	container.add_child(label)
	record_labels[key] = label


func set_record(
	key: String,
	value: String
) -> void:
	if not record_labels.has(key):
		return

	var label: Label = record_labels[key]

	label.text = "%s:\n%s" % [
		label.get_meta("heading"),
		value
	]


# ============================================================
# PHONE GAMEPLAY
# ============================================================

func answer_phone() -> void:
	if is_instance_valid(ring_player):
		ring_player.stop()
	play_sfx("pickup")
	answer_button.disabled = true

	phone_light.color = GREEN

	populate_record()

	phone_dialogue_panel.visible = true

	phone_status_label.text = "LINE 1 — CONNECTED"

	phone_dialogue_label.text = (
		"%s:\n\n%s"
		% [
			case_data["name"],
			case_data["opening"]
		]
	)

	for button in question_buttons:
		if button.visible:
			button.disabled = false

	save_game()


func ask_question(index: int) -> void:
	play_sfx("click")
	if index in asked_questions:
		return

	asked_questions.append(index)

	question_buttons[index].disabled = true

	var question: Dictionary = (
		case_data["questions"][index]
	)

	phone_dialogue_label.text = (
		"YOU:\n%s\n\n%s:\n%s"
		% [
			question["question"],
			case_data["name"],
			question["answer"]
		]
	)

	if (
		asked_questions.size()
		== case_data["questions"].size()
	):
		trigger_after_questions()

	save_game()


func trigger_after_questions() -> void:
	phone_dialogue_label.text += (
		"\n\n"
		+ str(
			case_data["after_questions"]
		)
	)

	var id := int(case_data["id"])

	if id == 10:
		set_record(
			"notes",
			"Wish recorded June 14, 1979."
		)

	elif id == 13:
		set_record(
			"recorded_wish",
			"I wish I had the most beautiful "
			+ "blue eyes in the world."
		)

	elif id == 20:
		await record_flicker_case_20()

	enable_paperwork()


func call_back() -> void:
	play_sfx("click")
	var id := int(case_data["id"])

	if (
		id == 20
		and case_20_callback_unlocked
		and not case_20_callback_used
	):
		case_20_callback_used = true

		phone_dialogue_panel.visible = true
		phone_status_label.text = "OUTBOUND CALL"

		phone_dialogue_label.text = (
			"Connecting...\n\n"
			+ "A different voice answers."
		)

		await get_tree().create_timer(
			1.2
		).timeout

		case_index = 20

		save_game()
		load_current_case()
		answer_phone()

		return

	phone_dialogue_panel.visible = true
	phone_status_label.text = "OUTBOUND CALL"

	phone_dialogue_label.text = (
		"OUTBOUND CALLS ARE NOT PERMITTED."
	)


# ============================================================
# PAPERWORK
# ============================================================

func enable_paperwork() -> void:
	paperwork_open = true
	worksheet_button.disabled = false

	update_submission_tray()


func open_worksheet() -> void:
	play_sfx("paper")
	if is_instance_valid(worksheet_overlay):
		return

	worksheet_overlay = create_overlay()

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	worksheet_overlay.add_child(center)

	var sheet := PanelContainer.new()

	# Kept slightly smaller than the window at 1152x648.
	sheet.custom_minimum_size = Vector2(
		590,
		500
	)

	var sheet_style := make_style(
		PAPER,
		PAPER_EDGE,
		2,
		1
	)

	sheet_style.shadow_color = Color(
		0,
		0,
		0,
		0.70
	)
	sheet_style.shadow_size = 14

	sheet.add_theme_stylebox_override(
		"panel",
		sheet_style
	)

	center.add_child(sheet)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(
		540,
		450
	)
	box.add_theme_constant_override(
		"separation",
		6
	)

	sheet.add_child(box)

	box.add_child(
		paper_label(
			"WISH DEPARTMENT",
			9,
			HORIZONTAL_ALIGNMENT_CENTER
		)
	)

	box.add_child(
		paper_label(
			"RESOLUTION WORKSHEET",
			20,
			HORIZONTAL_ALIGNMENT_CENTER
		)
	)

	box.add_child(
		paper_label(
			"CASE %03d  //  %s"
			% [
				int(case_data["id"]),
				str(case_data["name"]).to_upper()
			],
			10,
			HORIZONTAL_ALIGNMENT_CENTER
		)
	)

	box.add_child(
		HSeparator.new()
	)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)

	var form := VBoxContainer.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_theme_constant_override(
		"separation",
		6
	)
	scroll.add_child(form)

	form.add_child(
		paper_label(
			"SELECT RESOLUTION",
			10
		)
	)

	resolution_buttons.clear()

	for resolution in [
		"EXPLAIN / NO ACTION",
		"CANCEL WISH",
		"SEND WISH STICK",
		"PROVIDE TERMINATION OPTIONS"
	]:
		var button := paper_button(
			resolution
		)

		button.toggle_mode = true

		button.button_pressed = (
			selected_resolution
			== resolution
		)

		button.pressed.connect(
			select_resolution.bind(
				resolution,
				button
			)
		)

		form.add_child(button)
		resolution_buttons.append(button)

	form.add_child(
		HSeparator.new()
	)

	form.add_child(
		paper_label(
			"APPLICABLE RULE(S) — SELECT AT LEAST ONE",
			10
		)
	)

	rule_buttons.clear()

	for rule in handbook_rules:
		var button := paper_button(
			rule
		)

		button.toggle_mode = true
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		button.button_pressed = (
			rule in selected_rules
		)

		button.pressed.connect(
			toggle_rule.bind(
				rule,
				button
			)
		)

		form.add_child(button)
		rule_buttons.append(button)

	form.add_child(
		HSeparator.new()
	)

	form.add_child(
		paper_label(
			"EMPLOYEE NOTES — OPTIONAL",
			10
		)
	)

	notes_box = TextEdit.new()
	notes_box.custom_minimum_size.y = 85
	notes_box.placeholder_text = (
		"Write any notes for the case file..."
	)

	var case_key := str(
		case_data["id"]
	)

	if player_notes.has(case_key):
		notes_box.text = str(
			player_notes[case_key]
		)

	notes_box.text_changed.connect(
		save_current_notes
	)

	form.add_child(notes_box)

	submit_status_label = paper_label(
		get_worksheet_status(),
		9,
		HORIZONTAL_ALIGNMENT_CENTER
	)

	form.add_child(
		submit_status_label
	)

	var close := paper_button(
		"CLOSE WORKSHEET"
	)

	close.custom_minimum_size.y = 35

	close.pressed.connect(
		close_worksheet
	)

	box.add_child(close)


func select_resolution(
	resolution: String,
	_pressed_button: Button
) -> void:
	selected_resolution = resolution

	for button in resolution_buttons:
		button.button_pressed = (
			button.text == resolution
		)

	if is_instance_valid(
		submit_status_label
	):
		submit_status_label.text = (
			get_worksheet_status()
		)

	update_submission_tray()


func toggle_rule(
	rule: String,
	button: Button
) -> void:
	if button.button_pressed:
		if rule not in selected_rules:
			selected_rules.append(rule)
	else:
		selected_rules.erase(rule)

	if is_instance_valid(
		submit_status_label
	):
		submit_status_label.text = (
			get_worksheet_status()
		)

	update_submission_tray()


func save_current_notes() -> void:
	if not is_instance_valid(
		notes_box
	):
		return

	var case_key := str(
		case_data["id"]
	)

	player_notes[case_key] = (
		notes_box.text
	)

	save_game()


func get_worksheet_status() -> String:
	if selected_resolution == "":
		return "RESOLUTION REQUIRED"

	if selected_rules.is_empty():
		return "AT LEAST ONE RULE REQUIRED"

	return "WORKSHEET COMPLETE — CLOSE AND SUBMIT"


func close_worksheet() -> void:
	save_current_notes()

	if is_instance_valid(
		worksheet_overlay
	):
		worksheet_overlay.queue_free()

	worksheet_overlay = null

	update_submission_tray()


func update_submission_tray() -> void:
	if submit_tray_button == null:
		return

	submit_tray_button.disabled = (
		not paperwork_open
		or selected_resolution == ""
		or selected_rules.is_empty()
	)


# ============================================================
# SUBMISSION
# ============================================================

func submit_paperwork() -> void:
	play_sfx("submit")
	if not paperwork_open:
		return

	if selected_resolution == "":
		return

	if selected_rules.is_empty():
		return

	var case_id := int(
		case_data["id"]
	)

	var case_key := str(case_id)

	if is_instance_valid(notes_box):
		player_notes[case_key] = (
			notes_box.text
		)

	var required_rules: Array = (
		case_data.get(
			"rules",
			[]
		)
	)

	# A submission passes the rule check when the employee cites at least
	# one rule that actually applies. Extra cited rules do not cause a return.
	var correct_rules := false

	for rule in required_rules:
		if str(rule) in selected_rules:
			correct_rules = true
			break

	var resolution_correct := (
		selected_resolution
		== str(
			case_data["correct_resolution"]
		)
	)

	var submission_correct := (
		resolution_correct
		and correct_rules
	)

	if case_id == 8:
		if not waiting_for_case_8_second_step:
			if submission_correct:
				start_case_8_second_step()
			else:
				queue_wrong_submission()
				close_case_silently()

			return

		if selected_resolution != "SEND WISH STICK":
			queue_wrong_submission()
			close_case_silently()
			return

		close_case_silently()
		return

	if not submission_correct:
		queue_wrong_submission()

	close_case_silently()


func start_case_8_second_step() -> void:
	waiting_for_case_8_second_step = true

	phone_dialogue_panel.visible = true

	phone_dialogue_label.text = (
		"BEN'S CANCELLATION HAS BEEN PROCESSED.\n\n"
		+ "Claire remains on the line."
	)

	selected_resolution = ""
	selected_rules.clear()

	update_submission_tray()


func queue_wrong_submission() -> void:
	var delay := randi_range(
		1,
		4
	)

	var notes := ""

	var case_key := str(
		case_data["id"]
	)

	if player_notes.has(case_key):
		notes = str(
			player_notes[case_key]
		)

	var return_data := {
		"case_id": int(case_data["id"]),
		"case_title": str(case_data["title"]),
		"resolution": selected_resolution,
		"rules": selected_rules.duplicate(),
		"notes": notes,
		"return_after": calls_completed + delay
	}

	pending_returns.append(
		return_data
	)


# ============================================================
# CLOSE CASE
# ============================================================

func close_case_silently() -> void:
	case_finished = true
	paperwork_open = false

	var id := int(
		case_data["id"]
	)

	for button in question_buttons:
		button.disabled = true

	worksheet_button.disabled = true
	submit_tray_button.disabled = true

	phone_light.color = Color("#282a26")

	phone_dialogue_panel.visible = true
	phone_status_label.text = "LINE IDLE"

	if id == 10:
		phone_dialogue_label.text = (
			"The line goes quiet."
		)

		await get_tree().create_timer(
			0.8
		).timeout

		clear_record()

	elif id == 14:
		phone_dialogue_label.text = (
			"The call has ended.\n\n"
			+ "The caller record remains "
			+ "on the monitor."
		)

	elif id == 17:
		phone_dialogue_label.text = (
			"UNKNOWN:\n\n"
			+ "He's asleep.\n\n"
			+ "The line disconnects."
		)

	elif id == 18:
		set_record(
			"recorded_wish",
			"I wish Daniel could never "
			+ "get away from me."
		)

		phone_dialogue_label.text = (
			"The caller record changes."
		)

	elif id == 20:
		case_20_callback_unlocked = true
		callback_button.disabled = false

		phone_dialogue_label.text = (
			"The line disconnects."
		)

		add_departure_rule()

		save_game()
		return

	elif id == 25:
		phone_dialogue_label.text = (
			"The paperwork disappears "
			+ "into the Head Office tray.\n\n"
			+ "A soft click comes from "
			+ "the right-hand drawer."
		)

		drawer_button.disabled = false

		save_game()
		return

	else:
		phone_dialogue_label.text = (
			"The line disconnects."
		)

	calls_completed += 1

	save_game()

	var delay := randf_range(
		0.5,
		7.0
	)

	await get_tree().create_timer(
		delay
	).timeout

	var returned := await check_head_office_returns()

	if returned:
		return

	begin_next_call()


# ============================================================
# HEAD OFFICE RETURNS
# ============================================================

func check_head_office_returns() -> bool:
	for i in range(
		pending_returns.size()
	):
		var item: Dictionary = (
			pending_returns[i]
		)

		if (
			int(item["return_after"])
			<= calls_completed
		):
			pending_returns.remove_at(i)

			strikes += 1

			strikes_label.text = (
				"STRIKES %d / 3"
				% strikes
			)

			show_returned_paperwork(
				item
			)

			save_game()
			return true

	return false


func show_returned_paperwork(
	item: Dictionary
) -> void:
	var overlay := create_overlay()

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	overlay.add_child(center)

	var sheet := PanelContainer.new()
	sheet.custom_minimum_size = Vector2(
		590,
		475
	)

	var style := make_style(
		PAPER,
		PAPER_EDGE,
		2,
		1
	)

	style.shadow_color = Color(
		0,
		0,
		0,
		0.72
	)
	style.shadow_size = 15

	sheet.add_theme_stylebox_override(
		"panel",
		style
	)

	center.add_child(sheet)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(
		535,
		420
	)
	box.add_theme_constant_override(
		"separation",
		7
	)

	sheet.add_child(box)

	box.add_child(
		paper_label(
			"WISH DEPARTMENT",
			9,
			HORIZONTAL_ALIGNMENT_CENTER
		)
	)

	box.add_child(
		paper_label(
			"RETURNED FROM HEAD OFFICE",
			19,
			HORIZONTAL_ALIGNMENT_CENTER
		)
	)

	box.add_child(
		HSeparator.new()
	)

	box.add_child(
		paper_label(
			"CASE %03d — %s"
			% [
				int(item["case_id"]),
				str(item["case_title"]).to_upper()
			],
			13
		)
	)

	box.add_child(
		paper_label(
			"SUBMITTED RESOLUTION:\n"
			+ str(item["resolution"]),
			12
		)
	)

	var rules_text := ""

	for rule in item["rules"]:
		if rules_text != "":
			rules_text += "\n"

		rules_text += (
			"• " + str(rule)
		)

	box.add_child(
		paper_label(
			"RULE(S) APPLIED:\n"
			+ rules_text,
			11
		)
	)

	var notes := str(
		item["notes"]
	)

	if notes.strip_edges() == "":
		notes = "—"

	box.add_child(
		paper_label(
			"EMPLOYEE NOTES:\n"
			+ notes,
			11
		)
	)

	var returned := paper_label(
		"RETURNED — DOES NOT COMPLY WITH WISH CODE",
		13,
		HORIZONTAL_ALIGNMENT_CENTER
	)

	returned.add_theme_color_override(
		"font_color",
		RED
	)

	box.add_child(returned)

	var strike := paper_label(
		"STRIKE RECORDED: %d / 3"
		% strikes,
		12,
		HORIZONTAL_ALIGNMENT_CENTER
	)

	strike.add_theme_color_override(
		"font_color",
		RED
	)

	box.add_child(strike)

	var acknowledge := paper_button(
		"ACKNOWLEDGE"
	)

	if strikes >= 3:
		acknowledge.text = (
			"REPORT FOR PERFORMANCE REVIEW"
		)

		acknowledge.pressed.connect(
			start_performance_review.bind(
				overlay
			)
		)
	else:
		acknowledge.pressed.connect(
			close_return.bind(
				overlay
			)
		)

	box.add_child(acknowledge)


func close_return(
	overlay: Control
) -> void:
	overlay.queue_free()

	await get_tree().create_timer(
		0.8
	).timeout

	begin_next_call()


func start_performance_review(
	overlay: Control
) -> void:
	overlay.queue_free()
	performance_review()


# ============================================================
# NEXT CASE
# ============================================================

func begin_next_call() -> void:
	if case_index >= cases.size() - 1:
		return

	case_index += 1

	save_game()
	load_current_case()


# ============================================================
# CASE 20
# ============================================================

func record_flicker_case_20() -> void:
	play_sfx("static")
	await crt_glitch(0.55)
	set_record(
		"recorded_wish",
		"I wish you worked here instead of me."
	)

	await get_tree().create_timer(
		0.65
	).timeout

	set_record(
		"recorded_wish",
		"—"
	)


func add_departure_rule() -> void:
	var rule := (
		"IF YOU NO LONGER WISH TO WORK "
		+ "FOR THE DEPARTMENT, "
		+ "YOU MUST WISH YOURSELF OUT."
	)

	if rule not in handbook_rules:
		handbook_rules.append(rule)


# ============================================================
# HANDBOOK OPEN
# ============================================================

func open_handbook() -> void:
	play_sfx("paper")
	var overlay := create_overlay()

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	overlay.add_child(center)

	var book := PanelContainer.new()
	book.custom_minimum_size = Vector2(
		650,
		490
	)

	var style := make_style(
		Color("#c9bea0"),
		BINDER_DARK,
		9,
		4
	)

	style.shadow_color = Color(
		0,
		0,
		0,
		0.75
	)
	style.shadow_size = 15

	book.add_theme_stylebox_override(
		"panel",
		style
	)

	center.add_child(book)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(
		590,
		430
	)
	box.add_theme_constant_override(
		"separation",
		7
	)
	book.add_child(box)

	box.add_child(
		paper_label(
			"WISH DEPARTMENT",
			9,
			HORIZONTAL_ALIGNMENT_CENTER
		)
	)

	box.add_child(
		paper_label(
			"OFFICIAL WISH CODE",
			21,
			HORIZONTAL_ALIGNMENT_CENTER
		)
	)

	box.add_child(
		paper_label(
			"EMPLOYEE REFERENCE MANUAL",
			9,
			HORIZONTAL_ALIGNMENT_CENTER
		)
	)

	box.add_child(
		HSeparator.new()
	)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)

	var rules := VBoxContainer.new()
	rules.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules.add_theme_constant_override(
		"separation",
		7
	)
	scroll.add_child(rules)

	for i in range(
		handbook_rules.size()
	):
		var rule_name: String = handbook_rules[i]
		var label := paper_label(
			"%02d. %s\n%s"
			% [
				i + 1,
				rule_name,
				get_rule_explanation(rule_name)
			],
			11
		)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		rules.add_child(label)

	var close := paper_button(
		"CLOSE HANDBOOK"
	)

	close.custom_minimum_size.y = 36
	close.pressed.connect(
		overlay.queue_free
	)

	box.add_child(close)


func get_rule_explanation(rule_name: String) -> String:
	match rule_name:
		"Records Are Always Right.":
			return "Treat the official caller record as fact when making a decision. Caller testimony may be mistaken, incomplete, or dishonest."
		"One Wish Per Person.":
			return "A person may make only one valid wish in their lifetime. Once a valid wish is used, that person's wish is spent."
		"Wishes Are Literal.":
			return "A wish follows the words that were actually spoken. Intent, assumptions, and what the wisher meant do not rewrite the wording."
		"A Wish Must Be Fulfilled.":
			return "A valid wish will be carried out. The Department does not reject a valid wish merely because the result is inconvenient or strange."
		"Nothing Comes From Nothing.":
			return "A wish cannot create physical matter from nowhere. Existing matter may be moved, transferred, or changed, and new conditions or abilities may be created."
		"Ambiguity Does Not Invalidate a Wish.":
			return "Vague or ambiguous wording can still form a valid wish. Reality fulfills a valid interpretation rather than cancelling the wish."
		"Identification Is Literal.":
			return "If a wish identifies a person or subject by name or description, the magic follows that literal identification, even if the wisher meant someone else."
		"Wishes Follow Their Subject.":
			return "Once attached to a person or subject, a wish remains attached even if that subject's location, appearance, circumstances, or condition changes."
		"Death Ends a Wish.":
			return "When the person whose wish is sustaining an effect dies, that wish ends. Ordinary consequences that already happened are not automatically reversed."
		"The Wisher Has Authority.":
			return "Only the person who made the wish controls that wish. A person affected by somebody else's wish is not automatically authorized to cancel it."
		"Cancellation Stops; It Does Not Undo.":
			return "Cancellation stops the wish's magic from that point forward. It does not rewind time or automatically restore physical changes and past consequences."
		"Cancellation Must Be Requested.":
			return "Do not cancel a wish merely because cancellation seems helpful. The authorized wisher must clearly request cancellation."
		"One Wish May Unwish Another.":
			return "A person with an unused wish may spend it to wish that another person's wish never happened. This is different from cancellation and consumes the new wisher's one wish."
		"Free Will Has Consequences.":
			return "If a wish overrides another person's free will, the original wisher loses the right to cancel it. The wish may still end through death or a valid unwish by another person."
		"The Wisher Must Make Their Own Wish.":
			return "The eligible person must personally verbalize and understand their own wish. A wish cannot be taken, made on their behalf, or obtained by manipulating someone unable to understand it."
		"Wishes Are Restricted Before Age 25.":
			return "A person under 25 cannot make a normal wish. Before 25, their own wish may be used only when necessary to save their own life or another person's life."
		"People Under 25 Are Protected.":
			return "A wish cannot harmfully affect a person under 25. Fulfillment must avoid causing that protected person harm."
		"Wishes Cannot Be Used to Kill or Torture.":
			return "A wish may not be used to deliberately kill, torture, or cause severe suffering. An eligible adult who attempts such a prohibited wish forfeits their wish; the intended target is unharmed."
		"A Broken or Defective Stick Does Not Consume a Wish.":
			return "If the stick breaks before the wish is completed, or a defective stick fails to register the wish, no wish is consumed and a replacement may be issued."
		_:
			return "Refer to the official Wish Code for application guidance."

# ============================================================
# PERFORMANCE REVIEW
# ============================================================

func performance_review() -> void:
	phone_dialogue_panel.visible = true

	phone_status_label.text = (
		"INTERNAL LINE"
	)

	phone_dialogue_label.text = (
		"MANDATORY PERFORMANCE REVIEW.\n\n"
		+ "Three strikes have been recorded.\n\n"
		+ "Please report to Head Office."
	)

	answer_button.disabled = true
	callback_button.disabled = true
	worksheet_button.disabled = true
	submit_tray_button.disabled = true

	for button in question_buttons:
		button.disabled = true

	door_button.disabled = false


func open_door() -> void:
	play_sfx("door")
	if strikes < 3:
		return

	show_black_screen(
		"MANDATORY PERFORMANCE REVIEW\n\nGAME OVER",
		true
	)


# ============================================================
# ENDING
# ============================================================

func open_drawer() -> void:
	play_sfx("drawer")
	if int(case_data["id"]) != 25:
		return

	drawer_button.disabled = true

	phone_dialogue_panel.visible = true

	phone_status_label.text = (
		"LINE IDLE"
	)

	phone_dialogue_label.text = (
		"The drawer slides open.\n\n"
		+ "Inside is a Wish Stick.\n\n"
		+ "It has your name on it."
	)

	await get_tree().create_timer(
		1.5
	).timeout

	show_player_wish()


func show_player_wish() -> void:
	var overlay := create_overlay()

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(
		550,
		290
	)

	var style := make_style(
		Color("#292b27"),
		Color("#10120f"),
		5,
		5
	)

	panel.add_theme_stylebox_override(
		"panel",
		style
	)

	center.add_child(panel)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(
		490,
		230
	)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override(
		"separation",
		18
	)

	panel.add_child(box)

	box.add_child(
		light_label(
			"WISH STICK",
			21,
			HORIZONTAL_ALIGNMENT_CENTER
		)
	)

	var text := light_label(
		"For the first time, there is no caller "
		+ "on the other end of the phone.",
		14,
		HORIZONTAL_ALIGNMENT_CENTER
	)

	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	box.add_child(text)

	var wish := dark_button(
		"I wish I didn't work for "
		+ "the Department anymore."
	)

	wish.custom_minimum_size.y = 50

	wish.pressed.connect(
		player_makes_wish.bind(
			overlay
		)
	)

	box.add_child(wish)


func player_makes_wish(
	overlay: Control
) -> void:
	overlay.queue_free()

	await get_tree().create_timer(
		0.4
	).timeout

	show_player_file()


func show_player_file() -> void:
	var overlay := create_overlay()

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	overlay.add_child(center)

	var crt := PanelContainer.new()
	crt.custom_minimum_size = Vector2(
		560,
		450
	)

	var outer := make_style(
		CRT_PLASTIC,
		CRT_DARK,
		7,
		10
	)

	crt.add_theme_stylebox_override(
		"panel",
		outer
	)

	center.add_child(crt)

	var screen := PanelContainer.new()

	var screen_style := make_style(
		CRT_SCREEN,
		Color("#0b0f0b"),
		5,
		12
	)

	screen.add_theme_stylebox_override(
		"panel",
		screen_style
	)

	crt.add_child(screen)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(
		490,
		380
	)
	box.add_theme_constant_override(
		"separation",
		9
	)
	screen.add_child(box)

	box.add_child(
		crt_label(
			"WISH DEPARTMENT — CALLER RECORD",
			17
		)
	)

	box.add_child(
		HSeparator.new()
	)

	for text in [
		"NAME:\n[PLAYER NAME]",
		"AGE:\n[PLAYER AGE]",
		"WISH STATUS:\nUSED",
		"RECORDED WISH:\n[REDACTED]",
		"PREVIOUS CONTACTS:\n1",
		"NOTES:\n[REDACTED]"
	]:
		box.add_child(
			crt_label(
				text,
				13
			)
		)

	await get_tree().create_timer(
		3.0
	).timeout

	show_black_screen(
		"WISHFUL THINKING\n\nPART ONE",
		false
	)


# ============================================================
# TRAINING + DESK INSPECTION
# ============================================================

func show_tutorial() -> void:
	var overlay := create_overlay()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var memo := PanelContainer.new()
	memo.custom_minimum_size = Vector2(620, 500)
	var memo_style := make_style(PAPER, PAPER_EDGE, 2, 2)
	memo_style.shadow_color = Color(0,0,0,0.72)
	memo_style.shadow_size = 15
	memo.add_theme_stylebox_override("panel", memo_style)
	center.add_child(memo)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(560, 440)
	box.add_theme_constant_override("separation", 8)
	memo.add_child(box)
	box.add_child(paper_label("WISH DEPARTMENT", 9, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(paper_label("NEW EMPLOYEE — DESK PROCEDURE", 20, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(HSeparator.new())

	var instructions := paper_label(
		"1. When the telephone rings, click the HANDSET to answer. The caller's official record will appear on the computer.\n\n"
		+ "2. Ask all four available questions. Questions may be asked in any order. Read the caller record and the Wish Code carefully — callers may be mistaken, incomplete, or dishonest.\n\n"
		+ "3. The RESOLUTION WORKSHEET may be opened and closed at any time. Select one resolution, select at least one rule you believe applies, and add notes if useful. Your selections remain when the worksheet is closed.\n\n"
		+ "4. After the call is complete, close the worksheet and click the HEAD OFFICE SUBMISSION TRAY. Head Office does not confirm correct work. Returned paperwork means you made an error. Three strikes require a performance review.\n\n"
		+ "5. The WISH CODE handbook is always available. REDIAL is available on the telephone, although outbound calls are normally prohibited.\n\n"
		+ "6. This is your desk. The lamp and ordinary desk objects may be clicked. Some things are only ordinary until they aren't.",
		11
	)
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(instructions)

	var begin := paper_button("BEGIN SHIFT")
	begin.custom_minimum_size.y = 38
	begin.pressed.connect(func():
		play_sfx("paper")
		overlay.queue_free()
	)
	box.add_child(begin)


func add_clutter_hotspot(rect: Rect2, message: String, sound_name: String = "click") -> void:
	var button := Button.new()
	button.text = ""
	button.flat = true
	button.anchor_left = rect.position.x
	button.anchor_top = rect.position.y
	button.anchor_right = rect.position.x + rect.size.x
	button.anchor_bottom = rect.position.y + rect.size.y
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(inspect_clutter.bind(message, sound_name))
	add_child(button)


func inspect_clutter(message: String, sound_name: String = "click") -> void:
	play_sfx(sound_name)
	if is_instance_valid(inspect_panel):
		inspect_panel.queue_free()

	inspect_panel = PanelContainer.new()
	inspect_panel.anchor_left = 0.29
	inspect_panel.anchor_top = 0.865
	inspect_panel.anchor_right = 0.71
	inspect_panel.anchor_bottom = 0.945
	inspect_panel.z_index = 80
	inspect_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inspect_panel.add_theme_stylebox_override("panel", make_style(Color(0.08,0.075,0.065,0.94), Color(0.25,0.23,0.19,0.9), 1, 3))
	add_child(inspect_panel)

	inspect_message = light_label(message, 10, HORIZONTAL_ALIGNMENT_CENTER)
	inspect_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	inspect_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspect_message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inspect_panel.add_child(inspect_message)

	var this_panel := inspect_panel
	await get_tree().create_timer(2.6).timeout
	if is_instance_valid(this_panel):
		this_panel.queue_free()


# ============================================================
# ATMOSPHERE + PROCEDURAL AUDIO
# ============================================================

func setup_audio() -> void:
	ambient_player = AudioStreamPlayer.new()
	ring_player = AudioStreamPlayer.new()
	sfx_player = AudioStreamPlayer.new()
	add_child(ambient_player)
	add_child(ring_player)
	add_child(sfx_player)

	audio_streams["hum"] = make_audio_stream(58.0, 1.0, 0.035, 0.015, true)
	audio_streams["ring"] = make_phone_ring_stream()
	audio_streams["pickup"] = make_audio_stream(120.0, 0.10, 0.20, 0.06, false)
	audio_streams["click"] = make_audio_stream(980.0, 0.045, 0.10, 0.02, false)
	audio_streams["paper"] = make_audio_stream(180.0, 0.16, 0.08, 0.18, false)
	audio_streams["submit"] = make_audio_stream(72.0, 0.18, 0.22, 0.04, false)
	audio_streams["drawer"] = make_audio_stream(95.0, 0.32, 0.15, 0.13, false)
	audio_streams["door"] = make_audio_stream(48.0, 0.42, 0.20, 0.08, false)
	audio_streams["static"] = make_audio_stream(340.0, 0.20, 0.04, 0.35, false)

	ambient_player.stream = audio_streams["hum"]
	ambient_player.volume_db = -13.0
	ambient_player.play()


func make_phone_ring_stream() -> AudioStreamWAV:
	# Old landline cadence: two strong bell bursts, then a pause, looping
	# continuously until the handset is picked up.
	var rate := 22050
	var duration := 2.8
	var sample_count := int(rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for i in range(sample_count):
		var t := float(i) / float(rate)
		var local_t := fmod(t, duration)
		var active := (local_t < 0.42) or (local_t >= 0.58 and local_t < 1.0)
		var wave := 0.0
		if active:
			# Two close frequencies give the mechanical BRRING character.
			wave = (sin(TAU * 430.0 * t) + sin(TAU * 485.0 * t)) * 0.105
			# Add a small tremolo so it reads as a bell, not a pure beep.
			wave *= 0.72 + 0.28 * sin(TAU * 18.0 * t)
		var sample := int(clamp(wave, -1.0, 1.0) * 32767.0)
		data[i * 2] = sample & 0xff
		data[i * 2 + 1] = (sample >> 8) & 0xff

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream


func make_audio_stream(
	frequency: float,
	duration: float,
	volume: float,
	noise_amount: float,
	looping: bool
) -> AudioStreamWAV:
	var rate := 22050
	var sample_count := int(rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t := float(i) / float(rate)
		var wave := sin(TAU * frequency * t) * volume
		if noise_amount > 0.0:
			wave += randf_range(-1.0, 1.0) * noise_amount
		# Tiny fade prevents clicks on one-shot effects.
		if not looping:
			var fade: float = minf(1.0, minf(t / 0.015, (duration - t) / 0.025))
			wave *= max(fade, 0.0)
		var sample := int(clamp(wave, -1.0, 1.0) * 32767.0)
		data[i * 2] = sample & 0xff
		data[i * 2 + 1] = (sample >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	if looping:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = sample_count
	return stream


func play_sfx(name: String) -> void:
	if not audio_streams.has(name):
		return
	if name == "ring":
		ring_player.stream = audio_streams[name]
		ring_player.volume_db = -5.0
		ring_player.play()
	else:
		sfx_player.stream = audio_streams[name]
		sfx_player.volume_db = -7.0
		sfx_player.play()


func start_atmosphere() -> void:
	atmosphere_running = true
	atmosphere_loop()
	crt_idle_loop()


func atmosphere_loop() -> void:
	while atmosphere_running:
		await get_tree().create_timer(randf_range(4.0, 11.0)).timeout
		if not is_instance_valid(room_flicker_overlay):
			continue
		# Most flickers are tiny; occasionally the fluorescent tube sputters twice.
		var flashes := 2 if randf() < 0.22 else 1
		for i in range(flashes):
			room_flicker_overlay.color = Color(0.80, 0.84, 0.68, randf_range(0.025, 0.075))
			if is_instance_valid(ambient_player):
				ambient_player.volume_db = -17.0
			await get_tree().create_timer(randf_range(0.025, 0.075)).timeout
			room_flicker_overlay.color = Color(0.05, 0.055, 0.045, randf_range(0.015, 0.045))
			await get_tree().create_timer(randf_range(0.02, 0.06)).timeout
			room_flicker_overlay.color = Color(0.82, 0.86, 0.70, 0.0)
			if is_instance_valid(ambient_player):
				ambient_player.volume_db = -13.0


func crt_idle_loop() -> void:
	while atmosphere_running:
		await get_tree().create_timer(randf_range(2.5, 7.5)).timeout
		if not is_instance_valid(crt_flicker_overlay):
			continue
		crt_flicker_overlay.color = Color(0.55, 0.75, 0.46, randf_range(0.015, 0.04))
		await get_tree().create_timer(randf_range(0.025, 0.07)).timeout
		crt_flicker_overlay.color = Color(0.52, 0.72, 0.43, 0.0)


func crt_glitch(duration: float = 0.35) -> void:
	if not is_instance_valid(crt_flicker_overlay):
		return
	var elapsed := 0.0
	while elapsed < duration:
		crt_flicker_overlay.color = Color(
			0.58,
			0.78,
			0.48,
			randf_range(0.04, 0.16)
		)
		var wait := randf_range(0.025, 0.07)
		await get_tree().create_timer(wait).timeout
		elapsed += wait
	crt_flicker_overlay.color = Color(0.52, 0.72, 0.43, 0.0)


# ============================================================
# GENERIC UI HELPERS
# ============================================================

func make_style(
	background: Color,
	border: Color,
	border_width: int,
	radius: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()

	style.bg_color = background
	style.border_color = border

	style.set_border_width_all(
		border_width
	)

	style.set_corner_radius_all(
		radius
	)

	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8

	return style


func crt_label(
	text: String,
	size: int
) -> Label:
	var label := Label.new()

	label.text = text

	label.add_theme_font_size_override(
		"font_size",
		size
	)

	label.add_theme_color_override(
		"font_color",
		CRT_GREEN
	)

	return label


func paper_label(
	text: String,
	size: int,
	alignment := HORIZONTAL_ALIGNMENT_LEFT
) -> Label:
	var label := Label.new()

	label.text = text
	label.horizontal_alignment = alignment
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	label.add_theme_font_size_override(
		"font_size",
		size
	)

	label.add_theme_color_override(
		"font_color",
		INK
	)

	return label


func light_label(
	text: String,
	size: int,
	alignment := HORIZONTAL_ALIGNMENT_LEFT
) -> Label:
	var label := Label.new()

	label.text = text
	label.horizontal_alignment = alignment

	label.add_theme_font_size_override(
		"font_size",
		size
	)

	label.add_theme_color_override(
		"font_color",
		Color("#dedbca")
	)

	return label


func dark_button(
	text: String
) -> Button:
	var button := Button.new()

	button.text = text

	var normal := make_style(
		Color("#3c3f39"),
		Color("#20221e"),
		2,
		3
	)

	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#50534b")
	hover.border_color = Color("#707268")

	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#292b27")

	var disabled: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color("#292b27")
	disabled.border_color = Color("#232520")

	button.add_theme_stylebox_override(
		"normal",
		normal
	)

	button.add_theme_stylebox_override(
		"hover",
		hover
	)

	button.add_theme_stylebox_override(
		"pressed",
		pressed
	)

	button.add_theme_stylebox_override(
		"disabled",
		disabled
	)

	button.add_theme_color_override(
		"font_color",
		Color("#dddace")
	)

	button.add_theme_color_override(
		"font_hover_color",
		Color.WHITE
	)

	button.add_theme_color_override(
		"font_disabled_color",
		Color("#74766e")
	)

	return button


func paper_button(
	text: String
) -> Button:
	var button := Button.new()

	button.text = text

	var normal := make_style(
		Color("#d1c8ae"),
		Color("#766f5d"),
		1,
		1
	)

	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#e6dec6")
	hover.border_color = Color("#3c3a31")

	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#b6ab90")

	var disabled: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color("#beb7a3")

	button.add_theme_stylebox_override(
		"normal",
		normal
	)

	button.add_theme_stylebox_override(
		"hover",
		hover
	)

	button.add_theme_stylebox_override(
		"pressed",
		pressed
	)

	button.add_theme_stylebox_override(
		"disabled",
		disabled
	)

	button.add_theme_color_override(
		"font_color",
		INK
	)

	button.add_theme_color_override(
		"font_hover_color",
		Color.BLACK
	)

	button.add_theme_color_override(
		"font_disabled_color",
		Color("#6e6a5f")
	)

	button.add_theme_font_size_override(
		"font_size",
		9
	)

	return button


func create_overlay() -> ColorRect:
	var overlay := ColorRect.new()

	overlay.color = Color(
		0.018,
		0.02,
		0.017,
		0.92
	)

	overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	add_child(overlay)

	return overlay


func format_number(value) -> String:
	var number := float(value)

	if number == floor(number):
		return str(int(number))

	return str(number)


# ============================================================
# BLACK SCREEN
# ============================================================

func show_black_screen(
	message: String,
	allow_restart: bool
) -> void:
	var overlay := ColorRect.new()

	overlay.color = Color.BLACK

	overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	overlay.add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(
		420,
		180
	)
	box.add_theme_constant_override(
		"separation",
		20
	)

	center.add_child(box)

	var label := light_label(
		message,
		23,
		HORIZONTAL_ALIGNMENT_CENTER
	)

	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	box.add_child(label)

	if allow_restart:
		var restart := dark_button(
			"RESTART"
		)

		restart.pressed.connect(
			restart_game
		)

		box.add_child(restart)


# ============================================================
# RESTART
# ============================================================

func restart_game() -> void:
	case_index = 0
	strikes = 0
	calls_completed = 0

	case_20_callback_used = false

	player_notes.clear()
	pending_returns.clear()

	if FileAccess.file_exists(
		SAVE_PATH
	):
		DirAccess.remove_absolute(
			SAVE_PATH
		)

	get_tree().reload_current_scene()
