extends PanelContainer

# ---------------------------------------------------------------------------
# State machine
# ---------------------------------------------------------------------------
enum GameState { WAIT_ROLL, WAIT_PICK, GAME_OVER }
var state: GameState = GameState.WAIT_ROLL

# ---------------------------------------------------------------------------
# Configuration (configurable, not hardcoded)
# ---------------------------------------------------------------------------
var rows := 10
var cols := 10
var dice_faces := 6
const WIN_SCORE := 5

# ---------------------------------------------------------------------------
# Color palette — muted player colors that pop on dark backgrounds
# ---------------------------------------------------------------------------
const PLAYER_HEX := ["#E07060", "#6080C8", "#70A870", "#D4A040"]
const PLAYER_COLORS := [
	Color(0.878, 0.439, 0.376),  # Coral       — Player 1
	Color(0.376, 0.502, 0.784),  # Slate blue  — Player 2
	Color(0.439, 0.659, 0.439),  # Sage green  — Player 3
	Color(0.831, 0.627, 0.251),  # Amber       — Player 4
]
const DARK_BG := Color(0.13, 0.13, 0.16)
const SIDEBAR_BG := Color(0.17, 0.17, 0.21)
const ACCENT_GOLD := Color(0.90, 0.75, 0.25)
const NEUTRAL_CELL := Color(0.22, 0.22, 0.27)
const SPENT_ALPHA := 0.40

# ---------------------------------------------------------------------------
# Random name pools for empty name fields
# ---------------------------------------------------------------------------
const ADJECTIVES := ["Brave", "Lucky", "Swift", "Bold", "Calm", "Fierce", "Jolly", "Keen", "Nimble", "Proud", "Witty", "Zesty"]
const NOUNS := ["Fox", "Bear", "Star", "Wolf", "Hawk", "Lion", "Owl", "Puma", "Rook", "Sage", "Wren", "Lynx"]

# ---------------------------------------------------------------------------
# Line detection directions (horizontal, vertical, two diagonals)
# ---------------------------------------------------------------------------
const DIRECTIONS := [
	Vector2i(1, 0),   # horizontal
	Vector2i(0, 1),   # vertical
	Vector2i(1, 1),   # diagonal down-right
	Vector2i(1, -1),  # diagonal down-left
]

# ---------------------------------------------------------------------------
# Data model
# ---------------------------------------------------------------------------
var board_numbers: Array = []   # [row][col] -> int 1..dice_faces
var owner_grid: Array = []      # [row][col] -> int (-1 unclaimed, 0..3 player index)
var scored_grid: Array = []     # [row][col] -> bool (spent/scored flag)
var cell_buttons: Array = []    # [row][col] -> Button node reference

var players: Array = []
var player_count := 2  # Default 2 (matches setup screen default)
var current_player := 0
var current_roll := 0

# ---------------------------------------------------------------------------
# Score labels for the score strip (created in _setup_score_strip)
# ---------------------------------------------------------------------------
var score_labels: Array = []
var score_panels: Array = []

# ---------------------------------------------------------------------------
# @onready UI node references — game UI
# ---------------------------------------------------------------------------
@onready var hbox_container: HBoxContainer = $HBoxContainer
@onready var grid_container: GridContainer = $HBoxContainer/BoardPanel/GridContainer
@onready var current_player_badge: PanelContainer = $HBoxContainer/Sidebar/SidebarContent/CurrentPlayerBadge
@onready var current_player_name: Label = $HBoxContainer/Sidebar/SidebarContent/CurrentPlayerBadge/CurrentPlayerName
@onready var roll_result_label: Label = $HBoxContainer/Sidebar/SidebarContent/RollResultLabel
@onready var roll_button: Button = $HBoxContainer/Sidebar/SidebarContent/RollButton
@onready var score_strip: HBoxContainer = $HBoxContainer/BoardPanel/ScoreStrip
@onready var game_log: RichTextLabel = $HBoxContainer/Sidebar/SidebarContent/LogScroll/GameLog
@onready var log_scroll: ScrollContainer = $HBoxContainer/Sidebar/SidebarContent/LogScroll
@onready var win_overlay: Control = $WinOverlay
@onready var win_title_label: Label = $WinOverlay/Panel/VBox/TitleLabel
@onready var win_scores_container: VBoxContainer = $WinOverlay/Panel/VBox/ScoresContainer
@onready var new_game_button: Button = $WinOverlay/Panel/VBox/NewGameButton

# ---------------------------------------------------------------------------
# @onready UI node references — setup screen
# ---------------------------------------------------------------------------
@onready var setup_overlay: Control = $SetupOverlay
@onready var count_btn_2: Button = $SetupOverlay/SetupCard/VBox/CountRow/CountBtn2
@onready var count_btn_3: Button = $SetupOverlay/SetupCard/VBox/CountRow/CountBtn3
@onready var count_btn_4: Button = $SetupOverlay/SetupCard/VBox/CountRow/CountBtn4
@onready var player_row_0: HBoxContainer = $SetupOverlay/SetupCard/VBox/NamesContainer/PlayerRow0
@onready var player_row_1: HBoxContainer = $SetupOverlay/SetupCard/VBox/NamesContainer/PlayerRow1
@onready var player_row_2: HBoxContainer = $SetupOverlay/SetupCard/VBox/NamesContainer/PlayerRow2
@onready var player_row_3: HBoxContainer = $SetupOverlay/SetupCard/VBox/NamesContainer/PlayerRow3
@onready var name_input_0: LineEdit = $SetupOverlay/SetupCard/VBox/NamesContainer/PlayerRow0/NameInput0
@onready var name_input_1: LineEdit = $SetupOverlay/SetupCard/VBox/NamesContainer/PlayerRow1/NameInput1
@onready var name_input_2: LineEdit = $SetupOverlay/SetupCard/VBox/NamesContainer/PlayerRow2/NameInput2
@onready var name_input_3: LineEdit = $SetupOverlay/SetupCard/VBox/NamesContainer/PlayerRow3/NameInput3
@onready var start_button: Button = $SetupOverlay/SetupCard/VBox/StartButton

# Collected arrays for easy iteration
var name_inputs: Array = []
var player_rows: Array = []

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	# Apply dark background to root PanelContainer
	var root_style := StyleBoxFlat.new()
	root_style.bg_color = DARK_BG
	add_theme_stylebox_override("panel", root_style)

	# GridContainer gaps (2-3px between cells)
	grid_container.add_theme_constant_override("h_separation", 3)
	grid_container.add_theme_constant_override("v_separation", 3)

	# Style the sidebar background
	var sidebar_style := StyleBoxFlat.new()
	sidebar_style.bg_color = SIDEBAR_BG
	sidebar_style.set_corner_radius_all(8)
	sidebar_style.corner_detail = 4
	$HBoxContainer/Sidebar.add_theme_stylebox_override("panel", sidebar_style)

	# Style buttons with gold accent
	_style_button_gold(roll_button)

	# Apply large font to roll result label
	roll_result_label.add_theme_font_size_override("font_size", 48)

	# Build the board grid (once at _ready — never again)
	_init_arrays()
	_generate_board()
	_build_grid()

	# Wire persistent signals
	roll_button.pressed.connect(_on_roll_button_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	_style_button_gold(new_game_button)

	# Hide game UI at startup — setup screen will be shown instead
	hbox_container.visible = false

	# Populate iteration arrays after @onready vars are resolved
	name_inputs = [name_input_0, name_input_1, name_input_2, name_input_3]
	player_rows = [player_row_0, player_row_1, player_row_2, player_row_3]

	# Show setup screen (it starts visible=true in the scene)
	_init_setup_screen()

# ---------------------------------------------------------------------------
# Setup screen initialization — called once at _ready()
# ---------------------------------------------------------------------------
func _init_setup_screen() -> void:
	# Style the setup card background
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = SIDEBAR_BG
	card_style.set_corner_radius_all(10)
	card_style.corner_detail = 4
	card_style.set_content_margin_all(24)
	$SetupOverlay/SetupCard.add_theme_stylebox_override("panel", card_style)

	# Create ButtonGroup for exclusive count selection
	var bg := ButtonGroup.new()
	for btn in [count_btn_2, count_btn_3, count_btn_4]:
		btn.toggle_mode = true
		btn.button_group = bg
	bg.pressed.connect(_on_count_selected)

	# Default to 2 players
	count_btn_2.button_pressed = true
	_style_button_gold(count_btn_2)
	_style_button_neutral(count_btn_3)
	_style_button_neutral(count_btn_4)

	# Style each name input with player-colored border
	for i in 4:
		var field: LineEdit = name_inputs[i]
		var field_style := StyleBoxFlat.new()
		field_style.bg_color = Color(0.20, 0.20, 0.25)
		field_style.set_border_width_all(2)
		field_style.border_color = PLAYER_COLORS[i]
		field_style.set_corner_radius_all(6)
		field_style.corner_detail = 4
		field_style.set_content_margin_all(6)
		field.add_theme_stylebox_override("normal", field_style)
		field.add_theme_stylebox_override("focus", field_style)
		field.add_theme_color_override("font_color", Color.WHITE)
		field.add_theme_color_override("font_placeholder_color", Color(0.6, 0.6, 0.6))

	# Wire Enter key chaining between fields
	name_inputs[0].text_submitted.connect(func(_t: String): name_inputs[1].grab_focus())
	name_inputs[1].text_submitted.connect(func(_t: String): _on_enter_from_field(1))
	name_inputs[2].text_submitted.connect(func(_t: String): _on_enter_from_field(2))
	name_inputs[3].text_submitted.connect(func(_t: String): _on_start_game_pressed())

	# Style Start Game button
	_style_button_gold(start_button)
	start_button.pressed.connect(_on_start_game_pressed)

	# Ensure initial visibility matches 2-player default (rows 2/3 hidden)
	player_rows[2].visible = false
	player_rows[3].visible = false

# ---------------------------------------------------------------------------
# Count button selection handler
# ---------------------------------------------------------------------------
func _on_count_selected(btn: BaseButton) -> void:
	var count: int = int(btn.text)
	# Update button styles: pressed=gold, others=neutral
	for b in [count_btn_2, count_btn_3, count_btn_4]:
		if b.button_pressed:
			_style_button_gold(b)
		else:
			_style_button_neutral(b)
	_update_name_field_visibility(count)

# ---------------------------------------------------------------------------
# Enter key handler for chained focus in name fields
# ---------------------------------------------------------------------------
func _on_enter_from_field(idx: int) -> void:
	var selected: int = _get_selected_count()
	if idx + 1 < selected:
		name_inputs[idx + 1].grab_focus()
	else:
		_on_start_game_pressed()

# ---------------------------------------------------------------------------
# Neutral button style (unselected count buttons + general dark buttons)
# ---------------------------------------------------------------------------
func _style_button_neutral(btn: Button) -> void:
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = NEUTRAL_CELL
	normal_style.set_corner_radius_all(8)
	normal_style.corner_detail = 4
	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = NEUTRAL_CELL.lightened(0.15)
	hover_style.set_corner_radius_all(8)
	hover_style.corner_detail = 4
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = NEUTRAL_CELL.darkened(0.15)
	pressed_style.set_corner_radius_all(8)
	pressed_style.corner_detail = 4
	btn.add_theme_stylebox_override("pressed", pressed_style)

	var disabled_style := StyleBoxFlat.new()
	disabled_style.bg_color = NEUTRAL_CELL.darkened(0.3)
	disabled_style.set_corner_radius_all(8)
	disabled_style.corner_detail = 4
	btn.add_theme_stylebox_override("disabled", disabled_style)

	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_color_disabled", Color(0.5, 0.5, 0.5))

# ---------------------------------------------------------------------------
# Show/hide name field rows with slide animation when count changes
# ---------------------------------------------------------------------------
func _update_name_field_visibility(count: int) -> void:
	if count >= 3:
		_show_player_row(player_rows[2])
	else:
		_hide_player_row(player_rows[2])
	if count >= 4:
		_show_player_row(player_rows[3])
	else:
		_hide_player_row(player_rows[3])

func _show_player_row(row: Control) -> void:
	row.visible = true
	row.custom_minimum_size = Vector2(0, 0)
	row.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(row, "custom_minimum_size", Vector2(0, 40), 0.15)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(row, "modulate:a", 1.0, 0.15)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _hide_player_row(row: Control) -> void:
	if not row.visible:
		return
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(row, "custom_minimum_size", Vector2(0, 0), 0.12)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_property(row, "modulate:a", 0.0, 0.12)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished
	row.visible = false

# ---------------------------------------------------------------------------
# Get currently selected player count from ButtonGroup state
# ---------------------------------------------------------------------------
func _get_selected_count() -> int:
	if count_btn_2.button_pressed:
		return 2
	if count_btn_3.button_pressed:
		return 3
	return 4

# ---------------------------------------------------------------------------
# Random fun name for empty name fields
# ---------------------------------------------------------------------------
func _random_fun_name() -> String:
	return ADJECTIVES[randi() % ADJECTIVES.size()] + " " + NOUNS[randi() % NOUNS.size()]

# ---------------------------------------------------------------------------
# Start Game button handler — reads setup, initializes game, fades to gameplay
# ---------------------------------------------------------------------------
func _on_start_game_pressed() -> void:
	player_count = _get_selected_count()
	# Build dynamic players array from setup state
	players = []
	for i in player_count:
		var name_text: String = name_inputs[i].text.strip_edges()
		if name_text.is_empty():
			name_text = _random_fun_name()
		players.append({"name": name_text, "color": PLAYER_COLORS[i], "score": 0})
	# Rebuild score strip for the selected player count
	for child in score_strip.get_children():
		child.queue_free()
	score_labels.clear()
	score_panels.clear()
	_setup_score_strip()
	# Reset game state
	current_player = 0
	current_roll = 0
	state = GameState.WAIT_ROLL
	# Reset data grids
	for r in rows:
		for c in cols:
			owner_grid[r][c] = -1
			scored_grid[r][c] = false
	# Generate fresh board and update buttons in place (never _build_grid() again)
	_generate_board()
	for r in rows:
		for c in cols:
			var btn: Button = cell_buttons[r][c]
			btn.text = str(board_numbers[r][c])
			btn.disabled = false
			btn.scale = Vector2.ONE
			_set_cell_color(btn, NEUTRAL_CELL)
	game_log.clear()
	# Fade to game UI, then update UI after transition completes
	await _fade_to_game()
	_update_ui()

# ---------------------------------------------------------------------------
# Fade transitions between setup and game
# ---------------------------------------------------------------------------
func _fade_to_game() -> void:
	var tw := create_tween()
	tw.tween_property(setup_overlay, "modulate:a", 0.0, 0.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished
	setup_overlay.visible = false
	hbox_container.visible = true

func _fade_to_setup() -> void:
	win_overlay.visible = false
	setup_overlay.modulate.a = 0.0
	setup_overlay.visible = true
	hbox_container.visible = false
	var tw := create_tween()
	tw.tween_property(setup_overlay, "modulate:a", 1.0, 0.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# ---------------------------------------------------------------------------
# Roll button gold styling
# ---------------------------------------------------------------------------
func _style_button_gold(btn: Button) -> void:
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = ACCENT_GOLD
	normal_style.set_corner_radius_all(8)
	normal_style.corner_detail = 4
	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = ACCENT_GOLD.lightened(0.15)
	hover_style.set_corner_radius_all(8)
	hover_style.corner_detail = 4
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = ACCENT_GOLD.darkened(0.15)
	pressed_style.set_corner_radius_all(8)
	pressed_style.corner_detail = 4
	btn.add_theme_stylebox_override("pressed", pressed_style)

	var disabled_style := StyleBoxFlat.new()
	disabled_style.bg_color = ACCENT_GOLD.darkened(0.5)
	disabled_style.set_corner_radius_all(8)
	disabled_style.corner_detail = 4
	btn.add_theme_stylebox_override("disabled", disabled_style)

	btn.add_theme_color_override("font_color", Color.BLACK)
	btn.add_theme_color_override("font_color_disabled", Color(0.3, 0.3, 0.3))

# ---------------------------------------------------------------------------
# Score strip setup — one label per player, created once at _ready()
# ---------------------------------------------------------------------------
func _setup_score_strip() -> void:
	score_labels.clear()
	score_panels.clear()
	for i in player_count:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = Color.TRANSPARENT
		panel_style.set_border_width_all(2)
		panel_style.border_color = PLAYER_COLORS[i]
		panel_style.set_corner_radius_all(8)
		panel_style.corner_detail = 4
		panel_style.set_content_margin_all(6)
		panel.add_theme_stylebox_override("panel", panel_style)
		var lbl := Label.new()
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(lbl)
		score_strip.add_child(panel)
		score_labels.append(lbl)
		score_panels.append(panel)

# ---------------------------------------------------------------------------
# Array initialization
# ---------------------------------------------------------------------------
func _init_arrays() -> void:
	board_numbers = []
	owner_grid = []
	scored_grid = []
	cell_buttons = []
	for r in rows:
		board_numbers.append([])
		owner_grid.append([])
		scored_grid.append([])
		cell_buttons.append([])
		for c in cols:
			board_numbers[r].append(0)
			owner_grid[r].append(-1)
			scored_grid[r].append(false)
			cell_buttons[r].append(null)

# ---------------------------------------------------------------------------
# Board generation — shuffle bag algorithm (Pattern 5)
# Gives count-balanced distribution with natural variance
# ---------------------------------------------------------------------------
func _generate_board() -> void:
	var total_cells := rows * cols
	var pool: Array = []
	var base_count := total_cells / dice_faces
	var remainder := total_cells % dice_faces
	for face in range(1, dice_faces + 1):
		var count := base_count + (1 if face <= remainder else 0)
		for _i in count:
			pool.append(face)
	pool.shuffle()
	var idx := 0
	for r in rows:
		for c in cols:
			board_numbers[r][c] = pool[idx]
			idx += 1

# ---------------------------------------------------------------------------
# Grid construction — create 100 Button nodes programmatically (Pattern 2)
# Buttons are created once at _ready(); never rebuilt during gameplay
# ---------------------------------------------------------------------------
func _build_grid() -> void:
	for r in rows:
		for c in cols:
			var btn := Button.new()
			btn.text = str(board_numbers[r][c])
			btn.custom_minimum_size = Vector2(50, 50)
			btn.pressed.connect(_on_cell_pressed.bind(r, c))
			# Apply neutral dark style with rounded corners
			_set_cell_color(btn, NEUTRAL_CELL)
			# White text is readable on dark/colored backgrounds
			btn.add_theme_color_override("font_color", Color.WHITE)
			btn.add_theme_color_override("font_color_disabled", Color.WHITE)
			grid_container.add_child(btn)
			cell_buttons[r][c] = btn

# ---------------------------------------------------------------------------
# Roll button handler
# ---------------------------------------------------------------------------
func _on_roll_button_pressed() -> void:
	if state != GameState.WAIT_ROLL:
		return
	current_roll = randi_range(1, dice_faces)
	state = GameState.WAIT_PICK
	_highlight_valid_cells()
	_log("%s rolled a %d" % [players[current_player].name, current_roll], current_player)
	_update_ui()

# ---------------------------------------------------------------------------
# Cell press handler
# ---------------------------------------------------------------------------
func _on_cell_pressed(row: int, col: int) -> void:
	if state != GameState.WAIT_PICK:
		return
	if owner_grid[row][col] != -1:
		return  # Already claimed
	if board_numbers[row][col] != current_roll:
		return  # Does not match current roll
	_claim_cell(row, col)

# ---------------------------------------------------------------------------
# Highlight valid cells with gold border; dim non-matching unclaimed cells
# ---------------------------------------------------------------------------
func _highlight_valid_cells() -> void:
	var valid_count := 0
	for r in rows:
		for c in cols:
			var btn: Button = cell_buttons[r][c]
			if owner_grid[r][c] != -1:
				# Already claimed — leave as-is (player color, disabled)
				continue
			if board_numbers[r][c] == current_roll:
				# Valid move: gold border on neutral background
				_set_cell_color(btn, NEUTRAL_CELL, ACCENT_GOLD, 3)
				btn.disabled = false
				valid_count += 1
			else:
				# Unclaimed but not a valid move — reset to neutral, disable
				_set_cell_color(btn, NEUTRAL_CELL)
				btn.disabled = true
	if valid_count == 0:
		_check_and_handle_no_moves()

func _clear_highlights() -> void:
	for r in rows:
		for c in cols:
			if owner_grid[r][c] != -1:
				# Claimed — leave player color intact (or spent appearance if scored)
				continue
			var btn: Button = cell_buttons[r][c]
			_set_cell_color(btn, NEUTRAL_CELL)
			btn.disabled = false  # Re-enable unclaimed cells for next turn

# ---------------------------------------------------------------------------
# Cell claiming
# NOTE: Signal connections in _build_grid() are made once at _ready().
# _build_grid() must never be called again — double-fires signals on 100 buttons.
# ---------------------------------------------------------------------------
func _claim_cell(row: int, col: int) -> void:
	owner_grid[row][col] = current_player
	cell_buttons[row][col].disabled = true
	_set_cell_color(cell_buttons[row][col], PLAYER_COLORS[current_player])
	_log("%s claimed cell (%d, %d)" % [players[current_player].name, row, col], current_player)
	_clear_highlights()
	_check_score(row, col, current_player)
	if _check_win_or_stalemate():
		return
	_advance_turn()

# ---------------------------------------------------------------------------
# UI update — badge, large roll, score strip, roll button state
# ---------------------------------------------------------------------------
func _update_ui() -> void:
	_update_player_badge()
	_update_score_strip()

	if current_roll == 0:
		roll_result_label.text = "-"
	else:
		roll_result_label.text = str(current_roll)

	# Roll button is only active during WAIT_ROLL
	roll_button.disabled = (state != GameState.WAIT_ROLL)

# ---------------------------------------------------------------------------
# Current player badge — colored chip with player name
# ---------------------------------------------------------------------------
func _update_player_badge() -> void:
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = PLAYER_COLORS[current_player]
	badge_style.set_corner_radius_all(8)
	badge_style.corner_detail = 4
	current_player_badge.add_theme_stylebox_override("panel", badge_style)
	current_player_name.text = players[current_player].name
	current_player_name.add_theme_color_override("font_color", Color.WHITE)

# ---------------------------------------------------------------------------
# Score strip — update all player score labels
# ---------------------------------------------------------------------------
func _update_score_strip() -> void:
	for i in score_labels.size():
		score_labels[i].text = "%s: %d" % [players[i].name, players[i].score]

# ---------------------------------------------------------------------------
# Game log — color-coded by player, with optional score emphasis
# ---------------------------------------------------------------------------
func _log(message: String, player_idx: int = -1) -> void:
	if player_idx >= 0 and player_idx < player_count:
		game_log.append_text("[color=%s]%s[/color]\n" % [PLAYER_HEX[player_idx], message])
	else:
		game_log.append_text(message + "\n")

func _log_score(message: String, player_idx: int) -> void:
	game_log.append_text("[color=%s][font_size=16]%s[/font_size][/color]\n" % [PLAYER_HEX[player_idx], message])

# ---------------------------------------------------------------------------
# Button color utility — creates StyleBoxFlat with rounded corners
# Supports optional border (used for valid-move gold outline)
# Must override all 4 states so disabled buttons keep their player color
# ---------------------------------------------------------------------------
func _set_cell_color(btn: Button, bg: Color, border_color: Color = Color.TRANSPARENT, border_px: int = 0) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(6)
	style.corner_detail = 4
	style.anti_aliasing = true
	if border_px > 0:
		style.set_border_width_all(border_px)
		style.border_color = border_color
		style.draw_center = true  # Keep bg color; border is additive
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("disabled", style)

# ---------------------------------------------------------------------------
# Spent cell visual — dimmed version of player color (scored lines)
# ---------------------------------------------------------------------------
func _set_cell_spent(row: int, col: int) -> void:
	var player_idx: int = owner_grid[row][col]
	var base_color: Color = PLAYER_COLORS[player_idx]
	var spent_color := Color(base_color.r, base_color.g, base_color.b, SPENT_ALPHA)
	_set_cell_color(cell_buttons[row][col], spent_color)

# ---------------------------------------------------------------------------
# Bounds check helper
# ---------------------------------------------------------------------------
func _in_bounds(r: int, c: int) -> bool:
	return r >= 0 and r < rows and c >= 0 and c < cols

# ---------------------------------------------------------------------------
# Turn advance
# ---------------------------------------------------------------------------
func _advance_turn() -> void:
	current_player = (current_player + 1) % player_count
	current_roll = 0
	state = GameState.WAIT_ROLL
	_update_ui()

# ---------------------------------------------------------------------------
# Line detection (Pattern 4)
# ---------------------------------------------------------------------------
func _collect_line(row: int, col: int, dir: Vector2i, player_idx: int) -> Array:
	var cells := [Vector2i(col, row)]
	# Walk forward
	var r := row + dir.y
	var c := col + dir.x
	while _in_bounds(r, c) and owner_grid[r][c] == player_idx and not scored_grid[r][c]:
		cells.append(Vector2i(c, r))
		r += dir.y
		c += dir.x
	# Walk backward
	r = row - dir.y
	c = col - dir.x
	while _in_bounds(r, c) and owner_grid[r][c] == player_idx and not scored_grid[r][c]:
		cells.append(Vector2i(c, r))
		r -= dir.y
		c -= dir.x
	return cells

func _check_score(row: int, col: int, player_idx: int) -> bool:
	for dir in DIRECTIONS:
		var cells := _collect_line(row, col, dir, player_idx)
		if cells.size() >= 3:
			for cell in cells:
				scored_grid[cell.y][cell.x] = true
			players[player_idx].score += 1
			_log_score("%s scored! Line of %d. Score: %d" % [players[player_idx].name, cells.size(), players[player_idx].score], player_idx)
			_apply_spent_appearance(cells)  # Dim cells immediately (before animation)
			_animate_score_cells(cells)     # Tween plays over already-dimmed buttons
			_flash_score_panel(player_idx)  # Flash the player's name bar
			return true  # Max 1 point per turn — stop checking other directions
	return false

# ---------------------------------------------------------------------------
# Apply dimmed spent appearance to an array of scored cells (SCOR-03)
# Called immediately after scoring, before animation
# ---------------------------------------------------------------------------
func _apply_spent_appearance(cells: Array) -> void:
	for cell_vec in cells:  # cell_vec is Vector2i(col, row) per _collect_line convention
		var player_idx: int = owner_grid[cell_vec.y][cell_vec.x]
		var base_color: Color = PLAYER_COLORS[player_idx]
		var spent_color := Color(base_color.r, base_color.g, base_color.b, SPENT_ALPHA)
		_set_cell_color(cell_buttons[cell_vec.y][cell_vec.x], spent_color)

# ---------------------------------------------------------------------------
# Scale pop animation for scoring cells (SCOR-03)
# Fire-and-forget — score already updated before this call
# ---------------------------------------------------------------------------
func _animate_score_cells(cells: Array) -> void:
	for cell_vec in cells:  # cell_vec is Vector2i(col, row) per _collect_line convention
		var btn: Button = cell_buttons[cell_vec.y][cell_vec.x]
		# Reset scale first to avoid stale tween artifacts
		btn.scale = Vector2.ONE
		# Center the scale pivot — must be set at animation time (not _ready())
		btn.pivot_offset = btn.size / 2.0
		var tw := create_tween()
		# Pop to 1.2x
		tw.tween_property(btn, "scale", Vector2(1.2, 1.2), 0.15)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		# Return to 1.0x
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# No await — score already updated before this call

# ---------------------------------------------------------------------------
# Flash the score panel when a player scores — fills with player color then fades
# ---------------------------------------------------------------------------
func _flash_score_panel(player_idx: int) -> void:
	if player_idx < 0 or player_idx >= score_panels.size():
		return
	var panel: PanelContainer = score_panels[player_idx]
	var color: Color = PLAYER_COLORS[player_idx]
	# Create a filled style for the flash
	var flash_style := StyleBoxFlat.new()
	flash_style.bg_color = color
	flash_style.set_border_width_all(2)
	flash_style.border_color = color
	flash_style.set_corner_radius_all(8)
	flash_style.corner_detail = 4
	flash_style.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", flash_style)
	# Tween back to transparent background
	var tw := create_tween()
	tw.tween_method(func(t: float) -> void:
		var s := StyleBoxFlat.new()
		s.bg_color = Color(color.r, color.g, color.b, (1.0 - t) * 0.6)
		s.set_border_width_all(2)
		s.border_color = color
		s.set_corner_radius_all(8)
		s.corner_detail = 4
		s.set_content_margin_all(6)
		panel.add_theme_stylebox_override("panel", s)
	, 0.0, 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# ---------------------------------------------------------------------------
# New Game — route back to setup screen (WIN-03)
# Setup screen preserves previous names and count (LineEdit.text values persist)
# ---------------------------------------------------------------------------
func _on_new_game_pressed() -> void:
	_fade_to_setup()

# ---------------------------------------------------------------------------
# Disable all cells (used on game over)
# ---------------------------------------------------------------------------
func _disable_all_cells() -> void:
	for r in rows:
		for c in cols:
			if cell_buttons[r][c] != null:
				cell_buttons[r][c].disabled = true

# ---------------------------------------------------------------------------
# Auto-reroll helpers
# ---------------------------------------------------------------------------
func _has_unclaimed_cells() -> bool:
	for r in rows:
		for c in cols:
			if owner_grid[r][c] == -1:
				return true
	return false

func _check_and_handle_no_moves() -> void:
	if not _has_unclaimed_cells():
		# Board is completely full — trigger stalemate (avoids infinite reroll)
		state = GameState.GAME_OVER
		_resolve_stalemate()
		return
	# Unclaimed cells exist but none match the roll — auto-reroll
	var max_rerolls := 100
	var reroll_count := 0
	while reroll_count < max_rerolls:
		_log("No valid moves for %d — auto-rerolling..." % current_roll)
		current_roll = randi_range(1, dice_faces)
		_log("%s rolled a %d" % [players[current_player].name, current_roll], current_player)
		_update_ui()
		reroll_count += 1
		# Check if any unclaimed cell matches the new roll
		var valid_found := false
		for r in rows:
			for c in cols:
				if owner_grid[r][c] == -1 and board_numbers[r][c] == current_roll:
					valid_found = true
					break
			if valid_found:
				break
		if valid_found:
			# Re-highlight with the new roll; returns here (no more recursion)
			_highlight_valid_cells()
			return
	# Safety fallback: should never reach here on a d6 with unclaimed cells
	_log("Auto-reroll limit exceeded — ending game to prevent hang")
	state = GameState.GAME_OVER
	_resolve_stalemate()

# ---------------------------------------------------------------------------
# Win / stalemate check
# ---------------------------------------------------------------------------
func _check_win_or_stalemate() -> bool:
	# Win check
	if players[current_player].score >= WIN_SCORE:
		state = GameState.GAME_OVER
		_log("Game over! %s wins with %d points!" % [players[current_player].name, players[current_player].score], current_player)
		_disable_all_cells()
		_show_win_overlay(current_player)
		_update_ui()
		return true
	# Stalemate check — any unclaimed cell?
	for r in rows:
		for c in cols:
			if owner_grid[r][c] == -1:
				return false  # At least one unclaimed cell exists
	# All cells claimed, no winner
	state = GameState.GAME_OVER
	_resolve_stalemate()
	return true

func _resolve_stalemate() -> void:
	var best_score := -1
	var winners: Array = []
	for i in player_count:
		if players[i].score > best_score:
			best_score = players[i].score
			winners = [players[i].name]
		elif players[i].score == best_score:
			winners.append(players[i].name)
	_log("Stalemate! Winner(s): %s with %d point(s)" % [", ".join(winners), best_score])
	_disable_all_cells()
	_show_stalemate_overlay(winners, best_score)
	_update_ui()

# ---------------------------------------------------------------------------
# Win / stalemate overlay display (WIN-02)
# ---------------------------------------------------------------------------
func _show_win_overlay(winner_idx: int) -> void:
	win_title_label.text = "%s Wins!" % players[winner_idx].name
	win_title_label.add_theme_color_override("font_color", PLAYER_COLORS[winner_idx])

	# Tint the panel border with winner's color
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.15, 0.18)
	panel_style.set_border_width_all(4)
	panel_style.border_color = PLAYER_COLORS[winner_idx]
	panel_style.set_corner_radius_all(10)
	panel_style.corner_detail = 4
	$WinOverlay/Panel.add_theme_stylebox_override("panel", panel_style)

	# Clear any existing score labels and build dynamically (one per player)
	for child in win_scores_container.get_children():
		child.queue_free()
	var sorted_players := []
	for i in player_count:
		sorted_players.append({"name": players[i].name, "score": players[i].score, "color": PLAYER_COLORS[i]})
	sorted_players.sort_custom(func(a, b): return a.score > b.score)
	for p in sorted_players:
		var lbl := Label.new()
		lbl.text = "%s: %d pts" % [p.name, p.score]
		lbl.add_theme_color_override("font_color", p.color)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		win_scores_container.add_child(lbl)

	win_overlay.visible = true

func _show_stalemate_overlay(winners: Array, best_score: int) -> void:
	win_title_label.text = "Game Over!"

	# Border color: winner's color if single winner, neutral white if tied
	var border_color := Color(1.0, 1.0, 1.0)
	if winners.size() == 1:
		for i in player_count:
			if players[i].name == winners[0]:
				border_color = PLAYER_COLORS[i]
				break

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.15, 0.18)
	panel_style.set_border_width_all(4)
	panel_style.border_color = border_color
	panel_style.set_corner_radius_all(10)
	panel_style.corner_detail = 4
	$WinOverlay/Panel.add_theme_stylebox_override("panel", panel_style)

	# Clear and rebuild score labels ranked by score
	for child in win_scores_container.get_children():
		child.queue_free()
	var sorted_players := []
	for i in player_count:
		sorted_players.append({"name": players[i].name, "score": players[i].score, "color": PLAYER_COLORS[i]})
	sorted_players.sort_custom(func(a, b): return a.score > b.score)
	for p in sorted_players:
		var lbl := Label.new()
		lbl.text = "%s: %d pts" % [p.name, p.score]
		lbl.add_theme_color_override("font_color", p.color)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		win_scores_container.add_child(lbl)

	win_overlay.visible = true
