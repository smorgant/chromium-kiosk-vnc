# Use an official Python image as the base
FROM python:3.10-slim

# Set environment variables for the script
ENV DISPLAY=:99
ENV VNC_PORT=5900
ENV SCREEN_WIDTH=1920
ENV SCREEN_HEIGHT=1080
ENV TARGET_URL=https://example.com

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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Playwright
RUN pip install playwright

# Install Chromium browser with Playwright
RUN playwright install chromium

# Set working directory
WORKDIR /app

# Copy the Python script into the container
COPY vnc_chromium.py .

# Expose VNC port
EXPOSE 5900

# Command to start the script
CMD ["python3", "vnc_chromium.py"]