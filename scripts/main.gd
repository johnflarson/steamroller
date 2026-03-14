extends Control

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
# Data model
# ---------------------------------------------------------------------------
var board_numbers: Array = []   # [row][col] -> int 1..dice_faces
var owner_grid: Array = []      # [row][col] -> int (-1 unclaimed, 0..3 player index)
var scored_grid: Array = []     # [row][col] -> bool (spent/scored flag)
var cell_buttons: Array = []    # [row][col] -> Button node reference

var players: Array = [
	{"name": "Player 1", "color": Color.RED,    "score": 0},
	{"name": "Player 2", "color": Color.BLUE,   "score": 0},
	{"name": "Player 3", "color": Color.GREEN,  "score": 0},
	{"name": "Player 4", "color": Color.YELLOW, "score": 0},
]
var player_count := 4  # Default 4 for testing (exercises full player array)
var current_player := 0
var current_roll := 0

# ---------------------------------------------------------------------------
# @onready UI node references
# ---------------------------------------------------------------------------
@onready var grid_container: GridContainer = $HBoxContainer/BoardPanel/GridContainer
@onready var current_player_label: Label = $HBoxContainer/Sidebar/CurrentPlayerLabel
@onready var roll_result_label: Label = $HBoxContainer/Sidebar/RollResultLabel
@onready var roll_button: Button = $HBoxContainer/Sidebar/RollButton
@onready var scores_label: Label = $HBoxContainer/Sidebar/ScoresLabel
@onready var game_log: RichTextLabel = $HBoxContainer/Sidebar/LogScroll/GameLog

# ---------------------------------------------------------------------------
# Highlight color for valid cells
# ---------------------------------------------------------------------------
const HIGHLIGHT_COLOR := Color(1, 1, 0.5, 1)  # Light yellow

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
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	_init_arrays()
	_generate_board()
	_build_grid()
	_update_ui()
	roll_button.pressed.connect(_on_roll_button_pressed)

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
	_log("Player %s rolled a %d" % [players[current_player].name, current_roll])
	_update_ui()

# ---------------------------------------------------------------------------
# Cell press handler (stub — full claiming logic implemented in Plan 02)
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
# Highlight / clear stubs (Plan 02 implements visual highlighting)
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
				# Valid move: highlight and ensure enabled
				_set_cell_color(btn, HIGHLIGHT_COLOR)
				btn.disabled = false
				valid_count += 1
			else:
				# Unclaimed but not a valid move — reset to neutral appearance
				btn.remove_theme_stylebox_override("normal")
				btn.remove_theme_stylebox_override("hover")
				btn.remove_theme_stylebox_override("pressed")
				btn.remove_theme_stylebox_override("disabled")
				btn.disabled = true  # Not selectable this turn
	if valid_count == 0:
		_check_and_handle_no_moves()

func _clear_highlights() -> void:
	for r in rows:
		for c in cols:
			if owner_grid[r][c] != -1:
				# Claimed — leave player color intact
				continue
			var btn: Button = cell_buttons[r][c]
			btn.remove_theme_stylebox_override("normal")
			btn.remove_theme_stylebox_override("hover")
			btn.remove_theme_stylebox_override("pressed")
			btn.remove_theme_stylebox_override("disabled")
			btn.disabled = false  # Re-enable unclaimed cells for next turn

# ---------------------------------------------------------------------------
# Cell claiming
# NOTE: Signal connections in _build_grid() are made once at _ready().
# If a "Play Again" feature is added in Phase 3, ensure _build_grid() is not
# called again without disconnecting existing signals first to avoid double-fire.
# ---------------------------------------------------------------------------
func _claim_cell(row: int, col: int) -> void:
	owner_grid[row][col] = current_player
	cell_buttons[row][col].disabled = true
	_set_cell_color(cell_buttons[row][col], players[current_player].color)
	_log("%s claimed cell (%d, %d)" % [players[current_player].name, row, col])
	_clear_highlights()
	# Plan 03: _check_score(row, col, current_player)
	# Plan 03: _check_win_or_stalemate()
	_advance_turn()

# ---------------------------------------------------------------------------
# UI update
# ---------------------------------------------------------------------------
func _update_ui() -> void:
	current_player_label.text = "Current Player: %s" % players[current_player].name

	if current_roll == 0:
		roll_result_label.text = "Roll: -"
	else:
		roll_result_label.text = "Roll: %d" % current_roll

	# Roll button is only active during WAIT_ROLL
	roll_button.disabled = (state != GameState.WAIT_ROLL)

	# Scores — one line per player
	var score_lines := ""
	for i in player_count:
		score_lines += "%s: %d\n" % [players[i].name, players[i].score]
	scores_label.text = score_lines.strip_edges()

# ---------------------------------------------------------------------------
# Game log
# ---------------------------------------------------------------------------
func _log(message: String) -> void:
	game_log.append_text(message + "\n")

# ---------------------------------------------------------------------------
# Button color utility (Pattern 3) — creates new StyleBoxFlat per call
# Must override all 4 states so disabled buttons keep their player color
# ---------------------------------------------------------------------------
func _set_cell_color(btn: Button, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("disabled", style)

# ---------------------------------------------------------------------------
# Bounds check helper
# ---------------------------------------------------------------------------
func _in_bounds(r: int, c: int) -> bool:
	return r >= 0 and r < rows and c >= 0 and c < cols

# ---------------------------------------------------------------------------
# Turn advance (Plan 02 will call this after claiming a cell)
# ---------------------------------------------------------------------------
func _advance_turn() -> void:
	current_player = (current_player + 1) % player_count
	current_roll = 0
	state = GameState.WAIT_ROLL
	_update_ui()

# ---------------------------------------------------------------------------
# Line detection (Pattern 4) — used by scoring in Plan 02
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
			return true  # Max 1 point per turn
	return false

# ---------------------------------------------------------------------------
# Disable all cells (used on game over)
# ---------------------------------------------------------------------------
func _disable_all_cells() -> void:
	for r in rows:
		for c in cols:
			if cell_buttons[r][c] != null:
				cell_buttons[r][c].disabled = true

# ---------------------------------------------------------------------------
# Win / stalemate check (Plan 02 calls this after each claim)
# ---------------------------------------------------------------------------
func _check_win_or_stalemate() -> bool:
	# Win check
	if players[current_player].score >= WIN_SCORE:
		state = GameState.GAME_OVER
		_log("Game over! %s wins!" % players[current_player].name)
		_disable_all_cells()
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
	_update_ui()
