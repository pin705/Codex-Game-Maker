extends Node2D

@onready var status_label: Label = $CanvasLayer/StatusLabel

func _ready() -> void:
    status_label.text = "Import a generated sprite scene, then instance it under ShowcaseRoot."
