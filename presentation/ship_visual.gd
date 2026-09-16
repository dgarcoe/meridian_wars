extends RefCounted
## Small original procedural ship kit; +X is the bow. No external assets.


static func material(color: Color, emissive: bool = false) -> StandardMaterial3D:
	var value := StandardMaterial3D.new()
	value.albedo_color = color
	value.metallic = .6
	value.roughness = .45
	if emissive:
		value.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		value.emission_enabled = true
		value.emission = color
	return value


static func create(ship_class: int, accent: Color) -> Node3D:
	var root := Node3D.new()
	var hull := material(Color("596c7e"))
	var armor := material(Color("23384c"))
	var light := material(accent, true)
	var length: float = [3.4, 4.8, 5.8][ship_class]
	_box(root, Vector3(length,.7,1.0), Vector3.ZERO, hull)
	_box(root, Vector3(length*.65,.4,1.65), Vector3(-.4,-.25,0), armor)
	_box(root, Vector3(1.2,.75,.7), Vector3(-.6,.6,0), armor)
	_box(root, Vector3(.7,.08,.55), Vector3(-.1,1.0,0), light)
	_box(root, Vector3(.16,.45,.75), Vector3(-length*.5-.1,0,0), light)
	_box(root, Vector3(length*.6,.12,.14), Vector3(0,.4,.55), light)
	if ship_class > 0:
		for z in [-1.0,1.0]:
			_box(root, Vector3(length*.65,.35,.4), Vector3(-.7,-.1,z), armor)
			_box(root, Vector3(.2,.25,.25), Vector3(-length*.43,-.1,z), light)
	var nose := MeshInstance3D.new()
	var mesh := PrismMesh.new()
	mesh.size = Vector3(1.3,1.3,1.0)
	nose.mesh = mesh
	nose.rotation.z = -PI/2
	nose.position.x = length/2
	nose.material_override = hull
	root.add_child(nose)
	return root


static func _box(root: Node3D, size: Vector3, position: Vector3, material: Material) -> void:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = material
	node.position = position
	root.add_child(node)
