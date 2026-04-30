extends RefCounted
class_name MineStageSystem

var level_config: MineLevelConfig
var grid_system: GridSystem

var energy: int = 0
var max_energy: int = 0
var dig_power: int = 1
var gold: int = 0
var total_gain: int = 0
var stage_ended: bool = false

func setup(new_level_config: MineLevelConfig, new_grid_system: GridSystem) -> void:
	level_config = new_level_config
	grid_system = new_grid_system
	reset_stage()

func dig_cell(cell_id: int) -> Dictionary:
	if stage_ended:
		return {"ok": false, "reason": "关卡已结束"}
	if energy < level_config.energy_cost_per_dig:
		return {"ok": false, "reason": "能量不足"}
	if not grid_system.can_dig(cell_id):
		return {"ok": false, "reason": "该格子不可挖掘"}

	energy -= level_config.energy_cost_per_dig
	var dig_result: Dictionary = grid_system.dig_cell(cell_id, dig_power)
	if not bool(dig_result["ok"]):
		return dig_result

	if bool(dig_result["just_mined"]):
		var mineral: MineralConfig = dig_result["mineral"]
		if mineral != null:
			gold += mineral.value
			total_gain += mineral.value

	var special_bonus: int = 0
	if level_config.special_reward_chance > 0.0 and randf() <= level_config.special_reward_chance:
		special_bonus = randi_range(level_config.special_reward_gold_min, max(level_config.special_reward_gold_min, level_config.special_reward_gold_max))
		gold += special_bonus
		total_gain += special_bonus

	var end_result: Dictionary = check_end_condition()
	return {
		"ok": true,
		"cell_id": cell_id,
		"hp": dig_result["hp"],
		"max_hp": dig_result["max_hp"],
		"just_mined": dig_result["just_mined"],
		"energy": energy,
		"gold": gold,
		"mined_count": grid_system.mined_count,
		"ended": bool(end_result["ended"]),
		"end_reason": end_result["reason"],
		"mineral": dig_result["mineral"],
		"special_bonus": special_bonus
	}

func check_end_condition() -> Dictionary:
	var all_mined: bool = grid_system.all_mined()
	var energy_empty: bool = energy < level_config.energy_cost_per_dig

	var ended: bool = false
	match level_config.end_condition_type:
		MineLevelConfig.EndConditionType.ENERGY_AND_ALL_MINED:
			ended = all_mined or energy_empty
		MineLevelConfig.EndConditionType.ALL_MINED_ONLY:
			ended = all_mined
		MineLevelConfig.EndConditionType.ENERGY_ONLY:
			ended = energy_empty

	if ended:
		stage_ended = true

	return {
		"ended": ended,
		"reason": "矿物已挖完" if all_mined else "能量耗尽"
	}

func reset_stage() -> void:
	energy = level_config.initial_energy
	max_energy = level_config.max_energy
	dig_power = 1
	gold = 0
	total_gain = 0
	stage_ended = false
