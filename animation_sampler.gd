extends Control

@onready var anim_player: AnimationPlayer = get_node_or_null("../../PlayerCharacter/AnimationPlayer")
@onready var button_container: VBoxContainer = $ScrollContainer/VBoxContainer

func _ready() -> void:
	# Wait for libraries to be consolidated in character_body_3d.gd
	await get_tree().create_timer(1.2).timeout
	create_animation_sampler()

func create_animation_sampler() -> void:
	if not button_container:
		return
		
	# Clear existing
	for child in button_container.get_children():
		child.queue_free()
		
	if not anim_player:
		# Search fallback if the path is slightly off
		anim_player = get_tree().current_scene.find_child("AnimationPlayer", true, false)
		
	if not anim_player:
		push_error("AnimationSampler: Could not find AnimationPlayer in scene!")
		return
		
	var all_animations = anim_player.get_animation_list()
	print("Sampler: Found ", all_animations.size(), " animations")
	
	for anim_name in all_animations:
		var btn = Button.new()
		btn.text = anim_name
		btn.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
		button_container.add_child(btn)
		
		# Connect with bind for Godot 4
		btn.pressed.connect(_on_anim_pressed.bind(anim_name))

func _on_anim_pressed(anim_name: String) -> void:
	if anim_player:
		anim_player.play(anim_name)
		print("Sampler: Playing ", anim_name)

# Alias for create_animation_sampler
func create_sampler(): create_animation_sampler()
