## Fold Region for Code Folding System
## Author: Claude Code
## Date: January 2026

class_name FoldRegion
extends RefCounted

var start_line: int
var end_line: int
var indent_level: int
var is_folded: bool = false
var fold_type: String  # "function", "class", "loop", "conditional", "region"
var preview_text: String  # Text shown when folded

func _init(start: int, end: int, indent: int, type: String) -> void:
	start_line = start
	end_line = end
	indent_level = indent
	fold_type = type

func get_line_count() -> int:
	return end_line - start_line
