extends Control
class_name MineStageScene

const DigCellScene = preload("res://scenes/ui/dig_cell.tscn")
const DEFAULT_LEVEL_PATH := "res://resources/levels/mine_level_1.tres"
const DEFAULT_CONTENT_PATH := "res://resources/mine_content_default.tres"
const DEFAULT_MINERAL_PATHS := [
	"res://resources/minerals/copper.tres",
	"res://resources/minerals/silver.tres",
	"res://resources/minerals/gold.tres"
]
const DEFAULT_UPGRADE_PATHS := [
	"res://resources/upgrades/dig_power.tres",
	"res://resources/upgrades/max_energy.tres"
]

@export var level_data: MineLevelConfig
@export var mineral_data: Array[MineralConfig] = []
@export var upgrade_data: Array[UpgradeConfig] = []
@export var content_data: MineContentConfig
@export var level_index: int = 0

var mineral_map: Dictionary = {}
var level_config: MineLevelConfig
var grid_system := GridSystem.new()
var spawn_system := MineralSpawnSystem.new()
var stage_system := MineStageSystem.new()

var energy_label: Label
var hp_bar: ProgressBar
var hp_value_label: Label
var mined_label: Label
var gold_label: Label
var tip_label: Label
var level_info_label: Label
var grid_root: VBoxContainer
var settlement_panel: PanelContainer
var settlement_label: Label
var upgrade_power_button: Button
var upgrade_energy_button: Button
var level_option: OptionButton

var cell_nodes: Dictionary = {}
var upgrades: Array[UpgradeConfig] = []

func _ready() -> void:
	randomize()
	_build_ui()
	_start_stage()

func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	var background := TextureRect.new()
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.texture = load("res://assets/scene_bg.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(background)

	var root := VBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.offset_left = 24
	root.offset_top = 20
	root.offset_right = -24
	root.offset_bottom = -24
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var top_space := Control.new()
	top_space.custom_minimum_size.y = 80
	root.add_child(top_space)

	var center_layer := CenterContainer.new()
	center_layer.size_flags_vertical = SIZE_EXPAND_FILL
	root.add_child(center_layer)

	var play_area := VBoxContainer.new()
	play_area.custom_minimum_size = Vector2(860, 320)
	play_area.add_theme_constant_override("separation", 6)
	center_layer.add_child(play_area)

	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 16)
	play_area.add_child(header)

	energy_label = Label.new()
	mined_label = Label.new()
	gold_label = Label.new()
	tip_label = Label.new()
	level_info_label = Label.new()
	tip_label.text = "点击任意格子开始挖掘"
	header.add_child(energy_label)
	header.add_child(mined_label)
	header.add_child(gold_label)
	header.add_child(level_info_label)
	header.add_child(tip_label)
	energy_label.add_theme_color_override("font_color", Color(0.22, 0.14, 0.08))
	mined_label.add_theme_color_override("font_color", Color(0.22, 0.14, 0.08))
	gold_label.add_theme_color_override("font_color", Color(0.22, 0.14, 0.08))
	level_info_label.add_theme_color_override("font_color", Color(0.26, 0.17, 0.08))
	tip_label.add_theme_color_override("font_color", Color(0.32, 0.18, 0.08))

	var debug_buttons := HBoxContainer.new()
	debug_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	debug_buttons.add_theme_constant_override("separation", 8)
	play_area.add_child(debug_buttons)

	var add_gold_button := Button.new()
	add_gold_button.text = "调试+1000金币"
	add_gold_button.pressed.connect(_on_add_gold_pressed)
	_style_tool_button(add_gold_button, Color(0.38, 0.56, 0.76, 1.0))
	debug_buttons.add_child(add_gold_button)

	var reset_button := Button.new()
	reset_button.text = "重置本局"
	reset_button.pressed.connect(_on_restart_pressed)
	_style_tool_button(reset_button, Color(0.76, 0.42, 0.33, 1.0))
	debug_buttons.add_child(reset_button)

	level_option = OptionButton.new()
	level_option.custom_minimum_size = Vector2(180, 42)
	_populate_level_options()
	debug_buttons.add_child(level_option)

	var apply_level_button := Button.new()
	apply_level_button.text = "切换关卡"
	apply_level_button.pressed.connect(_on_apply_level_pressed)
	_style_tool_button(apply_level_button, Color(0.63, 0.54, 0.33, 1.0))
	debug_buttons.add_child(apply_level_button)

	var upgrade_box := HBoxContainer.new()
	upgrade_box.alignment = BoxContainer.ALIGNMENT_CENTER
	upgrade_box.add_theme_constant_override("separation", 8)
	play_area.add_child(upgrade_box)

	upgrade_power_button = Button.new()
	upgrade_power_button.pressed.connect(_on_upgrade_power_pressed)
	_style_tool_button(upgrade_power_button, Color(0.40, 0.60, 0.80, 1.0))
	upgrade_box.add_child(upgrade_power_button)

	upgrade_energy_button = Button.new()
	upgrade_energy_button.pressed.connect(_on_upgrade_energy_pressed)
	_style_tool_button(upgrade_energy_button, Color(0.34, 0.72, 0.54, 1.0))
	upgrade_box.add_child(upgrade_energy_button)

	var mine_frame := CenterContainer.new()
	mine_frame.custom_minimum_size = Vector2(840, 230)
	play_area.add_child(mine_frame)

	var grid_shift := MarginContainer.new()
	grid_shift.add_theme_constant_override("margin_left", 24)
	mine_frame.add_child(grid_shift)

	grid_root = VBoxContainer.new()
	grid_root.add_theme_constant_override("separation", 0)
	grid_shift.add_child(grid_root)

	var bottom_bar := Control.new()
	bottom_bar.custom_minimum_size = Vector2(0, 120)
	root.add_child(bottom_bar)

	var hp_frame := TextureRect.new()
	hp_frame.texture = _make_hp_frame_texture()
	hp_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hp_frame.stretch_mode = TextureRect.STRETCH_KEEP
	hp_frame.position = Vector2(4, 4)
	hp_frame.custom_minimum_size = Vector2(240, 64)
	hp_frame.z_index = 2
	bottom_bar.add_child(hp_frame)

	hp_bar = ProgressBar.new()
	hp_bar.position = Vector2(48, 24)
	hp_bar.custom_minimum_size = Vector2(126, 16)
	hp_bar.show_percentage = false
	hp_bar.max_value = 30
	hp_bar.value = 30
	hp_frame.add_child(hp_bar)

	hp_value_label = Label.new()
	hp_value_label.position = Vector2(178, 18)
	hp_value_label.add_theme_color_override("font_color", Color(0.22, 0.16, 0.10))
	hp_frame.add_child(hp_value_label)

	var panel_tex := TextureRect.new()
	panel_tex.anchor_left = 0.0
	panel_tex.anchor_top = 0.0
	panel_tex.anchor_right = 1.0
	panel_tex.anchor_bottom = 1.0
	panel_tex.texture = load("res://assets/ui_panel_inventory.png")
	panel_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bottom_bar.add_child(panel_tex)

	var tools_button := _create_texture_button("res://assets/ui_button_tools.png", Vector2(120, 68))
	tools_button.anchor_left = 1.0
	tools_button.anchor_right = 1.0
	tools_button.position = Vector2(-268, 22)
	tools_button.z_index = 3
	bottom_bar.add_child(tools_button)

	var end_turn_button := _create_texture_button("res://assets/ui_button_endturn.png", Vector2(120, 68))
	end_turn_button.anchor_left = 1.0
	end_turn_button.anchor_right = 1.0
	end_turn_button.position = Vector2(-138, 22)
	end_turn_button.z_index = 3
	end_turn_button.pressed.connect(_on_restart_pressed)
	bottom_bar.add_child(end_turn_button)

	settlement_panel = PanelContainer.new()
	settlement_panel.visible = false
	settlement_panel.anchor_left = 0.25
	settlement_panel.anchor_top = 0.3
	settlement_panel.anchor_right = 0.75
	settlement_panel.anchor_bottom = 0.7
	add_child(settlement_panel)

	var panel_v := VBoxContainer.new()
	panel_v.add_theme_constant_override("separation", 10)
	panel_v.offset_left = 12
	panel_v.offset_top = 12
	panel_v.offset_right = 12
	panel_v.offset_bottom = 12
	settlement_panel.add_child(panel_v)

	settlement_label = Label.new()
	settlement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel_v.add_child(settlement_label)

	var restart_button := Button.new()
	restart_button.text = "重新开始"
	restart_button.pressed.connect(_on_restart_pressed)
	panel_v.add_child(restart_button)

func _start_stage() -> void:
	mineral_map = _build_mineral_map()
	level_config = _resolve_level_config()
	upgrades = _resolve_upgrades()
	var available_minerals: Array[MineralConfig] = []
	for mineral_id in level_config.mineral_ids:
		if mineral_map.has(mineral_id):
			available_minerals.append(mineral_map[mineral_id])

	var placements := spawn_system.spawn_minerals(level_config, available_minerals)
	grid_system.build_grid(level_config, placements)
	stage_system.setup(level_config, grid_system)
	settlement_panel.visible = false

	_rebuild_grid_nodes()
	_refresh_ui()

func _rebuild_grid_nodes() -> void:
	for child in grid_root.get_children():
		child.queue_free()
	cell_nodes.clear()

	var total_cells: int = level_config.grid_width * level_config.grid_height
	for row in range(level_config.grid_height):
		var row_box := HBoxContainer.new()
		row_box.alignment = BoxContainer.ALIGNMENT_CENTER
		row_box.add_theme_constant_override("separation", -8)
		grid_root.add_child(row_box)

		if row % 2 == 1:
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(28, 1)
			row_box.add_child(spacer)

		for col in range(level_config.grid_width):
			var cell_id := row * level_config.grid_width + col
			if cell_id >= total_cells:
				continue
			var state: Dictionary = grid_system.cells[cell_id]
			var cell: DigCell = DigCellScene.instantiate()
			var label := "岩层"
			var mineral: MineralConfig = state["mineral"]
			if mineral != null:
				label = mineral.name
			cell.setup(cell_id, int(state["max_hp"]), label)
			cell.cell_clicked.connect(_on_cell_clicked)
			row_box.add_child(cell)
			cell_nodes[cell_id] = cell

func _on_cell_clicked(cell_id: int) -> void:
	var result: Dictionary = stage_system.dig_cell(cell_id)
	if not bool(result["ok"]):
		tip_label.text = result["reason"]
		return

	var cell: DigCell = cell_nodes[cell_id]
	cell.apply_damage(stage_system.dig_power)
	if bool(result["just_mined"]):
		var mineral: MineralConfig = result["mineral"]
		tip_label.text = "挖到 %s，+%d 金币" % [mineral.name, mineral.value]
	if int(result.get("special_bonus", 0)) > 0:
		if tip_label.text == "":
			tip_label.text = "触发特殊奖励，+%d 金币" % int(result["special_bonus"])
		else:
			tip_label.text += "；特殊奖励 +%d" % int(result["special_bonus"])

	if bool(result["ended"]):
		_finish_stage(String(result["end_reason"]))

	_refresh_ui()

func _finish_stage(reason: String) -> void:
	for cell_id in cell_nodes.keys():
		var cell: DigCell = cell_nodes[cell_id]
		cell.set_locked()

	settlement_label.text = "关卡结束：%s\n总收益：%d\n已挖矿物：%d" % [
		reason,
		stage_system.total_gain,
		grid_system.mined_count
	]
	settlement_panel.visible = true

func _refresh_ui() -> void:
	energy_label.text = "能量: %d/%d" % [stage_system.energy, stage_system.max_energy]
	mined_label.text = "矿物: %d/%d" % [grid_system.mined_deposits, grid_system.total_deposits]
	gold_label.text = "金币: %d" % stage_system.gold
	level_info_label.text = "关卡: %s  网格: %dx%d  目标: %d" % [
		level_config.name,
		level_config.grid_width,
		level_config.grid_height,
		grid_system.total_deposits
	]
	upgrade_power_button.text = "升级力量 Lv%d (花费%d)" % [stage_system.dig_power, _upgrade_cost(UpgradeConfig.UpgradeType.DIG_POWER)]
	upgrade_energy_button.text = "升级能量上限 (花费%d)" % [_upgrade_cost(UpgradeConfig.UpgradeType.MAX_ENERGY)]
	hp_bar.max_value = stage_system.max_energy
	hp_bar.value = stage_system.energy
	hp_value_label.text = "%d" % stage_system.energy

func _on_add_gold_pressed() -> void:
	stage_system.gold += 1000
	tip_label.text = "调试加钱成功 +1000"
	_refresh_ui()

func _on_restart_pressed() -> void:
	_start_stage()
	tip_label.text = "关卡已重置"

func _on_apply_level_pressed() -> void:
	if level_option != null:
		level_index = max(0, level_option.selected)
	_start_stage()
	tip_label.text = "已切换到关卡 %d" % (level_index + 1)

func _on_upgrade_power_pressed() -> void:
	var cost := _upgrade_cost(UpgradeConfig.UpgradeType.DIG_POWER)
	if stage_system.gold < cost:
		tip_label.text = "金币不足，无法升级力量"
		return
	stage_system.gold -= cost
	stage_system.dig_power += 1
	tip_label.text = "挖掘力量升级成功，当前:%d" % stage_system.dig_power
	_refresh_ui()

func _on_upgrade_energy_pressed() -> void:
	var cost := _upgrade_cost(UpgradeConfig.UpgradeType.MAX_ENERGY)
	if stage_system.gold < cost:
		tip_label.text = "金币不足，无法升级能量"
		return
	stage_system.gold -= cost
	stage_system.max_energy += 5
	stage_system.energy = min(stage_system.max_energy, stage_system.energy + 5)
	tip_label.text = "能量上限提升到 %d" % stage_system.max_energy
	_refresh_ui()

func _upgrade_cost(upgrade_type: UpgradeConfig.UpgradeType) -> int:
	for upgrade in upgrades:
		if upgrade.type == upgrade_type:
			if upgrade_type == UpgradeConfig.UpgradeType.DIG_POWER:
				return upgrade.cost + (stage_system.dig_power - 1) * 40
			return upgrade.cost + int((stage_system.max_energy - level_config.max_energy) / 5) * 30
	return 100

func _create_texture_button(texture_path: String, target_size: Vector2) -> TextureButton:
	var button := TextureButton.new()
	var texture := load(texture_path)
	button.texture_normal = texture
	button.texture_hover = texture
	button.texture_pressed = texture
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.custom_minimum_size = target_size
	return button

func _make_hp_frame_texture() -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://assets/scene_with_hp.png")
	atlas.region = Rect2(8, 172, 146, 34)
	return atlas

func _build_mineral_map() -> Dictionary:
	var data: Dictionary = {}
	var source := mineral_data
	var content := _resolve_content_data()
	if source.is_empty() and content != null and not content.minerals.is_empty():
		source = content.minerals
	if source.is_empty():
		source = _load_default_resources(DEFAULT_MINERAL_PATHS)
	if source.is_empty():
		source = DefaultConfigs.build_minerals().values()
	for mineral in source:
		if mineral != null:
			data[mineral.id] = mineral
	return data

func _resolve_level_config() -> MineLevelConfig:
	var content: MineContentConfig = _resolve_content_data()
	if content != null and not content.levels.is_empty():
		var idx: int = int(clamp(level_index, 0, content.levels.size() - 1))
		return content.levels[idx]
	if ResourceLoader.exists(DEFAULT_LEVEL_PATH):
		var default_level: MineLevelConfig = load(DEFAULT_LEVEL_PATH)
		if level_data == null and default_level != null:
			return default_level
	if level_data != null:
		return level_data
	return DefaultConfigs.build_level()

func _resolve_upgrades() -> Array[UpgradeConfig]:
	var content: MineContentConfig = _resolve_content_data()
	if content != null and not content.upgrades.is_empty():
		return content.upgrades.duplicate()
	if not upgrade_data.is_empty():
		return upgrade_data.duplicate()
	var loaded_upgrades: Array = _load_default_resources(DEFAULT_UPGRADE_PATHS)
	if not loaded_upgrades.is_empty():
		var cast_upgrades: Array[UpgradeConfig] = []
		for item in loaded_upgrades:
			if item is UpgradeConfig:
				cast_upgrades.append(item)
		if not cast_upgrades.is_empty():
			return cast_upgrades
	return DefaultConfigs.build_upgrades()

func _load_default_resources(paths: Array) -> Array:
	var list: Array = []
	for path in paths:
		if ResourceLoader.exists(path):
			var res: Resource = load(path)
			if res != null:
				list.append(res)
	return list

func _resolve_content_data() -> MineContentConfig:
	if content_data != null:
		return content_data
	if ResourceLoader.exists(DEFAULT_CONTENT_PATH):
		var default_content: MineContentConfig = load(DEFAULT_CONTENT_PATH)
		if default_content != null:
			return default_content
	return null

func _populate_level_options() -> void:
	if level_option == null:
		return
	level_option.clear()
	var content: MineContentConfig = _resolve_content_data()
	if content != null and not content.levels.is_empty():
		for i in range(content.levels.size()):
			var cfg: MineLevelConfig = content.levels[i]
			var name := "关卡 %d" % (i + 1)
			if cfg != null and not cfg.name.is_empty():
				name = cfg.name
			level_option.add_item(name, i)
	else:
		level_option.add_item("默认关卡", 0)
	level_option.selected = clamp(level_index, 0, max(0, level_option.item_count - 1))

func _style_tool_button(button: Button, color: Color) -> void:
	button.custom_minimum_size = Vector2(110, 42)
	button.add_theme_font_size_override("font_size", 16)
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_left = 6
	normal.corner_radius_bottom_right = 6
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(0.15, 0.10, 0.08, 0.85)
	var hover := normal.duplicate()
	hover.bg_color = color.lightened(0.08)
	var pressed := normal.duplicate()
	pressed.bg_color = color.darkened(0.12)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color(0.96, 0.93, 0.86))
