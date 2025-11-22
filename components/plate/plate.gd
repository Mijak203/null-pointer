extends Area3D

@onready var cube: Node3D = get_parent().get_node("Cube")

@export var grid_map_target : GridMap 
@export var block_change : StaticBody3D

var target_material: StandardMaterial3D

func _ready() -> void:
	cube.step_on_plate.connect(on_plate_stand)

	if grid_map_target:
		var library = grid_map_target.mesh_library

		var tile_ids = library.get_item_list()
		if tile_ids.size() > 0:
			var item_mesh = library.get_item_mesh(tile_ids[0])
			
			if item_mesh:
				var material = item_mesh.surface_get_material(0)
				
				if material is StandardMaterial3D:

					target_material = material 
					

					target_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					target_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
					

					target_material.cull_mode = BaseMaterial3D.CULL_BACK 
					

					var col = target_material.albedo_color
					col.a = 1.0
					target_material.albedo_color = col

func on_plate_stand():
	if not grid_map_target: return


	if grid_map_target.collision_layer == 1:
		grid_map_target.collision_layer = 0 
		print("Most: Kolizja WYŁĄCZONA")
	else:
		grid_map_target.collision_layer = 1 
		print("Most: Kolizja WŁĄCZONA")

	# --- 2. ZMIANA WYGLĄDU ---
	if target_material:
		var color = target_material.albedo_color
		

		if grid_map_target.collision_layer == 0:
			color.a = 0.2 
		else:
			color.a = 1.0 
			
		target_material.albedo_color = color

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
				
			
