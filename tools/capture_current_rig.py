import bpy
import os

def capture_current_rig(output_path):
    # Ensure we are in a 3D view context
    for window in bpy.context.window_manager.windows:
        for area in window.screen.areas:
            if area.type == 'VIEW_3D':
                # Set shading to Material Preview
                area.spaces.active.shading.type = 'MATERIAL'
                # Show bones in front
                for obj in bpy.data.objects:
                    if obj.type == 'ARMATURE':
                        obj.show_in_front = True
                        obj.data.display_type = 'OCTAHEDRAL'
                
                for region in area.regions:
                    if region.type == 'WINDOW':
                        with bpy.context.temp_override(window=window, screen=window.screen, area=area, region=region):
                            bpy.ops.view3d.view_axis(type='RIGHT')
                            bpy.ops.view3d.view_all(center=True)
                            
                            bpy.context.scene.render.filepath = output_path
                            bpy.ops.render.opengl(write_still=True)
                            print(f"Captured current rig to {output_path}")
                        return

if __name__ == "__main__":
    output_path = r'C:\Users\ruley\AppData\Roaming\Godot\app_userdata\BanditandTavious\.github\current_rig.png'
    capture_current_rig(output_path)
