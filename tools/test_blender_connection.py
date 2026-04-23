import socket
import json
import time

def blender_command(cmd_type, params=None, host='localhost', port=9876):
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.settimeout(5.0)
            s.connect((host, port))
            
            payload = {
                "type": cmd_type,
                "params": params or {}
            }
            print(f"Sending: {json.dumps(payload)}")
            s.sendall(json.dumps(payload).encode('utf-8'))
            
            # Read response
            data = s.recv(4096)
            if not data:
                return {"status": "error", "message": "No data received"}
            
            resp = json.loads(data.decode('utf-8'))
            return resp
    except Exception as e:
        return {"status": "error", "message": str(e)}

if __name__ == "__main__":
    # Test connection by getting Blender version via execute_blender_code
    # According to the web_fetch, there is an 'execute_blender_code' tool
    # But wait, the ADDON might use different keys.
    # Let's try a simple ping or execute_code
    test_code = """
import bpy
import json
# Get operator info
try:
    info = bpy.ops.object.add_fracture_cell_objects.get_rna_type().properties.keys()
    print(json.dumps(list(info)))
except Exception as e:
    print(json.dumps({"error": str(e)}))
"""
    result = blender_command("execute_code", {"code": test_code})
    print(f"Result: {json.dumps(result, indent=2)}")
