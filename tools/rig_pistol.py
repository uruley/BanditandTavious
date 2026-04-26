import bpy
import mathutils
import json
import os

def create_material(name, texture_dir, prefix):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    
    # Clear nodes
    for n in nodes: nodes.remove(n)
    
    # Create Principled BSDF
    node_bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    node_bsdf.location = (0, 0)
    
    # Create Material Output
    node_output = nodes.new(type='ShaderNodeOutputMaterial')
    node_output.location = (400, 0)
    links.new(node_bsdf.outputs['BSDF'], node_output.inputs['Surface'])
    
    def add_texture(file_name, socket_name, colorspace='Color'):
        path = os.path.join(texture_dir, file_name)
        if os.path.exists(path):
            tex = nodes.new(type='ShaderNodeTexImage')
            tex.image = bpy.data.images.load(path)
            tex.image.colorspace_settings.name = colorspace
            
            if socket_name == 'Normal':
                normal_map = nodes.new(type='ShaderNodeNormalMap')
                links.new(tex.outputs['Color'], normal_map.inputs['Color'])
                links.new(normal_map.outputs['Normal'], node_bsdf.inputs['Normal'])
            else:
                links.new(tex.outputs['Color'], node_bsdf.inputs[socket_name])
            return tex
        return None

    # Add specific maps
    add_texture(f"{prefix}_Base color.png", 'Base Color', 'sRGB')
    add_texture(f"{prefix}_Metallic.png", 'Metallic', 'Non-Color')
    add_texture(f"{prefix}_Roughness.png", 'Roughness', 'Non-Color')
    add_texture(f"{prefix}_Normal map.png", 'Normal', 'Non-Color')
    
    return mat

def rig_pistol(fbx_path, output_path, silver_tex_dir, mag_tex_dir):
    print(f"Starting TEXTURED RIGGING for: {fbx_path}")
    
    if bpy.context.object and bpy.context.object.mode != 'OBJECT':
        bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()
    
    bpy.ops.import_scene.fbx(filepath=fbx_path)
    imported_objs = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
    
    # Create Materials
    mat_silver = create_material("Mat_Silver", silver_tex_dir, "A3500X_silver")
    mat_mag = create_material("Mat_Magazine", mag_tex_dir, "magazine")

    # Scale and Rotate
    scale_factor = 0.2 / 4.36
    for obj in imported_objs:
        obj.scale = (scale_factor, scale_factor, scale_factor)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.transform_apply(scale=True, location=True, rotation=True)
        obj.rotation_euler[0] = -1.5708
        bpy.ops.object.transform_apply(rotation=True)
        
        # Assign Materials
        if "mag" in obj.name.lower() or "bullet" in obj.name.lower():
            obj.data.materials.clear()
            obj.data.materials.append(mat_mag)
        else:
            obj.data.materials.clear()
            obj.data.materials.append(mat_silver)

    # 4. Create Armature
    bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
    arm = bpy.context.view_layer.objects.active
    arm.name = "PistolArmature"
    eb = arm.data.edit_bones
    if "Bone" in eb: eb.remove(eb["Bone"])
        
    # 5. Add Bones
    def to_godot(old_pos):
        x, y, z = [v * scale_factor for v in old_pos]
        vec = mathutils.Vector((x, y, z))
        rot = mathutils.Matrix.Rotation(-1.5708, 4, 'X')
        return rot @ vec

    eb.new("Body").head, eb["Body"].tail = to_godot([0,0,0]), to_godot([0,0,10])
    eb.new("Slide").head, eb["Slide"].tail = to_godot([0, 1.86, 1.06]), to_godot([0, -2.17, 1.06])
    eb["Slide"].parent = eb["Body"]
    eb.new("Trigger").head, eb["Trigger"].tail = to_godot([0, 0.20, 0.87]), to_godot([0, 0.20, 0.08])
    eb["Trigger"].parent = eb["Body"]
    eb.new("Magazine").head, eb["Magazine"].tail = to_godot([0, 1.32, 0.98]), to_godot([0, 1.32, -1.49])
    eb["Magazine"].parent = eb["Body"]
    eb.new("Muzzle").head, eb["Muzzle"].tail = to_godot([0, -2.17, 1.06]), to_godot([0, -2.20, 1.06])
    eb["Muzzle"].parent = eb["Body"]

    bpy.ops.object.mode_set(mode='OBJECT')

    # 6. Parenting
    mapping = {"slid_low": "Slide", "trigger_low": "Trigger", "magzinebody_low": "Magazine", "magazinecover_low": "Magazine"}
    for obj in imported_objs:
        bone_name = "Body"
        for key in mapping:
            if key in obj.name.lower():
                bone_name = mapping[key]
                break
        
        bpy.ops.object.select_all(action='DESELECT')
        obj.select_set(True)
        arm.select_set(True)
        bpy.context.view_layer.objects.active = arm
        bpy.ops.object.mode_set(mode='POSE')
        arm.data.bones.active = arm.data.bones[bone_name]
        bpy.ops.object.parent_set(type='BONE')
        bpy.ops.object.mode_set(mode='OBJECT')

    # 7. Export
    bpy.ops.export_scene.gltf(filepath=output_path, export_format='GLB', export_apply=True, export_skins=True)
    print(f"SUCCESS: {output_path}")

if __name__ == "__main__":
    pass
