extends Area3D

@onready var cube: Node3D = get_parent().get_node("Cube")

@export var grid_map_target : GridMap 
@export var block_change : StaticBody3D

# Cache materiałów (żeby nie szukać ich ciągle i nie zacinać gry)
var grid_material: Material
var block_mesh: MeshInstance3D
var block_material: Material
var block_collision: CollisionShape3D

func _ready() -> void:
	cube.step_on_plate.connect(on_plate_stand)
	
	# --- 1. PRZYGOTOWANIE GRID MAPY ---
	
	if grid_map_target:
		var library = grid_map_target.mesh_library
		var tile_ids = library.get_item_list()
		if tile_ids.size() > 0:
			var item_mesh = library.get_item_mesh(tile_ids[0])
			if item_mesh:
				grid_material = item_mesh.surface_get_material(0)
				_setup_transparency(grid_material)
		grid_map_target.collision_layer = 0 
		print("Most: Kolizja WYŁĄCZONA")
		_set_material_alpha(grid_material, 0.2) # Zrób przezroczyste
	# --- 2. PRZYGOTOWANIE BLOCK CHANGE (Zoptymalizowane) ---
	if block_change:
		for child in block_change.get_children():
			if child is MeshInstance3D:
				block_mesh = child
				# Tworzymy unikalną kopię RAZ na starcie
				var original_mat = child.get_active_material(0)
				if original_mat:
					block_material = original_mat.duplicate()
					_setup_transparency(block_material)
					# Przypisujemy kopię do obiektu
					block_mesh.material_override = block_material
					
			elif child is CollisionShape3D:
				block_collision = child

# Funkcja pomocnicza ustawiająca flagi techniczne materiału
func _setup_transparency(mat: Material):
	if mat is StandardMaterial3D:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
		mat.cull_mode = BaseMaterial3D.CULL_BACK
		# Reset koloru na start
		var col = mat.albedo_color
		col.a = 1.0
		mat.albedo_color = col
		
	elif mat is ShaderMaterial:
		# Dla shadera ustawiamy render_priority na -1 (tło), żeby nie zasłaniał gracza
		mat.render_priority = -1
		# Reset alpha na start
		mat.set_shader_parameter("transparency_alpha", 1.0)

func on_plate_stand(collider_name):
	# --- LOGIKA GRID MAPY ---
	if self.name == collider_name:
		
		if grid_map_target:
			# Przełącz kolizję
			if grid_map_target.collision_layer == 1:
				grid_map_target.collision_layer = 0 
				print("Most: Kolizja WYŁĄCZONA")
				_set_material_alpha(grid_material, 0.2) # Zrób przezroczyste
			else:
				grid_map_target.collision_layer = 1 
				print("Most: Kolizja WŁĄCZONA")
				_set_material_alpha(grid_material, 1.0) # Zrób widoczne

		# --- LOGIKA STATYCZNEGO BLOKU ---
		if block_change:
			# Przełącz kolizję
			if block_collision:
				# set_deferred dla bezpieczeństwa fizyki
				block_collision.set_deferred("disabled", !block_collision.disabled)
			
			# Zmień wygląd (na podstawie stanu kolizji - odwracamy logikę lub sprawdzamy obecny stan)
			# Tutaj prosty toggle na podstawie aktualnej wartości alpha
			var current_alpha = _get_material_alpha(block_material)
			if current_alpha > 0.8:
				_set_material_alpha(block_material, 0.2) # Ukryj
			else:
				_set_material_alpha(block_material, 1.0) # Pokaż
			
			# Zmiana koloru dla firewalla
			if block_change.is_in_group("firewall"):
				# Użyj get_active_material, jest bezpieczniejsze (znajdzie materiał niezależnie czy jest w override czy w meshu)
				var mat = block_mesh.get_active_material(0)
				
				if mat is ShaderMaterial:
					var shader_mat := mat as ShaderMaterial
					
					if block_collision.disabled: 
						shader_mat.set_shader_parameter("base_color", Color(1.0, 0.1, 0.1, 0.35)) # czerwony
					else:
						shader_mat.set_shader_parameter("base_color", Color(0.0, 1.0, 0.3, 0.35)) # zielony")

# Uniwersalna funkcja ustawiająca przezroczystość dla obu typów materiałów
func _set_material_alpha(mat: Material, alpha_value: float):
	if not mat: return
	
	if mat is StandardMaterial3D:
		var col = mat.albedo_color
		col.a = alpha_value
		mat.albedo_color = col
		
	elif mat is ShaderMaterial:
		# Tutaj ustawiamy ten nowy parametr w shaderze!
		mat.set_shader_parameter("transparency_alpha", alpha_value)

# Funkcja pomocnicza do odczytu obecnej wartości
func _get_material_alpha(mat: Material) -> float:
	if not mat: return 1.0
	
	if mat is StandardMaterial3D:
		return mat.albedo_color.a
	elif mat is ShaderMaterial:
		# Pobieramy parametr (jeśli nie istnieje, zwróci null, więc rzutujemy na float)
		var val = mat.get_shader_parameter("transparency_alpha")
		if val != null:
			return val
		return 1.0
	return 1.0
