# Chromium VNC Streaming with Playwright

This project sets up a containerized environment to stream a Chromium browser session over VNC using a headless X server (Xvfb). It uses Playwright to manage Chromium installation and allows you to customize the URL and screen resolution.

## Features

- Streams Chromium browser via VNC
- Kiosk mode for full-screen browser experience
- Configurable URL and screen resolution
- Built with Python and Docker

## Prerequisites

- Docker installed on your system

## Building the Docker Image

Use the provided `Dockerfile` to build the image:

```bash
# Build the Docker image
docker build -t chromium-vnc .
```

## Running the Container

To run the container, pass the desired URL and screen resolution as environment variables:

```bash
# Run the container
docker run -e TARGET_URL="https://example.com" -e SCREEN_WIDTH=1920 -e SCREEN_HEIGHT=1080 -p 5900:5900 chromium-vnc
```

### Environment Variables

- `TARGET_URL`: The URL to load in Chromium (default: `https://example.com`)
- `SCREEN_WIDTH`: The width of the virtual display (default: `1920`)
- `SCREEN_HEIGHT`: The height of the virtual display (default: `1080`)
- `VNC_PORT`: The port for the VNC server (default: `5900`)
- `VNC_PASSWORD`: The password for the VNC server (optional)

## Accessing the VNC Server

Once the container is running, you can connect to the VNC server using a VNC client:

1. Use a VNC viewer (e.g., [TigerVNC](https://tigervnc.org/))
2. Connect to `localhost:5900` or `IPaddress:5900`
3. If you set a password, provide it when prompted

> ⚠️ **Warning**: By default, no password is set for the VNC server. If you expose the VNC server to the internet, it is highly recommended to set a secure password using the `VNC_PASSWORD` environment variable.


## Modifying the Python Script

The main Python script (`pyServer.py`) handles the setup for:

- Starting the X virtual framebuffer (Xvfb)
- Starting the VNC server (x11vnc)
- Launching Chromium in kiosk mode

If you need to make modifications, update the `pyServer.py` file and rebuild the Docker image.

## Troubleshooting

- **Chromium Errors**: Ensure all required libraries are installed in the Docker image. The `Dockerfile` includes dependencies for running Chromium.
- **Connection Refused**: Make sure the VNC server is exposed on the correct port (`5900`) and your firewall allows incoming connections.
- **Resolution Issues**: Ensure the `SCREEN_WIDTH` and `SCREEN_HEIGHT` match your VNC client settings.

## Limitations

- **Google API Warnings**: Some functionalities in Chromium may produce warnings related to missing or invalid Google API keys. Dummy environment variables are set to suppress these warnings, but they do not enable any Google services.
- **No GPU Acceleration**: The setup disables GPU acceleration (`--disable-gpu`), which may result in lower performance for GPU-intensive applications.
- **VNC Responsiveness**: Depending on the resolution and network conditions, the VNC server may not deliver real-time responsiveness for high-resolution streams.
- **Limited Browser Features**: Certain Chromium features like notifications, WebRTC, and other hardware-accelerated components may not function properly in a headless or virtualized environment.

## Example Dockerfile

Below is the `Dockerfile` used to build this project:

```bash
# Use an official Python image as the base
FROM python:3.10-slim

# Set environment variables for the script
ENV DISPLAY=:99
ENV VNC_PORT=5900
ENV SCREEN_WIDTH=1920
ENV SCREEN_HEIGHT=1080
ENV TARGET_URL=https://example.com

# Install required packages
RUN apt-get update && apt-get install -y \\
    xvfb \\
    x11vnc \\
    curl \\
    wget \\
    unzip \\
    libnss3 \\
    libatk1.0-0 \\
    libatk-bridge2.0-0 \\
    libcups2 \\
    libxcomposite1 \\
    libxrandr2 \\
    libgbm1 \\
    libasound2 \\
    libpangocairo-1.0-0 \\
    libgtk-3-0 \\
    && apt-get clean \\
    && rm -rf /var/lib/apt/lists/*

# Install Playwright
RUN pip install playwright

# Install Chromium browser with Playwright
RUN playwright install chromium

# Set working directory
WORKDIR /app

# Copy the Python script into the container
COPY pyServer.py .

# Expose VNC port
EXPOSE 5900

# Command to start the script
CMD ["python3", "pyServer.py"]
```

## Credits

This project uses:

- [Playwright](https://playwright.dev/) for managing Chromium
- [x11vnc](https://github.com/LibVNC/x11vnc) for VNC server
- [Xvfb](https://www.x.org/releases/X11R7.6/doc/man/man1/Xvfb.1.xhtml) for virtual framebuffer
