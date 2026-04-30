extends RefCounted
class_name GridSystem

var cells: Dictionary = {}
var mined_count: int = 0
var total_deposits: int = 0
var mined_deposits: int = 0
var _deposit_total_cells: Dictionary = {}
var _deposit_mined_cells: Dictionary = {}
var _deposit_rewarded: Dictionary = {}

func build_grid(level_config: MineLevelConfig, placements: Dictionary) -> void:
	cells.clear()
	mined_count = 0
	total_deposits = 0
	mined_deposits = 0
	_deposit_total_cells.clear()
	_deposit_mined_cells.clear()
	_deposit_rewarded.clear()

	var total_cells: int = level_config.grid_width * level_config.grid_height
	for cell_id in range(total_cells):
		var placement: Dictionary = placements.get(cell_id, {})
		var mineral: MineralConfig = placement.get("mineral")
		var deposit_id: int = int(placement.get("deposit_id", -1))
		var hp_value := level_config.default_cell_hp
		var is_reward := false
		if mineral != null:
			hp_value = max(1, mineral.hp)
			is_reward = true
			if not _deposit_total_cells.has(deposit_id):
				_deposit_total_cells[deposit_id] = 0
				_deposit_mined_cells[deposit_id] = 0
				_deposit_rewarded[deposit_id] = false
				total_deposits += 1
			_deposit_total_cells[deposit_id] = int(_deposit_total_cells[deposit_id]) + 1

		cells[cell_id] = {
			"cell_id": cell_id,
			"hp": hp_value,
			"max_hp": hp_value,
			"mined": false,
			"mineral": mineral,
			"deposit_id": deposit_id,
			"is_reward": is_reward
		}

func can_dig(cell_id: int) -> bool:
	return cells.has(cell_id) and not cells[cell_id]["mined"]

func dig_cell(cell_id: int, dig_power: int) -> Dictionary:
	if not can_dig(cell_id):
		return {"ok": false, "reason": "该格子已挖空"}

	var cell_state: Dictionary = cells[cell_id]
	cell_state["hp"] = max(0, int(cell_state["hp"]) - max(1, dig_power))

	var just_mined: bool = false
	var mined_mineral: MineralConfig = null
	if int(cell_state["hp"]) == 0 and not cell_state["mined"]:
		cell_state["mined"] = true
		mined_count += 1
		if bool(cell_state["is_reward"]):
			var deposit_id := int(cell_state["deposit_id"])
			_deposit_mined_cells[deposit_id] = int(_deposit_mined_cells.get(deposit_id, 0)) + 1
			if int(_deposit_mined_cells[deposit_id]) >= int(_deposit_total_cells.get(deposit_id, 1)) and not bool(_deposit_rewarded.get(deposit_id, false)):
				_deposit_rewarded[deposit_id] = true
				mined_deposits += 1
				just_mined = true
				mined_mineral = cell_state["mineral"]

	cells[cell_id] = cell_state
	return {
		"ok": true,
		"cell_id": cell_id,
		"hp": int(cell_state["hp"]),
		"max_hp": int(cell_state["max_hp"]),
		"just_mined": just_mined,
		"mineral": mined_mineral
	}

func all_mined() -> bool:
	return mined_deposits >= total_deposits
