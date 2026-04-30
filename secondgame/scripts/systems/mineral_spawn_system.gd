extends RefCounted
class_name MineralSpawnSystem

func spawn_minerals(level_config: MineLevelConfig, minerals: Array[MineralConfig]) -> Dictionary:
	var placements: Dictionary = {}
	if minerals.is_empty():
		return placements

	var total_weight: int = 0
	for mineral in minerals:
		total_weight += max(1, mineral.weight)

	var created: int = 0
	var deposit_id: int = 1
	var max_attempts: int = level_config.spawn_total_count * 60
	var attempts: int = 0

	while created < level_config.spawn_total_count and attempts < max_attempts:
		attempts += 1
		var mineral: MineralConfig = _pick_by_weight(minerals, total_weight)
		var cells: Array[int] = _pick_cells_for_mineral(level_config, mineral, placements)
		if cells.is_empty():
			continue

		for cell_id in cells:
			placements[cell_id] = {
				"mineral": mineral,
				"deposit_id": deposit_id
			}
		created += 1
		deposit_id += 1

	return placements

func _pick_by_weight(minerals: Array[MineralConfig], total_weight: int) -> MineralConfig:
	var roll: int = randi_range(1, max(1, total_weight))
	var cumulative: int = 0
	for mineral in minerals:
		cumulative += max(1, mineral.weight)
		if roll <= cumulative:
			return mineral
	return minerals[0]

func _pick_cells_for_mineral(level_config: MineLevelConfig, mineral: MineralConfig, placements: Dictionary) -> Array[int]:
	var width: int = max(1, mineral.width)
	var height: int = max(1, mineral.height)
	var max_x: int = level_config.grid_width - width
	var max_y: int = level_config.grid_height - height
	if max_x < 0 or max_y < 0:
		return []

	var start_x: int = randi_range(0, max_x)
	var start_y: int = randi_range(0, max_y)
	var cells: Array[int] = []
	for y in range(height):
		for x in range(width):
			var gx: int = start_x + x
			var gy: int = start_y + y
			var cell_id: int = gy * level_config.grid_width + gx
			if placements.has(cell_id):
				return []
			cells.append(cell_id)

	if level_config.spawn_rules != null and level_config.spawn_rules.min_distance > 0:
		if not _check_min_distance(level_config, cells, placements, level_config.spawn_rules.min_distance):
			return []
	return cells

func _check_min_distance(level_config: MineLevelConfig, cells: Array[int], placements: Dictionary, min_distance: int) -> bool:
	for cell_id in cells:
		var x: int = cell_id % level_config.grid_width
		var y := int(cell_id / level_config.grid_width)
		for dy in range(-min_distance, min_distance + 1):
			for dx in range(-min_distance, min_distance + 1):
				if dx == 0 and dy == 0:
					continue
				var nx: int = x + dx
				var ny: int = y + dy
				if nx < 0 or ny < 0 or nx >= level_config.grid_width or ny >= level_config.grid_height:
					continue
				var neighbor_id: int = ny * level_config.grid_width + nx
				if placements.has(neighbor_id):
					return false
	return true
