import bpy

def create_fire_animation(armature_name):
    arm = bpy.data.objects.get(armature_name)
    if not arm or arm.type != 'ARMATURE':
        print(f"Error: {armature_name} not found")
        return

    # Create new Action
    action = bpy.data.actions.new(name="Fire")
    if not arm.animation_data:
        arm.animation_data_create()
    arm.animation_data.action = action

    # Helper to insert keyframes
    def insert_key(bone_name, frame, location=None, rotation=None):
        pbone = arm.pose.bones.get(bone_name)
        if not pbone: return
        
        if location is not None:
            pbone.location = location
            pbone.keyframe_insert(data_path="location", frame=frame)
        if rotation is not None:
            pbone.rotation_euler = rotation
            pbone.keyframe_insert(data_path="rotation_euler", frame=frame)

    # Frame 0: Rest Position
    insert_key("Slide", 0, location=(0,0,0))
    insert_key("Trigger", 0, rotation=(0,0,0))
    insert_key("Body", 0, rotation=(0,0,0))

    # Frame 2: Peak Recoil (Slide back, Trigger back, Body kick)
    # Slide back on its local Y axis (which is pointing along barrel)
    insert_key("Slide", 2, location=(0, -0.05, 0)) # 5cm back
    insert_key("Trigger", 2, rotation=(0.4, 0, 0)) # Pull back
    insert_key("Body", 2, rotation=(-0.1, 0, 0))   # Kick up (negative X rotation)

    # Frame 10: Back to Rest
    insert_key("Slide", 10, location=(0,0,0))
    insert_key("Trigger", 10, rotation=(0,0,0))
    insert_key("Body", 10, rotation=(0,0,0))

    # Push to NLA so it exports
    track = arm.animation_data.nla_tracks.new()
    track.name = "Fire"
    track.strips.new("Fire", 0, action)
    
    # Set action to None so NLA drives the export
    arm.animation_data.action = None
    
    print("SUCCESS: 'Fire' animation created and pushed to NLA")

if __name__ == "__main__":
    create_fire_animation("PistolArmature")
    
    # Re-export GLB with animation
    output_path = r'C:\Users\ruley\AppData\Roaming\Godot\app_userdata\BanditandTavious\assets\weapons\A3500X_silver_rigged.glb'
    bpy.ops.export_scene.gltf(filepath=output_path, export_format='GLB', export_apply=True, export_skins=True, export_animations=True)
