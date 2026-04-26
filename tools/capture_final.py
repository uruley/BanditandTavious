import bpy
import os

def capture_final(output_path):
    # Set shading to Material for color
    for window in bpy.context.window_manager.windows:
        for area in window.screen.areas:
            if area.type == 'VIEW_3D':
                area.spaces.active.shading.type = 'MATERIAL'
                for region in area.regions:
                    if region.type == 'WINDOW':
                        with bpy.context.temp_override(window=window, screen=window.screen, area=area, region=region):
                            bpy.ops.view3d.view_axis(type='RIGHT')
                            bpy.ops.view3d.view_all(center=True)
                            bpy.context.scene.render.filepath = output_path
                            bpy.ops.render.opengl(write_still=True)
                            return

if __name__ == "__main__":
    out = r'C:\Users\ruley\AppData\Roaming\Godot\app_userdata\BanditandTavious\.github\final_rig_check.png'
    capture_final(out)
