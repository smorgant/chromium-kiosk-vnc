#!/bin/bash

# Check if TARGET_URL is set, exit if not
if [ -z "$TARGET_URL" ]; then
  echo "Error: TARGET_URL environment variable is required."
  exit 1
fi

# Start the launch_chromium.sh script in the background
./launch_chromium.sh &

# Get Chromium process ID (so we can track it)
CHROMIUM_PID=$!

# Start the Python API server in the background
python3 -u chromium_api.py &
API_PID=$!

# Wait for Chromium to exit
wait $CHROMIUM_PID

echo "Chromium has exited. Stopping the API server..."
kill $API_PID  # Stop Flask API

echo "Exiting container..."
exit 0  # This will allow the container to stop
