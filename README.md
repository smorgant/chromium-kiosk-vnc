# Chromium-Controlled Docker Container
This project provides a Docker container that runs a Chromium browser controlled via a Python-based API server. The container uses Playwright to download and set up Chromium, while leveraging the Chrome DevTools Protocol (CDP) via WebSocket to manage and control the browser through the API. Additionally, the container includes a VNC server for visual interaction with the browser and provides file download and retrieval capabilities.


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
  - [/download_file](#download_file)
  - [/list_downloads](#list_downloads)
  - [/get_file](#get_file)
  - [/delete_file](#delete_file)
- [Security Considerations](#security-considerations)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Latest Additions
- **Support for WebGL2**: Leverage mesa to support GPU acceleration via CPU acceleration- This can generate high cpu requirement VM will need to be sized appropriateley in this context
- **Shutdown Endpoint**: Added a new endpoint to shutdown the docker container / shutdown
- **File Download and Management**: Added new endpoints for downloading files, listing downloads, retrieving files, and managing downloaded content

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

To run multiple instances of the container, you can map the internal ports (5900 and 5901) to different external ports. For example:

```
# First instance
docker run -p 5900:5900 -p 5901:5901 -e TARGET_URL=https://www.example.com --name chromium-kiosk-v1 chromium-controller

# Second instance with different external ports
docker run -p 5902:5900 -p 5903:5901 -e TARGET_URL=https://www.example.com --name chromium-kiosk-v2 chromium-controller
```

In this example:
- The first instance uses default ports (5900/5901)
- The second instance maps internal port 5900 to external port 5902 (VNC) and internal port 5901 to external port 5903 (API)
- Each instance needs a unique container name (--name)

### Required and Optional Parameters for Running the Container

- **Required Parameter**:
  - `TARGET_URL`: The URL that Chromium should navigate to. This must be passed when starting the container.

- **Non-Mandatory Parameters**:
  - `VNC_PORT`: Port for the VNC server. Defaults to `5900` if not specified.
  - `SCREEN_WIDTH`: Width of the virtual screen. Defaults to `1920` if not specified.
  - `SCREEN_HEIGHT`: Height of the virtual screen. Defaults to `1080` if not specified.
  - `VNC_PASSWORD`: Password for VNC access. By default, no password is set, but it is recommended for security purposes.
  - `DOWNLOAD_DIR`: Directory for storing downloaded files. Defaults to `/downloads` if not specified.

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

### /download_file
**Endpoint**: `/download_file`  
**Method**: `POST`  
**Description**: Initiates a file download using Chrome DevTools Protocol.

**Request Headers**:
- `Content-Type`: Must be set to `application/json`

**Request Body** (JSON):
```
{
  "url": "<download_url>"
}
```

**Response**:
- Success: Returns a status `200 OK` with a message indicating that the download has been initiated and the download directory path.
- Failure: Returns a status `400` if no URL is provided, `404` if no open tabs are found, or `500` if there is an error communicating with Chromium.

### /list_downloads
**Endpoint**: `/list_downloads`  
**Method**: `GET`  
**Description**: Lists all files in the download directory with their metadata.

**Response**:
- Success: Returns a status `200 OK` with a JSON array of files containing:
  - `name`: File name
  - `size`: File size in bytes
  - `modified`: Last modification timestamp
  - `path`: Full file path
- Failure: Returns a status `500` if there is an error accessing the download directory.

### /get_file
**Endpoint**: `/get_file`  
**Method**: `POST`  
**Description**: Retrieves a specific file from the download directory.

**Request Headers**:
- `Content-Type`: Must be set to `application/json`

**Request Body** (JSON):
```
{
  "filename": "example.pdf"
}
```

**Response**:
- Success: Returns the file as an attachment with appropriate headers.
- Failure: 
  - Returns a status `400` if no filename is provided in the request body
  - Returns a status `404` if the file is not found
  - Returns a status `500` if there is an error retrieving the file

**Example Usage**:
```bash
curl -X POST http://localhost:5901/get_file \
  -H "Content-Type: application/json" \
  -d '{"filename": "example.pdf"}'
```

### /delete_file
**Endpoint**: `/delete_file/<filename>`  
**Method**: `DELETE`  
**Description**: Deletes a specific file from the download directory.

**Parameters**:
- `filename`: The name of the file to delete (in the URL path)

**Response**:
- Success: Returns a status `200 OK` with a message indicating that the file was deleted successfully.
- Failure: Returns a status `404` if the file is not found, or `500` if there is an error deleting the file.

## Security Considerations

- **Environment Variables**: Avoid hardcoding sensitive values (e.g., credentials) in the Dockerfile or scripts. Instead, pass sensitive values through environment variables using `docker run -e` options.
- **VNC Password**: By default, the VNC server runs without a password, which is insecure in a public environment. Consider setting a VNC password by passing the VNC_PASSWORD environment variable.
- **API Endpoint Security**: The `/change_url` and `/reload_page` endpoints do not have authentication mechanisms. It is recommended to add basic authentication or an API key to secure these endpoints if exposed publicly.
- **Logging Level**: The `chromium_api.py` script is configured to log at the debug level, which may expose sensitive information. Ensure to lower the verbosity level, particularly in production environments.
- **Flask Server**: The Flask server included is intended for development purposes. For production, you should use a WSGI server like `gunicorn` to increase security and reliability.
- **Non-Production Server Usage**: Replace Flask's default server with `gunicorn` or another production-ready server for shared or deployed versions.
- **Download Directory Security**: Ensure the download directory has appropriate permissions and is properly secured, especially when running in a production environment.

## Troubleshooting

1. **415 Unsupported Media Type Error**:
   - Ensure that the `Content-Type`