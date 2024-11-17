#!/bin/bash

# Check if TARGET_URL is set, exit if not
if [ -z "$TARGET_URL" ]; then
  echo "Error: TARGET_URL environment variable is required."
  exit 1
fi

# Start the launch_chromium.sh script in the background
./launch_chromium.sh &

# Start the Python API server
python3 -u chromium_api.py
