extends Control

const CAMPAIGN_SCENE := "res://scenes/ui/Main_Menu/CampaignMenu.tscn"

func _on_btn_campaign_pressed() -> void:
	SceneLoader.load_scene_async(CAMPAIGN_SCENE)
