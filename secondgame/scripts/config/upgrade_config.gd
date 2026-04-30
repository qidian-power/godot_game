extends Resource
class_name UpgradeConfig

enum UpgradeType {
	DIG_POWER = 0,
	MAX_ENERGY = 1,
	DIG_RANGE = 2,
}

@export var id: int = 0
@export var name: String = ""
@export var type: UpgradeType = UpgradeType.DIG_POWER
@export var level: int = 1
@export var value: int = 0
@export var cost: int = 0
