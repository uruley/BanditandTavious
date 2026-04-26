import socket
import json
import os

def blender_command(cmd_type, params=None, host='localhost', port=9876):
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.settimeout(30.0) # Longer timeout for heavy ops
            s.connect((host, port))
            payload = {"type": cmd_type, "params": params or {}}
            s.sendall(json.dumps(payload).encode('utf-8'))
            
            # Read until close or full JSON
            buffer = b""
            while True:
                data = s.recv(4096)
                if not data: break
                buffer += data
                try:
                    return json.loads(buffer.decode('utf-8'))
                except:
                    continue
            return json.loads(buffer.decode('utf-8'))
    except Exception as e:
        return {"status": "error", "message": str(e)}

def fracture_object(obj_name, shard_count=10, output_path="res://assets/fractured.glb"):
    # Convert res:// to absolute path and use forward slashes
    abs_output = output_path.replace("res://", os.getcwd().replace("\\", "/") + "/")
    
    code = f"""
import bpy
import os

def setup_materials(obj):
    # Create Exterior Material
    if "ExteriorMat" not in bpy.data.materials:
        ext_mat = bpy.data.materials.new(name="ExteriorMat")
        ext_mat.use_nodes = True
        nodes = ext_mat.node_tree.nodes
        nodes["Principled BSDF"].inputs[0].default_value = (0.5, 0.5, 0.5, 1) # Gray
    else:
        ext_mat = bpy.data.materials["ExteriorMat"]

    # Create Interior Material (e.g., darker or rougher)
    if "InteriorMat" not in bpy.data.materials:
        int_mat = bpy.data.materials.new(name="InteriorMat")
        int_mat.use_nodes = True
        nodes = int_mat.node_tree.nodes
        nodes["Principled BSDF"].inputs[0].default_value = (0.2, 0.1, 0.05, 1) # Dark Brown/Stone
    else:
        int_mat = bpy.data.materials["InteriorMat"]

    # Assign to slots
    if len(obj.data.materials) == 0:
        obj.data.materials.append(ext_mat)
    if len(obj.data.materials) == 1:
        obj.data.materials.append(int_mat)
    else:
        obj.data.materials[1] = int_mat

def run():
    # 1. Enable addon
    try:
        bpy.ops.preferences.addon_enable(module="bl_ext.blender_org.cell_fracture")
    except:
        bpy.ops.preferences.addon_enable(module="object_fracture_cell")
    
    obj = bpy.data.objects.get("{obj_name}")
    if not obj:
        return {{"status": "error", "message": "Object not found: {obj_name}"}}
    
    # Ensure object is visible and enabled
    obj.hide_viewport = False
    obj.hide_render = False
    obj.hide_set(False)
    
    # 2. Setup Materials
    setup_materials(obj)
    
    # Select object
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    
    # 3. Cell Fracture
    collection_name = "Fractured"
    # Clear collection if it exists
    coll = bpy.data.collections.get(collection_name)
    if coll:
        for o in coll.objects:
            bpy.data.objects.remove(o, do_unlink=True)
    else:
        coll = bpy.data.collections.new(collection_name)
        bpy.context.scene.collection.children.link(coll)

    try:
        bpy.ops.object.add_fracture_cell_objects(
            source_limit={shard_count}, 
            source_noise=0.1, 
            use_debug_points=False,
            use_interior_vgroup=True,
            use_recenter=True,
            material_index=1, # Uses the second material slot for inner faces
            collection_name=collection_name
        )
    except Exception as e:
         return {{"status": "error", "message": f"Cell fracture failed: {{e}}"}}

    # 4. Find shards in the collection, rename, and fix origins
    fractured_coll = bpy.data.collections.get(collection_name)
    if not fractured_coll:
         return {{"status": "error", "message": "Fractured collection not found"}}

    shards = [o for o in fractured_coll.objects if o != obj]
    print(f"!!! FOUND {{len(shards)}} SHARDS IN {{collection_name}}")
    for i, s in enumerate(shards):
        bpy.context.view_layer.objects.active = s
        bpy.ops.object.origin_set(type='ORIGIN_CENTER_OF_MASS', center='BOUNDS')
        old_name = s.name
        new_name = f"{{obj.name}}_shard_{{i}}-rigid"
        s.name = new_name
        if s.data:
            s.data.name = new_name
        print(f"!!! RENAMED {{old_name}} -> {{s.name}} (Data: {{s.data.name if s.data else 'None'}})")
    
    obj.hide_viewport = True
    obj.hide_render = True
    bpy.context.view_layer.update()

    # 5. Export
    bpy.ops.object.select_all(action='DESELECT')
    final_shards = [o for o in fractured_coll.objects if o != obj]
    for s in final_shards:
        s.select_set(True)
        print(f"!!! SELECTING FOR EXPORT: {{s.name}}")

    output_dir = os.path.dirname("{abs_output}")
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    try:
        bpy.ops.export_scene.gltf(
            filepath="{abs_output}",
            export_format='GLB',
            use_selection=True,
            export_apply=True
        )
    except Exception as e:
        return {{"status": "error", "message": f"GLTF export failed: {{e}}"}}

    return {{"status": "success", "shards": len(shards), "output": "{abs_output}"}}


import json
print(json.dumps(run()))
"""
    return blender_command("execute_code", {"code": code})

def create_wall(name="Wall"):
    code = f"""
import bpy
def run():
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0,0,1))
    obj = bpy.context.active_object
    obj.name = "{name}"
    obj.scale = (3.0, 0.5, 2.0) # Wide, thin wall
    bpy.ops.object.transform_apply(scale=True)
    return {{"status": "success", "name": obj.name}}

import json
print(json.dumps(run()))
"""
    return blender_command("execute_code", {"code": code})

def get_info():
    code = """
import bpy
def run():
    return {
        "status": "success", 
        "objects": [o.name for o in bpy.data.objects],
        "collections": [c.name for c in bpy.data.collections]
    }

import json
print(json.dumps(run()))
"""
    return blender_command("execute_code", {"code": code})

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "setup":
        print(json.dumps(create_wall(), indent=2))
    elif len(sys.argv) > 1 and sys.argv[1] == "info":
        print(json.dumps(get_info(), indent=2))
    else:
        name = sys.argv[1] if len(sys.argv) > 1 else "Cube"
        count = int(sys.argv[2]) if len(sys.argv) > 2 else 10
        path = sys.argv[3] if len(sys.argv) > 3 else "res://assets/fractured_cube.glb"
        
        res = fracture_object(name, count, path)
        print(json.dumps(res, indent=2))
