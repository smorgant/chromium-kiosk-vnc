#!/bin/bash

# Configuration
XVFB_DISPLAY=":99"
VNC_PORT=${VNC_PORT:-5900}
SCREEN_WIDTH=${SCREEN_WIDTH:-1920}
SCREEN_HEIGHT=${SCREEN_HEIGHT:-1080}
TARGET_URL=${TARGET_URL:-"https://www.example.com"}
VNC_PASSWORD=${VNC_PASSWORD:-""}
CHROMIUM_PATH="/root/.cache/ms-playwright/chromium-*/chrome-linux/chrome"  # Path for Playwright-installed Chromium

# Set environment variables to force software WebGL2 rendering
export LIBGL_ALWAYS_SOFTWARE=1
export MESA_GL_VERSION_OVERRIDE=4.5
export MESA_LOADER_DRIVER_OVERRIDE=llvmpipe

# Start Xvfb
resolution="${SCREEN_WIDTH}x${SCREEN_HEIGHT}x24"  # 24-bit color depth
echo "Starting Xvfb with resolution $resolution..."
Xvfb $XVFB_DISPLAY -screen 0 $resolution +extension GLX +render -noreset &
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

# Start VNC server
echo "Starting VNC server..."
if [ -n "$VNC_PASSWORD" ]; then
    x11vnc -display $XVFB_DISPLAY -rfbport $VNC_PORT -forever -shared -geometry ${SCREEN_WIDTH}x${SCREEN_HEIGHT} -passwd $VNC_PASSWORD -nopw &
else
    x11vnc -display $XVFB_DISPLAY -rfbport $VNC_PORT -forever -shared -geometry ${SCREEN_WIDTH}x${SCREEN_HEIGHT} -nopw &
fi
VNC_PID=$!
echo "VNC server started on port $VNC_PORT with resolution ${SCREEN_WIDTH}x${SCREEN_HEIGHT}."

# Start Chromium with WebGL2 in kiosk mode
echo "Launching Chromium in kiosk mode with WebGL2: $TARGET_URL"
$CHROMIUM_PATH --no-sandbox --test-type \
  --window-size=${SCREEN_WIDTH},${SCREEN_HEIGHT} --window-position=0,0 \
  --disable-dev-shm-usage \
  --use-gl=swiftshader \
  --enable-unsafe-swiftshader \
  --enable-gpu-rasterization \
  --enable-oop-rasterization \
  --enable-webgl \
  --ignore-gpu-blocklist \
  --enable-features=VaapiVideoDecoder,WebGLDraftExtensions,WebGL2ComputeContext \
  --enable-unsafe-webgpu \
  --enable-webgl2-compute-context \
  --enable-zero-copy \
  --no-message-box \
  --no-first-run --no-default-browser-check --remote-debugging-port=9222 \
  --kiosk "$TARGET_URL" &
CHROMIUM_PID=$!


# Wait for Chromium to exit
wait $CHROMIUM_PID

# Cleanup
echo "Stopping Xvfb..."
kill $XVFB_PID

echo "Stopping VNC server..."
if pgrep -x "x11vnc" > /dev/null; then
     kill $VNC_PID
fi

echo "Cleanup complete."

# Stop the Docker container
echo "Chromium has exited. Stopping container..."
exit 0
