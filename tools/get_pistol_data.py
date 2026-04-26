import bpy
import json
import mathutils

def get_bb(name):
    obj = bpy.data.objects.get(name)
    if not obj:
        return None
    # Get world space bounding box
    bb = [obj.matrix_world @ mathutils.Vector(v) for v in obj.bound_box]
    center = sum(bb, mathutils.Vector()) / 8
    # Calculate min and max
    min_v = mathutils.Vector((min(v[0] for v in bb), min(v[1] for v in bb), min(v[2] for v in bb)))
    max_v = mathutils.Vector((max(v[0] for v in bb), max(v[1] for v in bb), max(v[2] for v in bb)))
    return {
        'center': list(center),
        'min': list(min_v),
        'max': list(max_v),
        'size': list(max_v - min_v)
    }

data = {
    'slide': get_bb('slid_low'),
    'trigger': get_bb('trigger_low'),
    'mag': get_bb('magzinebody_low'),
    'frame': get_bb('frame_low')
}
print(json.dumps(data))
