## Module Loader for GoCars
## Resolves and loads Python modules for the import system
## Author: Claude Code
## Date: January 2026

extends RefCounted
class_name ModuleLoader

## Signals
signal module_loaded(module_name: String)
signal module_error(module_name: String, error: String)

## Dependencies
var _virtual_fs: Variant = null  # VirtualFileSystem instance
var _parser: Variant = null  # PythonParser instance

## Loaded modules cache: module_name -> parsed AST
var _loaded_modules: Dictionary = {}

## Import chain for circular dependency detection
var _import_chain: Array = []

func _init() -> void:
	var PythonParser = load("res://scripts/core/python_parser.gd")
	_parser = PythonParser.new()

## Set the virtual filesystem to load modules from
func set_filesystem(vfs: Variant) -> void:
	_virtual_fs = vfs

## Load a module and return its parsed AST
## Returns null if module cannot be loaded
func load_module(module_name: String) -> Variant:
	# Check if already loaded (cached)
	if _loaded_modules.has(module_name):
		return _loaded_modules[module_name]

	# Check for circular imports
	if module_name in _import_chain:
		var error = "CircularImportError: circular import detected: %s" % " -> ".join(_import_chain + [module_name])
		push_error(error)
		module_error.emit(module_name, error)
		return null

	# Resolve module path
	var module_path = _resolve_module_path(module_name)
	if module_path == "":
		var error = "ModuleNotFoundError: No module named '%s'" % module_name
		push_error(error)
		module_error.emit(module_name, error)
		return null

	# Check if virtual filesystem is set
	if _virtual_fs == null:
		push_error("ModuleLoader: Virtual filesystem not set")
		return null

	# Check if file exists
	if not _virtual_fs.file_exists(module_path):
		var error = "ModuleNotFoundError: No module named '%s' (path: %s)" % [module_name, module_path]
		push_error(error)
		module_error.emit(module_name, error)
		return null

	# Read module source code
	var source = _virtual_fs.read_file(module_path)
	if source == "":
		var error = "ModuleError: Module '%s' is empty or cannot be read" % module_name
		push_error(error)
		module_error.emit(module_name, error)
		return null

	# Add to import chain (for circular dependency detection)
	_import_chain.append(module_name)

	# Parse module
	var ast = _parser.parse(source)

	# Remove from import chain
	_import_chain.erase(module_name)

	# Check for parse errors
	if _parser._errors.size() > 0:
		var error = "SyntaxError in module '%s': %s" % [module_name, _parser._errors[0]]
		push_error(error)
		module_error.emit(module_name, error)
		return null

	# Cache the loaded module
	_loaded_modules[module_name] = ast
	module_loaded.emit(module_name)

	return ast

## Resolve module name to file path
## Examples:
##   "helpers" -> "helpers.py"
##   "modules.navigation" -> "modules/navigation.py"
func _resolve_module_path(module_name: String) -> String:
	# Convert dots to slashes
	var path = module_name.replace(".", "/")

	# Add .py extension
	path += ".py"

	return path

## Clear all loaded modules (useful for testing or level restart)
func clear_cache() -> void:
	_loaded_modules.clear()
	_import_chain.clear()

## Get all loaded module names
func get_loaded_modules() -> Array:
	return _loaded_modules.keys()

## Check if a module is loaded
func is_module_loaded(module_name: String) -> bool:
	return _loaded_modules.has(module_name)

## Get module AST (if loaded)
func get_module_ast(module_name: String) -> Variant:
	if _loaded_modules.has(module_name):
		return _loaded_modules[module_name]
	return null
