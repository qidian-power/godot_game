extends Resource
class_name MineLevelConfig

enum EndConditionType {
	ENERGY_AND_ALL_MINED = 0,
	ALL_MINED_ONLY = 1,
	ENERGY_ONLY = 2,
}

@export var id: int = 0
@export var name: String = ""
@export var grid_width: int = 8
@export var grid_height: int = 6
@export var initial_energy: int = 20
@export var max_energy: int = 20
@export var energy_cost_per_dig: int = 1
@export var default_cell_hp: int = 1
@export var mineral_ids: Array[int] = []
@export var spawn_total_count: int = 10
@export var spawn_rules: SpawnRule
@export var end_condition_type: EndConditionType = EndConditionType.ENERGY_AND_ALL_MINED
@export var background_sprite: String = ""
@export var special_reward_chance: float = 0.0
@export var special_reward_gold_min: int = 0
@export var special_reward_gold_max: int = 0
