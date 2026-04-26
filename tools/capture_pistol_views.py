import bpy
import os

def capture_views(fbx_path, output_dir):
    # 1. Clear scene
    if bpy.context.object and bpy.context.object.mode != 'OBJECT':
        bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()
    
    # 2. Import FBX
    bpy.ops.import_scene.fbx(filepath=fbx_path)
    
    # 3. Setup views
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        
    views = [
        ("front", "FRONT"),
        ("side", "RIGHT"),
        ("top", "TOP")
    ]
    
    # Ensure we are in a 3D view context
    for window in bpy.context.window_manager.windows:
        for area in window.screen.areas:
            if area.type == 'VIEW_3D':
                for region in area.regions:
                    if region.type == 'WINDOW':
                        with bpy.context.temp_override(window=window, screen=window.screen, area=area, region=region):
                            for name, axis in views:
                                # Set view
                                bpy.ops.view3d.view_axis(type=axis)
                                bpy.ops.view3d.view_all(center=True)
                                
                                # Render viewport
                                bpy.context.scene.render.filepath = os.path.join(output_dir, f"{name}.png")
                                bpy.ops.render.opengl(write_still=True)
                                print(f"Captured {name} view to {bpy.context.scene.render.filepath}")
                        return

if __name__ == "__main__":
    fbx_path = r'C:\Users\ruley\AppData\Roaming\Godot\app_userdata\BanditandTavious\assets\weapons\Pistols\A3500X silver.fbx'
    output_dir = r'C:\Users\ruley\AppData\Roaming\Godot\app_userdata\BanditandTavious\.github'
    capture_views(fbx_path, output_dir)
