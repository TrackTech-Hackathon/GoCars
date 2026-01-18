# snippet_popup.gd
extends PopupPanel
class_name SnippetPopup

signal snippet_selected(snippet)

var item_list: ItemList
var preview_label: RichTextLabel

var filtered_snippets: Array = []

func _ready() -> void:
	item_list = get_node_or_null("VBox/ItemList")
	preview_label = get_node_or_null("VBox/Preview")

func show_snippets(prefix: String, position: Vector2) -> void:
	filtered_snippets = SnippetLibrary.get_by_prefix(prefix)

	if filtered_snippets.is_empty():
		hide()
		return

	_populate_list()
	global_position = position
	show()
	if item_list:
		item_list.grab_focus()
		item_list.select(0)
		_update_preview(0)

func _populate_list() -> void:
	if not item_list:
		return

	item_list.clear()

	for snippet in filtered_snippets:
		var display = "%s -> %s" % [snippet.prefix, snippet.name]
		item_list.add_item(display)

func _update_preview(index: int) -> void:
	if index < 0 or index >= filtered_snippets.size():
		return

	if not preview_label:
		return

	var snippet = filtered_snippets[index]
	var preview_text = "[b]%s[/b]\n%s\n\n[code]%s[/code]" % [
		snippet.name,
		snippet.description,
		"\n".join(snippet.body)
	]
	preview_label.text = preview_text

func select_next() -> void:
	if not item_list:
		return

	var current = item_list.get_selected_items()
	if current.is_empty():
		item_list.select(0)
	else:
		var next_idx = (current[0] + 1) % filtered_snippets.size()
		item_list.select(next_idx)
		_update_preview(next_idx)

func select_prev() -> void:
	if not item_list:
		return

	var current = item_list.get_selected_items()
	if current.is_empty():
		item_list.select(0)
	else:
		var prev_idx = (current[0] - 1 + filtered_snippets.size()) % filtered_snippets.size()
		item_list.select(prev_idx)
		_update_preview(prev_idx)

func confirm() -> void:
	if not item_list:
		return

	var selected = item_list.get_selected_items()
	if not selected.is_empty():
		snippet_selected.emit(filtered_snippets[selected[0]])
	hide()

func _on_item_list_item_selected(index: int) -> void:
	_update_preview(index)

func _on_item_list_item_activated(index: int) -> void:
	snippet_selected.emit(filtered_snippets[index])
	hide()
