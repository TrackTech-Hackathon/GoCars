## Fold Manager for Code Folding
## Author: Claude Code
## Date: January 2026

class_name FoldManager
extends RefCounted

signal folds_updated()

var code_edit: CodeEdit
var fold_regions: Array[FoldRegion] = []
var folded_lines: Dictionary = {}  # start_line -> FoldRegion

const FOLD_STARTERS = {
	"def ": "function",
	"class ": "class",
	"if ": "conditional",
	"elif ": "conditional",
	"else:": "conditional",
	"for ": "loop",
	"while ": "loop",
	"try:": "error_handling",
	"except": "error_handling",
	"finally:": "error_handling",
	"with ": "context",
	"#region": "region",
}

func _init(editor: CodeEdit) -> void:
	code_edit = editor

func analyze_folds(content: String) -> void:
	fold_regions.clear()
	var lines = content.split("\n")

	var region_stack: Array[Dictionary] = []  # {line, indent, type}

	for i in range(lines.size()):
		var line = lines[i]
		var stripped = line.strip_edges()
		var indent = _get_indent_level(line)

		# Check for fold starters
		for starter in FOLD_STARTERS:
			if stripped.begins_with(starter):
				# Close any regions at same or higher indent
				while not region_stack.is_empty() and region_stack[-1].indent >= indent:
					var region = region_stack.pop_back()
					_create_fold_region(region.line, i - 1, region.indent, region.type, lines)

				region_stack.append({
					"line": i,
					"indent": indent,
					"type": FOLD_STARTERS[starter]
				})
				break

		# Check for #endregion
		if stripped.begins_with("#endregion"):
			for j in range(region_stack.size() - 1, -1, -1):
				if region_stack[j].type == "region":
					var region = region_stack[j]
					region_stack.remove_at(j)
					_create_fold_region(region.line, i, region.indent, region.type, lines)
					break

	# Close remaining regions at end of file
	for region in region_stack:
		var end_line = _find_block_end(region.line, region.indent, lines)
		_create_fold_region(region.line, end_line, region.indent, region.type, lines)

	folds_updated.emit()

func _get_indent_level(line: String) -> int:
	var indent = 0
	for c in line:
		if c == " ":
			indent += 1
		elif c == "\t":
			indent += 4
		else:
			break
	return indent / 4  # Convert to indent level

func _find_block_end(start_line: int, start_indent: int, lines: Array) -> int:
	for i in range(start_line + 1, lines.size()):
		var line = lines[i]
		if line.strip_edges().is_empty():
			continue

		var indent = _get_indent_level(line)
		if indent <= start_indent:
			return i - 1

	return lines.size() - 1

func _create_fold_region(start: int, end: int, indent: int, type: String, lines: Array) -> void:
	if end <= start:
		return

	var region = FoldRegion.new(start, end, indent, type)

	# Generate preview text
	var first_line = lines[start].strip_edges()
	region.preview_text = first_line + " ... (%d lines)" % (end - start)

	fold_regions.append(region)

func toggle_fold(line: int) -> void:
	var region = get_fold_at_line(line)
	if region:
		if region.is_folded:
			unfold(region)
		else:
			fold(region)

func fold(region: FoldRegion) -> void:
	if region.is_folded:
		return

	region.is_folded = true
	folded_lines[region.start_line] = region

	# Hide lines in CodeEdit
	for i in range(region.start_line + 1, region.end_line + 1):
		code_edit.set_line_as_hidden(i, true)

	folds_updated.emit()

func unfold(region: FoldRegion) -> void:
	if not region.is_folded:
		return

	region.is_folded = false
	folded_lines.erase(region.start_line)

	# Show lines in CodeEdit
	for i in range(region.start_line + 1, region.end_line + 1):
		code_edit.set_line_as_hidden(i, false)

	folds_updated.emit()

func fold_all() -> void:
	for region in fold_regions:
		fold(region)

func unfold_all() -> void:
	for region in fold_regions:
		unfold(region)

func get_fold_at_line(line: int) -> FoldRegion:
	for region in fold_regions:
		if region.start_line == line:
			return region
	return null

func is_line_foldable(line: int) -> bool:
	return get_fold_at_line(line) != null

func is_line_folded(line: int) -> bool:
	var region = get_fold_at_line(line)
	return region != null and region.is_folded

func get_visible_line_count() -> int:
	var hidden = 0
	for region in folded_lines.values():
		hidden += region.end_line - region.start_line
	return code_edit.get_line_count() - hidden
