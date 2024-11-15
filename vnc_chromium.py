import os
import subprocess
import time
from playwright.sync_api import sync_playwright

# Configuration
XVFB_DISPLAY = ":99"
VNC_PORT = 5900
VNC_PASSWORD = os.environ.get("VNC_PASSWORD", None)  # Fetch password from environment
URL = os.environ.get("TARGET_URL", "https://example.com")  # Accept URL from environment variable
default_width = int(os.environ.get("SCREEN_WIDTH", 1920))  # Accept width from environment variable
default_height = int(os.environ.get("SCREEN_HEIGHT", 1080))  # Accept height from environment variable


def start_xvfb(width=1920, height=1080):
    """Start the virtual display (Xvfb)."""
    resolution = f"{width}x{height}x24"  # 24-bit color depth
    print(f"Starting Xvfb with resolution {resolution}...")
    xvfb_cmd = ["Xvfb", XVFB_DISPLAY, "-screen", "0", resolution]
    xvfb_process = subprocess.Popen(xvfb_cmd)
    os.environ["DISPLAY"] = XVFB_DISPLAY
    print(f"Xvfb started on display {XVFB_DISPLAY}.")
    return xvfb_process


def start_vnc_server(width=1920, height=1080):
    """Start the VNC server (x11vnc)."""
    print("Starting VNC server...")
    vnc_cmd = [
        "x11vnc",
        "-display", XVFB_DISPLAY,
        "-rfbport", str(VNC_PORT),
        "-forever",
        "-shared",
        "-geometry", f"{width}x{height}"
    ]
    if VNC_PASSWORD:
        vnc_cmd.extend(["-passwd", VNC_PASSWORD])
    vnc_process = subprocess.Popen(vnc_cmd)
    print(f"VNC server started on port {VNC_PORT} with resolution {width}x{height}.")
    return vnc_process


def launch_chromium(chromium_path, width=1920, height=1080):
    """Launch Chromium in kiosk mode with specified resolution."""
    print(f"Launching Chromium in kiosk mode with resolution {width}x{height}...")
    chromium_cmd = [
        chromium_path,
        "--no-sandbox",
        "--test-type",  # Suppress sandbox warning
        "--disable-gpu",
        f"--window-size={width},{height}",  # Explicitly set window size
        "--window-position=0,0",  # Position the window to the top-left corner
        "--disable-dbus",
        "--no-message-box",
        "--disable-dev-shm-usage",  # Avoid /dev/shm issues in Docker
        "--no-first-run",  # Disable the first-run dialog
        "--no-default-browser-check",  # Skip default browser check
        "--kiosk",  # Enable kiosk mode
        URL,
    ]
    chromium_process = subprocess.Popen(chromium_cmd)
    print("Chromium launched in kiosk mode.")
    return chromium_process


def install_chromium():
    """Use Playwright to install Chromium and return the binary path."""
    with sync_playwright() as p:
        print("Installing Chromium using Playwright...")
        chromium_path = p.chromium.executable_path
        print(f"Chromium installed at: {chromium_path}")
        return chromium_path


def main():
    """Main function to manage the setup."""
    xvfb_process = None
    vnc_process = None
    chromium_process = None

    try:
        # Set dummy Google API keys to suppress warnings
        os.environ["GOOGLE_API_KEY"] = "no"
        os.environ["GOOGLE_DEFAULT_CLIENT_ID"] = "no"
        os.environ["GOOGLE_DEFAULT_CLIENT_SECRET"] = "no"

        # Install Chromium and get its binary path
        chromium_path = install_chromium()

        # Start Xvfb and VNC server
        xvfb_process = start_xvfb(width=default_width, height=default_height)
        time.sleep(2)  # Allow time for Xvfb to initialize
        vnc_process = start_vnc_server(width=default_width, height=default_height)
        time.sleep(2)  # Allow time for VNC server to initialize

        # Launch Chromium using the binary
        chromium_process = launch_chromium(chromium_path, width=default_width, height=default_height)

        # Keep the setup running
        print("Setup is running. Press CTRL+C to exit.")
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("Shutting down...")
    finally:
        # Cleanup processes
        if chromium_process:
            print("Stopping Chromium...")
            chromium_process.terminate()
        if xvfb_process:
            print("Stopping Xvfb...")
            xvfb_process.terminate()
        if vnc_process:
            print("Stopping VNC server...")
            vnc_process.terminate()
        print("Cleanup complete.")


if __name__ == "__main__":
    main()
