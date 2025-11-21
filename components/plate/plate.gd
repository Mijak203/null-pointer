extends Area3D


@onready var cube: Node3D = get_parent().get_node("Cube")
@export var block_change : StaticBody3D

func _ready() -> void:
	
	cube.step_on_plate.connect(on_plate_stand)
		
func on_plate_stand():
	if block_change != null:
		for child in block_change.get_children():
			if child is MeshInstance3D:
				var current_mat = child.get_active_material(0)

				if current_mat and current_mat is StandardMaterial3D:
					var new_mat = current_mat.duplicate()
					new_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					new_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
					var color = new_mat.albedo_color
					if color.a <= 0.5:
						color.a = 1
					elif color.a > 0.5:
						color.a = 0.5
					new_mat.albedo_color = color

					child.material_override = new_mat
					new_mat.render_priority = -1
			elif child is CollisionShape3D:
				if child.disabled == true:
					child.disabled = false
				elif child.disabled == false:
					child.disabled = true
				
			
