import bpy
import bmesh
import os

def glassify_and_solidify(gltf_path, output_path):
    print("Starting glass and collision setup...")
    
    # 1. Clear scene
    if bpy.context.object and bpy.context.object.mode != 'OBJECT':
        bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()

    # 2. Import
    bpy.ops.import_scene.gltf(filepath=gltf_path)
    
    # 3. Process Meshes
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
    
    for m in meshes:
        bpy.context.view_layer.objects.active = m
        
        # Solidify all for double-sided collision
        bm = bmesh.new()
        bm.from_mesh(m.data)
        bmesh.ops.solidify(bm, geom=bm.faces, thickness=0.02)
        bm.to_mesh(m.data)
        bm.free()
        
        # Rename for Godot collision
        if not m.name.endswith("-col"):
            m.name = f"{m.name}-col"
            
        # 4. Handle Materials (Glass)
        for slot in m.material_slots:
            mat = slot.material
            if mat and "window" in mat.name.lower():
                print(f"Applying Glass properties to: {mat.name}")
                mat.use_nodes = True
                nodes = mat.node_tree.nodes
                bsdf = nodes.get("Principled BSDF")
                
                if bsdf:
                    # Glass Properties
                    bsdf.inputs['Base Color'].default_value = (0.8, 0.9, 1.0, 1.0) # Light blue tint
                    bsdf.inputs['Roughness'].default_value = 0.05                 # Very shiny
                    bsdf.inputs['Alpha'].default_value = 0.3                     # See-through
                    
                # Set blend mode for transparency
                try:
                    mat.blend_method = 'BLEND'
                except:
                    pass
                
                try:
                    mat.shadow_method = 'HASHED'
                except:
                    pass

    # 5. Export
    bpy.ops.export_scene.gltf(filepath=output_path, export_format='GLB', export_apply=True)
    print(f"SUCCESS: Glass windows and collisions added to {output_path}")

if __name__ == "__main__":
    pass
