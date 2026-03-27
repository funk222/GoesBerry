# GoesBerry

## Project Overview
GoesBerry is a project designed to facilitate the reception and processing of GOES-16/18 HRIT/GRB images on a Raspberry Pi 5. Utilizing tools such as goesrecv and goesproc, this project aims to streamline the workflow of obtaining satellite imagery.

## Features
- **Image Reception**: Capture GOES-16/18 HRIT/GRB images using the goesrecv utility.
- **Image Processing**: Use goesproc for further processing of the captured images.
- **Configuration Management**: Custom configuration available at `/boot/goesberry.conf`.
- **Systemd Services**: Utilizes systemd for service management to ensure smooth operation.
- **Web Interface**: A Node.js backend coupled with a Vue3/Vite frontend for accessing image data and configurations.

## Getting Started
1. Clone the repository.
2. Configure your system using `/boot/goesberry.conf`.
3. Install necessary dependencies.
4. Start the services using systemd.
5. Access the web interface to view images and manage configurations.

## Installation
For detailed installation steps, refer to the [INSTALL.md](INSTALL.md) file in the repository.