import bpy
import json

def analyze_house(gltf_path):
    if bpy.context.object and bpy.context.object.mode != 'OBJECT':
        bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()

    bpy.ops.import_scene.gltf(filepath=gltf_path)
    
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
    
    analysis = []
    for m in meshes:
        materials = [mat.name for mat in m.data.materials if mat]
        analysis.append({
            "name": m.name,
            "vertices": len(m.data.vertices),
            "polygons": len(m.data.polygons),
            "materials": materials
        })
        
    print(json.dumps(analysis, indent=2))

if __name__ == "__main__":
    pass
