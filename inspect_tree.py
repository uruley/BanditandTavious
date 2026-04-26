import sys
import os
sys.path.append("tools")
from blender_query import blender_command

# Clear scene first
blender_command("execute_code", {"code": "import bpy; bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete()"})

# Absolute path for blender
project_root = os.getcwd()
asset_path = os.path.join(project_root, "assets", "Environment", "Nature", "Trees", "island_tree_02_2k.gltf")

code = f"""
import bpy
import os

try:
    bpy.ops.import_scene.gltf(filepath=r'{asset_path}')
    objs = [obj.name for obj in bpy.context.scene.objects]
    print(f"OBJECTS:{{objs}}")
    
    # Get mesh info
    for obj in bpy.context.scene.objects:
        if obj.type == 'MESH':
            print(f"MESH:{{obj.name}} verts:{{len(obj.data.vertices)}}")
except Exception as e:
    print(f"ERROR:{{str(e)}}")
"""

result = blender_command("execute_code", {"code": code})
if result.get("status") == "success":
    print(result["result"]["result"])
else:
    print(f"Error: {result.get('message', 'Unknown error')}")
