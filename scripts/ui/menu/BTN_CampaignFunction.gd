extends Control

const CAMPAIGN_SCENE := "res://scenes/ui/Main_Menu/CampaignMenu.tscn"

func _on_btn_campaign_pressed() -> void:
	get_tree().change_scene_to_file(CAMPAIGN_SCENE)
