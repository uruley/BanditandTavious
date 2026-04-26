import bpy
import bmesh
import os

def create_gun_rack(output_path):
    print("Starting gun rack creation...")
    # 1. Clear scene
    if bpy.context.object and bpy.context.object.mode != 'OBJECT':
        bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()

    # 2. Modeling the Rack
    w, h, d = 1.0, 2.0, 0.4
    thickness = 0.05
    
    # Outer Frame
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, h/2, 0))
    frame = bpy.context.active_object
    frame.name = "GunRack_Frame"
    frame.scale = (w, h, d)
    bpy.ops.object.transform_apply(scale=True)
    
    # Hollow it out
    bm = bmesh.new()
    bm.from_mesh(frame.data)
    # Delete front face
    for f in bm.faces:
        if f.normal.y > 0.9:
            bmesh.ops.delete(bm, geom=[f], context='FACES')
    
    # Simple solidify
    bmesh.ops.solidify(bm, geom=bm.faces, thickness=-thickness)
    bm.to_mesh(frame.data)
    bm.free()

    # Add Shelves
    num_shelves = 4
    for i in range(1, num_shelves):
        z_pos = (h / num_shelves) * i
        bpy.ops.mesh.primitive_cube_add(size=1, location=(0, z_pos, 0))
        shelf = bpy.context.active_object
        shelf.scale = (w - thickness*2, thickness, d - thickness)
        bpy.ops.object.transform_apply(scale=True)
        shelf.name = f"Shelf_{i}"
        shelf.select_set(True)
        frame.select_set(True)
        bpy.context.view_layer.objects.active = frame
        bpy.ops.object.join()

    # 3. Procedural Wood Material (simplified for export)
    mat = bpy.data.materials.new(name="Wood_Procedural")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs['Base Color'].default_value = (0.2, 0.1, 0.05, 1) # Dark Brown
        bsdf.inputs['Roughness'].default_value = 0.8
    frame.data.materials.append(mat)

    # 4. Export
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=output_path, export_format='GLB', export_apply=True)
    print(f"SUCCESS: Gun Rack created at {output_path}")

    # 5. Capture Preview
    for window in bpy.context.window_manager.windows:
        for area in window.screen.areas:
            if area.type == 'VIEW_3D':
                for region in area.regions:
                    if region.type == 'WINDOW':
                        with bpy.context.temp_override(window=window, screen=window.screen, area=area, region=region):
                            bpy.ops.view3d.view_axis(type='FRONT')
                            bpy.ops.view3d.view_all(center=True)
                            bpy.context.scene.render.filepath = r'C:\Users\ruley\AppData\Roaming\Godot\app_userdata\BanditandTavious\.github\gun_rack_preview.png'
                            bpy.ops.render.opengl(write_still=True)
                            print("Preview captured.")
                        return

if __name__ == "__main__":
    pass
