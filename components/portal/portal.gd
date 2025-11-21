extends Area3D
@onready var cube: CharacterBody3D = get_node("/root/World/Cube")
@export var teleport_destination : Area3D
func _ready() -> void:
	
	cube.teleport.connect(on_teleport)
		
func on_teleport(colliderName):
	
	if self.name ==colliderName:
		var destination = self.teleport_destination.global_position
		cube.global_position = destination
