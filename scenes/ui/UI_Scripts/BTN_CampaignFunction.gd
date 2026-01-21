extends Control

const CAMPAIGN_SCENE := "res://scenes/menus/level_selector.tscn"

func _on_btn_campaign_pressed() -> void:
	get_tree().change_scene_to_file(CAMPAIGN_SCENE)
