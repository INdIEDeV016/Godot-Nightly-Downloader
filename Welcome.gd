extends Control


var link: = "https://hugo.pro/projects/godot-builds/"

func _ready():
	$CanvasLayer2/TitleBar.connect("close_dialog", $CanvasLayer/CloseDialog, "popup")


func _on_Information_meta_clicked(meta: String):
	if meta.begins_with("http"):
		if OS.shell_open(meta) == OK:
			print("Link opened")
		else:
			print("Couldn't open link")


func _on_Information_meta_hover_started(meta):
	pass


func _on_Information_meta_hover_ended(meta):
	pass


func _on_AboutButton_pressed() -> void:
	get_tree().change_scene_to(load("res://About.tscn"))
