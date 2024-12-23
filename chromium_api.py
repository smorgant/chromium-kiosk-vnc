import os
import subprocess
import time
import requests
import json
import logging
import asyncio
import websockets
from flask import Flask, request, jsonify

# Configure logging
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s %(levelname)s: %(message)s')

app = Flask(__name__)

# Configuration
CHROMIUM_DEBUGGING_URL = "http://localhost:9222/json"
VNC_PORT = os.environ.get("VNC_PORT", 5900)
API_PORT = VNC_PORT + 1

async def send_cdp_command(websocket_url, command_id, method, params):
    try:
        async with websockets.connect(websocket_url) as websocket:
            message = {
                "id": command_id,
                "method": method,
                "params": params
            }
            logging.debug(f"Sending CDP command: {json.dumps(message)}")
            await websocket.send(json.dumps(message))
            response = await websocket.recv()
            logging.debug(f"Received response: {response}")
            return response
    except Exception as e:
        logging.error(f"Failed to send CDP command: {e}")
        raise

@app.route('/change_url', methods=['POST'])
def change_url():
    data = request.get_json()
    new_url = data.get("url")
    if not new_url:
        logging.error("No URL provided in request.")
        return jsonify({"error": "No URL provided."}), 400

    # Fetch the list of open pages (tabs) from Chromium
    try:
        response = requests.get(CHROMIUM_DEBUGGING_URL)
        response.raise_for_status()
        tabs = response.json()
        logging.debug(f"Retrieved tabs: {tabs}")
    except requests.RequestException as e:
        logging.error(f"Could not connect to Chromium: {e}")
        return jsonify({"error": "Could not connect to Chromium.", "details": str(e)}), 500

    # Use the first available tab
    if len(tabs) == 0:
        logging.error("No open tabs found in Chromium.")
        return jsonify({"error": "No open tabs found."}), 404

    tab = tabs[0]
    websocket_url = tab.get('webSocketDebuggerUrl')
    if not websocket_url:
        logging.error("No WebSocket debugger URL found for the tab.")
        return jsonify({"error": "No WebSocket debugger URL found."}), 500

    # Send a command to navigate to the new URL using WebSocket
    try:
        asyncio.run(send_cdp_command(websocket_url, 1, "Page.navigate", {"url": new_url}))
    except Exception as e:
        logging.error(f"Failed to send command to Chromium: {e}")
        return jsonify({"error": "Failed to send command to Chromium.", "details": str(e)}), 500

    logging.info(f"URL successfully changed to {new_url}")
    return jsonify({"message": f"URL changed to {new_url}"}), 200

@app.route('/reload_page', methods=['POST'])
def reload_page():
    # Fetch the list of open pages (tabs) from Chromium
    try:
        response = requests.get(CHROMIUM_DEBUGGING_URL)
        response.raise_for_status()
        tabs = response.json()
        logging.debug(f"Retrieved tabs: {tabs}")
    except requests.RequestException as e:
        logging.error(f"Could not connect to Chromium: {e}")
        return jsonify({"error": "Could not connect to Chromium.", "details": str(e)}), 500

    # Use the first available tab
    if len(tabs) == 0:
        logging.error("No open tabs found in Chromium.")
        return jsonify({"error": "No open tabs found."}), 404

    tab = tabs[0]
    websocket_url = tab.get('webSocketDebuggerUrl')
    if not websocket_url:
        logging.error("No WebSocket debugger URL found for the tab.")
        return jsonify({"error": "No WebSocket debugger URL found."}), 500

    # Send a command to reload the page using WebSocket
    try:
        asyncio.run(send_cdp_command(websocket_url, 2, "Page.reload", {}))
    except Exception as e:
        logging.error(f"Failed to send command to Chromium: {e}")
        return jsonify({"error": "Failed to send command to Chromium.", "details": str(e)}), 500

    logging.info("Page successfully reloaded")
    return jsonify({"message": "Page reloaded successfully"}), 200

if __name__ == "__main__":
    logging.info("Starting Flask server for Chromium control API...")
    app.run(host="0.0.0.0", port=API_PORT)
