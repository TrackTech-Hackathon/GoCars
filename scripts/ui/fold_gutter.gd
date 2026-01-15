## Fold Gutter for Code Folding UI
## Author: Claude Code
## Date: January 2026

class_name FoldGutter
extends RefCounted

var code_edit: CodeEdit
var fold_manager: FoldManager

const GUTTER_FOLD = 2  # Gutter index for fold indicators

# Icons (would need actual textures in real implementation)
var fold_icon: Texture2D      # ▶ or ▼
var unfold_icon: Texture2D
var fold_end_icon: Texture2D  # └

func _init(editor: CodeEdit, manager: FoldManager) -> void:
	code_edit = editor
	fold_manager = manager

	# Setup fold gutter
	code_edit.add_gutter(GUTTER_FOLD)
	code_edit.set_gutter_type(GUTTER_FOLD, CodeEdit.GUTTER_TYPE_ICON)
	code_edit.set_gutter_width(GUTTER_FOLD, 16)
	code_edit.set_gutter_clickable(GUTTER_FOLD, true)

	# Connect signals
	code_edit.gutter_clicked.connect(_on_gutter_clicked)
	fold_manager.folds_updated.connect(_update_gutter_icons)

func _update_gutter_icons() -> void:
	# Clear all fold icons
	for i in range(code_edit.get_line_count()):
		code_edit.set_line_gutter_icon(i, GUTTER_FOLD, null)

	# Add icons for foldable lines
	for region in fold_manager.fold_regions:
		var icon = unfold_icon if region.is_folded else fold_icon
		code_edit.set_line_gutter_icon(region.start_line, GUTTER_FOLD, icon)

func _on_gutter_clicked(line: int, gutter: int) -> void:
	if gutter == GUTTER_FOLD:
		fold_manager.toggle_fold(line)
