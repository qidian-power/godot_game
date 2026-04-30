extends Control
class_name DigCell

signal cell_clicked(cell_id: int)

var cell_id: int = -1
var max_hp: int = 1
var current_hp: int = 1
var mined: bool = false
var mineral_name: String = ""
var is_locked: bool = false
var is_hovered: bool = false

func setup(new_cell_id: int, hp: int, mineral_label: String) -> void:
	cell_id = new_cell_id
	max_hp = max(1, hp)
	current_hp = max_hp
	mined = false
	mineral_name = mineral_label
	is_locked = false
	queue_redraw()

func apply_damage(amount: int) -> bool:
	if mined:
		return false
	current_hp = max(0, current_hp - max(0, amount))
	if current_hp == 0:
		mined = true
	queue_redraw()
	return mined

func set_locked() -> void:
	is_locked = true
	queue_redraw()

func set_unlocked() -> void:
	is_locked = false
	queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(64, 56)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _gui_input(event: InputEvent) -> void:
	if is_locked:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		cell_clicked.emit(cell_id)

func _on_mouse_entered() -> void:
	is_hovered = true
	queue_redraw()

func _on_mouse_exited() -> void:
	is_hovered = false
	queue_redraw()

func _draw() -> void:
	var size_v: Vector2 = size
	var cx: float = size_v.x * 0.5
	var cy: float = size_v.y * 0.5
	var r: float = min(size_v.x * 0.47, size_v.y * 0.48)
	var points: PackedVector2Array = []
	for i in range(6):
		var angle: float = deg_to_rad(60.0 * i - 30.0)
		points.append(Vector2(cx + cos(angle) * r, cy + sin(angle) * r))

	var fill_color: Color = _get_fill_color()
	draw_colored_polygon(points, fill_color)
	draw_polyline(points + PackedVector2Array([points[0]]), Color(0.96, 0.90, 0.76, 1.0), 2.0)

	if not mined:
		var hp_ratio: float = float(current_hp) / float(max_hp)
		var bar_w: float = size_v.x * 0.56
		var bar_h: float = 4.0
		var bar_x: float = cx - bar_w * 0.5
		var bar_y: float = cy + r * 0.42
		draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.25, 0.20, 0.15, 0.65), true)
		draw_rect(Rect2(bar_x, bar_y, bar_w * hp_ratio, bar_h), Color(0.36, 0.84, 0.38, 0.95), true)

func _get_fill_color() -> Color:
	if is_locked and not mined:
		return Color(0.55, 0.50, 0.42, 0.85)
	if mined:
		return Color(0.42, 0.39, 0.34, 1.0)

	var ratio: float = float(current_hp) / float(max_hp)
	var base: Color
	if ratio > 0.66:
		base = Color(0.90, 0.78, 0.56, 1.0)
	elif ratio > 0.33:
		base = Color(0.84, 0.70, 0.49, 1.0)
	else:
		base = Color(0.76, 0.59, 0.40, 1.0)

	if is_hovered:
		return base.lightened(0.08)
	return base
