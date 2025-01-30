# Chromium-Controlled Docker Container
This project provides a Docker container that runs a Chromium browser controlled via a Python-based API server. The container uses Playwright to download and set up Chromium, while leveraging the Chrome DevTools Protocol (CDP) via WebSocket to manage and control the browser through the API. Additionally, the container includes a VNC server for visual interaction with the browser.


## Table of Contents
- [Latest Additions](#latest-additions)
- [Features](#features)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Running the Container](#running-the-container)
- [API Documentation](#api-documentation)
  - [/change_url](#change_url)
  - [/reload_page](#reload_page)
  - [/clear_cache](#clear_cache)
  - [/shutdown](#shutdown)
- [Security Considerations](#security-considerations)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Latest Additions
- **Support for WebGL2**: Leverage mesa to support GPU acceleration via CPU acceleration- This can generate high cpu requirement VM will need to be sized appropriateley in this context
- **Shutdown Endpoint**: Added a new endpoint to shutdown the docker container / shutdown

## Features
- **Chromium Browser Control**: Uses Playwright to download Chromium and Chrome DevTools Protocol (CDP) to manage and control the browser via WebSocket.
- **API Server**: Flask-based server with endpoints to control the browser via CDP, such as changing URLs and reloading pages.
- **VNC Server**: Includes an X11 virtual framebuffer (Xvfb) and VNC server for visualizing and remotely accessing the Chromium browser.

## Project Structure
- `Dockerfile`: Instructions for building the Docker image, including installation of dependencies.
- `chromium_api.py`: Flask API server used to control Chromium.
- `launch_chromium.sh`: Shell script that starts Xvfb, VNC server, and Chromium.
- `start.sh`: Script to run both `launch_chromium.sh` and `chromium_api.py`.

## Getting Started

### Prerequisites
- Docker must be installed and running on your machine.
- No additional software is required, as everything else runs inside the container.

### Installation
Clone the repository to your local machine:

```
git clone <repository_url>
cd <repository_name>
```

### Running the Container
To build the Docker image and run the container, use the following commands:

```
docker build -t chromium-controller .
docker run -p 5900:5900 -p 5901:5901 -e TARGET_URL=https://www.example.com chromium-controller
```

- **Port 5900**: Used for VNC access.
- **Port 5901**: Used for the Flask API server.

### Required and Optional Parameters for Running the Container

- **Required Parameter**:
  - `TARGET_URL`: The URL that Chromium should navigate to. This must be passed when starting the container.

- **Non-Mandatory Parameters**:
  - `VNC_PORT`: Port for the VNC server. Defaults to `5900` if not specified.
  - `SCREEN_WIDTH`: Width of the virtual screen. Defaults to `1920` if not specified.
  - `SCREEN_HEIGHT`: Height of the virtual screen. Defaults to `1080` if not specified.
  - `VNC_PASSWORD`: Password for VNC access. By default, no password is set, but it is recommended for security purposes.

## API Documentation

### /change_url
**Endpoint**: `/change_url`  
**Method**: `POST`  
**Description**: Changes the current URL in the Chromium browser.

**Request Headers**:
- `Content-Type`: Must be set to `application/json`

**Request Body** (JSON):

```
{
  "url": "<new_url>"
}
```

**Response**:
- Success: Returns a status `200 OK` with a message indicating that the URL has been changed.
- Failure: Returns a status `400` if no URL is provided, or `500` if there is an error communicating with Chromium.

### /reload_page
**Endpoint**: `/reload_page`  
**Method**: `POST`  
**Description**: Reloads the current page in the Chromium browser.

**Response**:
- Success: Returns a status `200 OK` with a message "Page reloaded successfully" indicating that the page was reloaded.
- Failure: Returns a status `404` if no open tabs are found, or `500` if there is an error communicating with Chromium.


### /clear_cache
**Endpoint**: `/clear_cache`  
**Method**: `POST`  
**Description**: Clear the browser cache and cookies

**Response**:
- Success: Returns a status `200 OK` with a message "Browser cache and cookies cleared successfully" indicating that the cache and cookies are cleared.
- Failure: Returns a status `404` if no open tabs are found, or `500` if there is an error communicating with Chromium.


### /shutdown
**Endpoint**: `/shutdown`  
**Method**: `POST`  
**Description**: Shutdown the chromium instance and kill the container

**Response**:
- Success: Returns a status `200 OK` with a message "Chromium stopped successfully. The container will exit automatically." indicating that the chrome instance has been stopped and the container will follow.
- Failure: Returns a status `500` if there is an error stopping the process.


## Security Considerations

- **Environment Variables**: Avoid hardcoding sensitive values (e.g., credentials) in the Dockerfile or scripts. Instead, pass sensitive values through environment variables using `docker run -e` options.
- **VNC Password**: By default, the VNC server runs without a password, which is insecure in a public environment. Consider setting a VNC password by passing the VNC_PASSWORD environment variable.
- **API Endpoint Security**: The `/change_url` and `/reload_page` endpoints do not have authentication mechanisms. It is recommended to add basic authentication or an API key to secure these endpoints if exposed publicly.
- **Logging Level**: The `chromium_api.py` script is configured to log at the debug level, which may expose sensitive information. Ensure to lower the verbosity level, particularly in production environments.
- **Flask Server**: The Flask server included is intended for development purposes. For production, you should use a WSGI server like `gunicorn` to increase security and reliability.
- **Non-Production Server Usage**: Replace Flask's default server with `gunicorn` or another production-ready server for shared or deployed versions.

## Troubleshooting

1. **415 Unsupported Media Type Error**:
   - Ensure that the `Content-Type` header in your request is set to `application/json`. This is necessary for the server to correctly interpret the request body as JSON.

2. **Chromium DBus Errors**:
   - You may see errors related to DBus (`Failed to connect to the bus`). These can generally be ignored if the browser still functions properly.

## Next Steps: Moving from Playwright to Another Chromium Implementation

If your use case requires more flexibility or if Playwright is not suitable for your specific needs, you may consider switching to another Chromium automation tool. Some popular alternatives include:

- **Thorium Browser**: Thorium is an open-source Chromium-based browser with added enhancements for privacy and efficiency. It can serve as a replacement if you need better control or features outside of standard Chromium.

Each of these tools has different strengths, and your choice will depend on your project's needs, such as language compatibility, ease of use, and community support.

## License
This project is licensed under the MIT License. See the LICENSE file for more information.
