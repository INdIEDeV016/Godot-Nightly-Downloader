tool
extends Button

export (PackedScene) var scene

func _on_NextButton_pressed():
	get_tree().change_scene_to(scene)

func _get_configuration_warning():
	return "Next scene property can't be empty" if not scene else ""
