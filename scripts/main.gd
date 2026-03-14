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

var players: Array = [
	{"name": "Player 1", "color": PLAYER_COLORS[0], "score": 0},
	{"name": "Player 2", "color": PLAYER_COLORS[1], "score": 0},
	{"name": "Player 3", "color": PLAYER_COLORS[2], "score": 0},
	{"name": "Player 4", "color": PLAYER_COLORS[3], "score": 0},
]
var player_count := 4  # Default 4 for testing (exercises full player array)
var current_player := 0
var current_roll := 0

# ---------------------------------------------------------------------------
# Score labels for the score strip (created in _setup_score_strip)
# ---------------------------------------------------------------------------
var score_labels: Array = []

# ---------------------------------------------------------------------------
# @onready UI node references
# ---------------------------------------------------------------------------
@onready var grid_container: GridContainer = $HBoxContainer/BoardPanel/GridContainer
@onready var current_player_badge: PanelContainer = $HBoxContainer/Sidebar/SidebarContent/CurrentPlayerBadge
@onready var current_player_name: Label = $HBoxContainer/Sidebar/SidebarContent/CurrentPlayerBadge/CurrentPlayerName
@onready var roll_result_label: Label = $HBoxContainer/Sidebar/SidebarContent/RollResultLabel
@onready var roll_button: Button = $HBoxContainer/Sidebar/SidebarContent/RollButton
@onready var score_strip: HBoxContainer = $HBoxContainer/Sidebar/SidebarContent/ScoreStrip
@onready var game_log: RichTextLabel = $HBoxContainer/Sidebar/SidebarContent/LogScroll/GameLog
@onready var log_scroll: ScrollContainer = $HBoxContainer/Sidebar/SidebarContent/LogScroll
@onready var win_overlay: Control = $WinOverlay
@onready var win_title_label: Label = $WinOverlay/Panel/VBox/TitleLabel
@onready var win_scores_label: Label = $WinOverlay/Panel/VBox/ScoresLabel

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

	# Style the roll button with gold accent
	_style_roll_button()

	# Disable horizontal scrolling on log
	log_scroll.scroll_horizontal_enabled = false

	# Apply large font to roll result label
	roll_result_label.add_theme_font_size_override("font_size", 48)

	_init_arrays()
	_generate_board()
	_build_grid()
	_setup_score_strip()
	_update_ui()
	roll_button.pressed.connect(_on_roll_button_pressed)

# ---------------------------------------------------------------------------
# Roll button gold styling
# ---------------------------------------------------------------------------
func _style_roll_button() -> void:
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = ACCENT_GOLD
	normal_style.set_corner_radius_all(8)
	normal_style.corner_detail = 4
	roll_button.add_theme_stylebox_override("normal", normal_style)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = ACCENT_GOLD.lightened(0.15)
	hover_style.set_corner_radius_all(8)
	hover_style.corner_detail = 4
	roll_button.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = ACCENT_GOLD.darkened(0.15)
	pressed_style.set_corner_radius_all(8)
	pressed_style.corner_detail = 4
	roll_button.add_theme_stylebox_override("pressed", pressed_style)

	var disabled_style := StyleBoxFlat.new()
	disabled_style.bg_color = ACCENT_GOLD.darkened(0.5)
	disabled_style.set_corner_radius_all(8)
	disabled_style.corner_detail = 4
	roll_button.add_theme_stylebox_override("disabled", disabled_style)

	roll_button.add_theme_color_override("font_color", Color.BLACK)
	roll_button.add_theme_color_override("font_color_disabled", Color(0.3, 0.3, 0.3))

# ---------------------------------------------------------------------------
# Score strip setup — one label per player, created once at _ready()
# ---------------------------------------------------------------------------
func _setup_score_strip() -> void:
	score_labels.clear()
	for i in player_count:
		var lbl := Label.new()
		lbl.add_theme_color_override("font_color", PLAYER_COLORS[i])
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score_strip.add_child(lbl)
		score_labels.append(lbl)

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
# If a "Play Again" feature is added in Phase 3, ensure _build_grid() is not
# called again without disconnecting existing signals first to avoid double-fire.
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
	var player_idx := owner_grid[row][col]
	var base_color := PLAYER_COLORS[player_idx]
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
				_set_cell_spent(cell.y, cell.x)
			players[player_idx].score += 1
			_log_score("%s scored! Line of %d. Score: %d" % [players[player_idx].name, cells.size(), players[player_idx].score], player_idx)
			_animate_score_cells(cells)
			return true  # Max 1 point per turn — stop checking other directions
	return false

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

	# Tint the panel border with winner's color
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.15, 0.18)
	panel_style.set_border_width_all(4)
	panel_style.border_color = PLAYER_COLORS[winner_idx]
	panel_style.set_corner_radius_all(10)
	panel_style.corner_detail = 4
	$WinOverlay/Panel.add_theme_stylebox_override("panel", panel_style)

	# Build ranked scores text
	var sorted_players := []
	for i in player_count:
		sorted_players.append({"name": players[i].name, "score": players[i].score})
	sorted_players.sort_custom(func(a, b): return a.score > b.score)
	var lines := ""
	for p in sorted_players:
		lines += "%s: %d pts\n" % [p.name, p.score]
	win_scores_label.text = lines.strip_edges()

	win_overlay.visible = true

func _show_stalemate_overlay(winners: Array, best_score: int) -> void:
	win_title_label.text = "Game Over!"

	# Neutral styling (no winner color tint)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.15, 0.18)
	panel_style.set_border_width_all(4)
	panel_style.border_color = Color(0.5, 0.5, 0.5)
	panel_style.set_corner_radius_all(10)
	panel_style.corner_detail = 4
	$WinOverlay/Panel.add_theme_stylebox_override("panel", panel_style)

	# Build final scores with winner(s) shown first
	var sorted_players := []
	for i in player_count:
		sorted_players.append({"name": players[i].name, "score": players[i].score})
	sorted_players.sort_custom(func(a, b): return a.score > b.score)
	var lines := "Winner(s): %s\n\n" % ", ".join(winners)
	for p in sorted_players:
		lines += "%s: %d pts\n" % [p.name, p.score]
	win_scores_label.text = lines.strip_edges()

	win_overlay.visible = true
