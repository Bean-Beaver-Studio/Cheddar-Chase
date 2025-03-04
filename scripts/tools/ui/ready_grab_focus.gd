extends Control

func _ready() -> void:
	grab_focus()
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed() -> void:
	if visible:
		grab_focus()
