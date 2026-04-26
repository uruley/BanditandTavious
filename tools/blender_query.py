import socket
import json
import sys

def blender_command(cmd_type, params=None, host='localhost', port=9876):
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.settimeout(120.0) # 2 minutes
            s.connect((host, port))
            
            payload = {
                "type": cmd_type,
                "params": params or {}
            }
            s.sendall(json.dumps(payload).encode('utf-8'))
            
            # Read response (might need more than 4096 for large data)
            response_data = b""
            while True:
                chunk = s.recv(4096)
                if not chunk:
                    break
                response_data += chunk
                if len(chunk) < 4096:
                    break
            
            if not response_data:
                return {"status": "error", "message": "No data received"}
            
            resp = json.loads(response_data.decode('utf-8'))
            return resp
    except Exception as e:
        return {"status": "error", "message": str(e)}

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python blender_query.py 'python_code_here'")
        sys.exit(1)
        
    code = sys.argv[1]
    result = blender_command("execute_code", {"code": code})
    if result.get("status") == "success":
        print(result["result"]["result"])
    else:
        print(f"Error: {result.get('message', 'Unknown error')}")
