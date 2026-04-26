import bpy
import os

def capture_baseline(fbx_path, output_path):
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()
    
    bpy.ops.import_scene.fbx(filepath=fbx_path)
    
    for window in bpy.context.window_manager.windows:
        for area in window.screen.areas:
            if area.type == 'VIEW_3D':
                for region in area.regions:
                    if region.type == 'WINDOW':
                        with bpy.context.temp_override(window=window, screen=window.screen, area=area, region=region):
                            bpy.ops.view3d.view_axis(type='RIGHT')
                            bpy.ops.view3d.view_all(center=True)
                            bpy.context.scene.render.filepath = output_path
                            bpy.ops.render.opengl(write_still=True)
                            print(f"Baseline side view captured to {output_path}")
                        return

if __name__ == "__main__":
    fbx = r'C:\Users\ruley\AppData\Roaming\Godot\app_userdata\BanditandTavious\assets\weapons\A3500X silver.fbx'
    out = r'C:\Users\ruley\AppData\Roaming\Godot\app_userdata\BanditandTavious\.github\baseline_side.png'
    capture_baseline(fbx, out)
