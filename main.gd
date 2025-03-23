extends GridContainer
@onready var teste :PieChart = $Control/PieChart

func _ready() -> void:
	teste.elements= {"Unity" : 3324, "Godot" : 2838, "GameMaker" : 389, "Unreal" : 383, "Other" : 777}
