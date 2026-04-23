extends Area3D

func _ready() -> void:
	add_to_group("pickup")
	body_entered.connect(_on_body)


func _on_body(body: Node3D) -> void:
	if visible and body.is_in_group("karpathy_agent"):
		visible = false
		$CollisionShape3D.set_deferred("disabled", true)
