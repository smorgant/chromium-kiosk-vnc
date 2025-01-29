#!/bin/bash

# Configuration
XVFB_DISPLAY=":99"
VNC_PORT=${VNC_PORT:-5900}
SCREEN_WIDTH=${SCREEN_WIDTH:-1920}
SCREEN_HEIGHT=${SCREEN_HEIGHT:-1080}
TARGET_URL=${TARGET_URL:-"https://www.example.com"}
VNC_PASSWORD=${VNC_PASSWORD:-""}
CHROMIUM_PATH="/root/.cache/ms-playwright/chromium-*/chrome-linux/chrome"  # Path for Playwright-installed Chromium

# Start Xvfb
resolution="${SCREEN_WIDTH}x${SCREEN_HEIGHT}x24"  # 24-bit color depth
echo "Starting Xvfb with resolution $resolution..."
Xvfb $XVFB_DISPLAY -screen 0 $resolution &
XVFB_PID=$!
export DISPLAY=$XVFB_DISPLAY
echo "Xvfb started on display $XVFB_DISPLAY."

# Wait until Xvfb is fully ready
echo "Waiting for Xvfb to initialize..."
for i in {1..10}; do
    if xdpyinfo -display $XVFB_DISPLAY >/dev/null 2>&1; then
        echo "Xvfb is ready!"
        break
    fi
    echo "Xvfb not ready, retrying in 1 second..."
    sleep 1
done

# Start VNC server (optional)
echo "Starting VNC server..."
if [ -n "$VNC_PASSWORD" ]; then
    x11vnc -display $XVFB_DISPLAY -rfbport $VNC_PORT -forever -shared -geometry ${SCREEN_WIDTH}x${SCREEN_HEIGHT} -passwd $VNC_PASSWORD -nopw &
else
    x11vnc -display $XVFB_DISPLAY -rfbport $VNC_PORT -forever -shared -geometry ${SCREEN_WIDTH}x${SCREEN_HEIGHT} -nopw &
fi
VNC_PID=$!
echo "VNC server started on port $VNC_PORT with resolution ${SCREEN_WIDTH}x${SCREEN_HEIGHT}."

# Start Chromium in kiosk mode
echo "Launching Chromium in kiosk mode with URL: $TARGET_URL"
$CHROMIUM_PATH --no-sandbox --test-type --disable-gpu --disable-software-rasterizer \
  --window-size=${SCREEN_WIDTH},${SCREEN_HEIGHT} --window-position=0,0 \
  --disable-dbus --disable-features=AudioServiceOutOfProcess \
  --no-message-box --disable-dev-shm-usage \
  --no-first-run --no-default-browser-check --remote-debugging-port=9222 \
  --kiosk "$TARGET_URL" &
CHROMIUM_PID=$!

# Wait for Chromium to exit
wait $CHROMIUM_PID

# Cleanup
echo "Stopping Xvfb..."
kill $XVFB_PID

echo "Stopping VNC server..."
kill $VNC_PID

echo "Cleanup complete."
