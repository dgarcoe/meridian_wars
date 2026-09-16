extends RefCounted
## Single versioned campaign slot, written through a temporary sibling file.

const Operation = preload("res://domain/operation.gd")
const PATH := "user://meridian_operation.json"
const MAX_BYTES := 65536


func save(operation: RefCounted, path: String = PATH) -> Error:
	if operation.phase == "battle":
		return ERR_BUSY
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(operation.to_data(), "\t"))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return error
	return DirAccess.rename_absolute(path + ".tmp", path)


func load_operation(path: String = PATH) -> RefCounted:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > MAX_BYTES:
		return null
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(data) != TYPE_DICTIONARY:
		return null
	var operation := Operation.new()
	return operation if operation.restore(data) else null
