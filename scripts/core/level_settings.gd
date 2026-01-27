## Level Settings for GoCars
## Centralized configuration for each level (hearts, road building, etc.)
## Replaces the old hidden Label-based configuration system
## Author: Claude Code
## Date: January 2026

extends Node
class_name LevelSettings

## Level display name shown in menus and UI
@export var level_name: String = ""

## Number of hearts/lives the player starts with
@export_range(1, 20) var starting_hearts: int = 10

## Road Building Configuration
@export_group("Road Building")
## Enable road building mode
@export var build_mode_enabled: bool = false
## Number of road cards available (only used if build_mode_enabled)
@export_range(0, 50) var road_cards: int = 0

## Car Spawning Configuration
@export_group("Car Spawning")
## Automatically spawn cars at intervals
@export var auto_spawn_enabled: bool = true
## Seconds between car spawns
@export_range(5.0, 60.0) var spawn_interval: float = 15.0

## Stoplight Configuration
@export_group("Stoplights")
## Can players edit stoplight code?
@export var stoplight_code_editable: bool = false


## Get LevelSettings from a level node (with fallback to defaults)
## This is the main entry point for reading level settings
static func from_node(level_node: Node) -> LevelSettings:
	var settings_node = level_node.get_node_or_null("LevelSettings")

	# If it's already a LevelSettings script, return it
	if settings_node and settings_node is LevelSettings:
		return settings_node

	# BACKWARD COMPATIBILITY: Try reading old Label format
	if settings_node and settings_node is Node:
		return _read_from_labels(settings_node, level_node)

	# No settings found, return defaults
	return _create_default()


## Read settings from old Label-based format (backward compatibility)
## This allows gradual migration from the old system to the new one
static func _read_from_labels(level_settings_node: Node, level_node: Node) -> LevelSettings:
	var settings = LevelSettings.new()

	# Read level name from LevelName Label
	var name_label = level_settings_node.get_node_or_null("LevelName")
	if name_label and name_label is Label:
		settings.level_name = name_label.text.strip_edges()

	# Read road building config from LevelBuildRoads Label
	var roads_label = level_settings_node.get_node_or_null("LevelBuildRoads")
	if roads_label and roads_label is Label:
		var roads_text = roads_label.text.strip_edges()
		if roads_text.is_valid_int():
			var count = int(roads_text)
			settings.build_mode_enabled = count > 0
			settings.road_cards = count

	# Read heart count from HeartsUI/HeartCount Label
	var hearts_ui = level_node.get_node_or_null("HeartsUI")
	if hearts_ui:
		var heart_label = hearts_ui.get_node_or_null("HeartCount")
		if heart_label and heart_label is Label:
			var heart_text = heart_label.text.strip_edges()
			if heart_text.is_valid_int():
				settings.starting_hearts = int(heart_text)

	return settings


## Create default settings when no configuration is found
static func _create_default() -> LevelSettings:
	var settings = LevelSettings.new()
	settings.level_name = "Untitled Level"
	settings.starting_hearts = 10
	settings.build_mode_enabled = false
	settings.road_cards = 0
	settings.auto_spawn_enabled = true
	settings.spawn_interval = 15.0
	return settings
