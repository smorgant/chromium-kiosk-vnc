# Use an official Python image as the base
FROM python:3.10-slim

# Install required packages
RUN apt-get update && apt-get install -y \
    xvfb \
    x11vnc \
    curl \
    wget \
    unzip \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libxcomposite1 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpangocairo-1.0-0 \
    libgtk-3-0 \
    mesa-utils \
    libgl1-mesa-dri \
    libgl1-mesa-glx \
    xserver-xorg-video-dummy \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Playwright
RUN pip install playwright requests flask websockets asyncio

# Install Chromium browser with Playwright
RUN playwright install chromium

# Set working directory
WORKDIR /app

# Copy the Python script into the container
COPY chromium_api.py .
COPY start.sh .
COPY launch_chromium.sh .

RUN chmod +x start.sh chromium_api.py launch_chromium.sh

# Expose VNC port
EXPOSE 5900
EXPOSE 5901

# Set environment variables for software WebGL2
ENV LIBGL_ALWAYS_SOFTWARE=1
ENV MESA_GL_VERSION_OVERRIDE=4.5
ENV MESA_LOADER_DRIVER_OVERRIDE=llvmpipe
ENV DISPLAY=:99

# Set the entrypoint to the start script
ENTRYPOINT ["./start.sh"]
