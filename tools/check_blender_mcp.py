import asyncio
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client
import json

async def list_blender_tools():
    # If the server is on a port, it might be a websocket or HTTP server.
    # But usually MCP clients use stdio or SSE.
    # The user says "port number", which often means websocket or SSE.
    # Let's try to find if there's a specific way to connect to a port.
    print("Trying to connect to Blender MCP on port 9876...")
    # This is a placeholder. If it's a websocket server, we need a websocket client.
    # Let's assume it's an SSE server for now or check if there's a tool.
    pass

if __name__ == "__main__":
    # asyncio.run(list_blender_tools())
    print("Script ready to connect to port 9876. Need to confirm the protocol (SSE/Websocket).")
