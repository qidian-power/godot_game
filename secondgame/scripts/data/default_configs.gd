extends RefCounted
class_name DefaultConfigs

static func build_minerals() -> Dictionary:
	var minerals: Dictionary = {}

	var copper := MineralConfig.new()
	copper.id = 1
	copper.name = "铜矿"
	copper.value = 5
	copper.weight = 50
	copper.hp = 2
	copper.width = 1
	copper.height = 1
	minerals[copper.id] = copper

	var silver := MineralConfig.new()
	silver.id = 2
	silver.name = "银矿"
	silver.value = 10
	silver.weight = 30
	silver.hp = 3
	silver.width = 1
	silver.height = 2
	minerals[silver.id] = silver

	var gold := MineralConfig.new()
	gold.id = 3
	gold.name = "金矿"
	gold.value = 20
	gold.weight = 20
	gold.hp = 4
	gold.width = 2
	gold.height = 2
	minerals[gold.id] = gold

	return minerals

static func build_level() -> MineLevelConfig:
	var rule := SpawnRule.new()
	rule.no_overlap = true
	rule.border_check = true
	rule.min_distance = 0

	var level := MineLevelConfig.new()
	level.id = 1
	level.name = "新手矿场"
	level.grid_width = 8
	level.grid_height = 6
	level.initial_energy = 30
	level.max_energy = 30
	level.energy_cost_per_dig = 1
	level.default_cell_hp = 2
	level.mineral_ids = [1, 2, 3]
	level.spawn_total_count = 16
	level.spawn_rules = rule
	level.end_condition_type = MineLevelConfig.EndConditionType.ENERGY_AND_ALL_MINED
	level.special_reward_chance = 0.08
	level.special_reward_gold_min = 3
	level.special_reward_gold_max = 12
	return level

static func build_upgrades() -> Array[UpgradeConfig]:
	var list: Array[UpgradeConfig] = []

	var dig_power_u := UpgradeConfig.new()
	dig_power_u.id = 1
	dig_power_u.name = "挖掘力量"
	dig_power_u.type = UpgradeConfig.UpgradeType.DIG_POWER
	dig_power_u.level = 1
	dig_power_u.value = 1
	dig_power_u.cost = 80
	list.append(dig_power_u)

	var energy_u := UpgradeConfig.new()
	energy_u.id = 2
	energy_u.name = "能量上限"
	energy_u.type = UpgradeConfig.UpgradeType.MAX_ENERGY
	energy_u.level = 1
	energy_u.value = 5
	energy_u.cost = 60
	list.append(energy_u)

	return list
