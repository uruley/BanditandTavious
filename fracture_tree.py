import sys
import os
sys.path.append("tools")
from blender_query import blender_command

# 1. Clean scene
blender_command("execute_code", {"code": "import bpy; bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete()"})

# 2. Import tree
project_root = os.getcwd()
asset_path = os.path.join(project_root, "assets", "Environment", "Nature", "Trees", "island_tree_02_2k.gltf")
output_path = os.path.join(project_root, "assets", "models", "island_tree_02_fractured.glb")

code = f"""
import bpy
import os
import json

def run():
    # Setup paths
    asset_path = r'{asset_path}'
    output_path = r'{output_path}'
    
    # Import
    bpy.ops.import_scene.gltf(filepath=asset_path)
    
    # Find the tree mesh
    obj = None
    for o in bpy.context.scene.objects:
        if o.type == 'MESH':
            obj = o
            break
            
    if not obj:
        return {{"status": "error", "message": "Tree mesh not found"}}
    
    # Decimate if too high poly for cell fracture? 874k is huge.
    # Actually, let's try to decimate it first to make it stable.
    bpy.context.view_layer.objects.active = obj
    decimate = obj.modifiers.new(name="Decimate", type='DECIMATE')
    decimate.ratio = 0.05 # 5% of vertices
    bpy.ops.object.modifier_apply(modifier="Decimate")
    
    print(f"Decimated mesh to {{len(obj.data.vertices)}} vertices")

    # Materials
    if len(obj.data.materials) == 0:
        mat = bpy.data.materials.new(name="TreeMat")
        obj.data.materials.append(mat)
    
    # Interior material (slot 2)
    int_mat = bpy.data.materials.new(name="TreeInterior")
    int_mat.use_nodes = True
    int_mat.node_tree.nodes["Principled BSDF"].inputs[0].default_value = (0.3, 0.2, 0.1, 1) # Wood brown
    obj.data.materials.append(int_mat)

    # Cell Fracture
    try:
        bpy.ops.preferences.addon_enable(module="bl_ext.blender_org.cell_fracture")
    except:
        try:
            bpy.ops.preferences.addon_enable(module="object_fracture_cell")
        except:
            pass
        
    collection_name = "FracturedTree"
    coll = bpy.data.collections.new(collection_name)
    bpy.context.scene.collection.children.link(coll)
    
    bpy.ops.object.add_fracture_cell_objects(
        source_limit=20, 
        source_noise=0.1, 
        use_debug_points=False,
        use_interior_vgroup=True,
        use_recenter=True,
        material_index=1,
        collection_name=collection_name
    )
    
    # Process shards
    shards = [o for o in coll.objects if o != obj]
    for i, s in enumerate(shards):
        bpy.context.view_layer.objects.active = s
        bpy.ops.object.origin_set(type='ORIGIN_CENTER_OF_MASS', center='BOUNDS')
        s.name = f"tree_shard_{{i}}-rigid"
        if s.data: s.data.name = s.name
        
    # Export shards
    bpy.ops.object.select_all(action='DESELECT')
    for s in shards:
        s.select_set(True)
        
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=output_path,
        export_format='GLB',
        use_selection=True,
        export_apply=True
    )
    
    return {{"status": "success", "shards": len(shards), "output": output_path}}

print(json.dumps(run()))
"""

result = blender_command("execute_code", {"code": code})
if result.get("status") == "success":
    print(result["result"]["result"])
else:
    print(f"Error: {result.get('message', 'Unknown error')}")
