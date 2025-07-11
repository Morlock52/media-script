# Your Ultimate Self-Hosted Media Server Stack

Welcome to your all-in-one solution for building a personal media powerhouse! This project deploys a comprehensive suite of over 20 containerized services to create your very own "self-hosted Netflix," giving you full control over your movies, TV shows, music, and more.

## Overview

This stack automates the entire media lifecycle: from discovering and downloading content to organizing, transcoding, and streaming it to your favorite devices. It's designed to be powerful for seasoned home-labbers yet accessible enough for those new to self-hosting, thanks to a guided setup process.

## Why Choose This Stack?

*   **Comprehensive:** Over 20 integrated services working in harmony, including popular tools like Jellyfin, the *Arr suite, and Tdarr.
*   **Automated:** Set it up and let it manage your media library with minimal intervention.
*   **Customizable:** Tailor your deployment for local LAN access or secure remote access over the internet.
*   **Optimized:** Options for GPU-accelerated transcoding to ensure smooth streaming.
*   **Control:** Own your media and your data.
*   **Open Source Focused:** Built primarily around powerful open-source applications.

## What's Inside? (Key Services Explained)

This stack includes many services, but here are some of the stars of the show:

*   **Jellyfin:** A free, open-source media system that puts you in control of managing and streaming your media. Think of it as your personal Netflix, Plex, or Emby.
*   **Sonarr:** Smart PVR for TV shows. It monitors multiple RSS feeds for new episodes of your favorite shows and will grab, sort, and rename them.
*   **Radarr:** A movie collection manager for Usenet and BitTorrent users. It can monitor multiple RSS feeds for new movies and will interface with clients and indexers to grab, sort, and rename them.
*   **Lidarr:** A music collection manager for Usenet and BitTorrent users. It's like Sonarr/Radarr but for music, helping you manage your digital music library.
*   **Tdarr:** A conditional-based transcoding application. It can be used to automate transcoding of your media files into preferred formats and codecs, saving space and ensuring compatibility across devices.

...and about 15+ other supporting services for downloads, indexing, monitoring, and more to create a seamless experience!

## Key Features

*   Automated discovery and downloading of movies, TV shows, and music.
*   Beautiful and intuitive media browsing and streaming interface with Jellyfin.
*   Automated media file organization and renaming.
*   Efficient, conditional transcoding of media files with Tdarr.
*   Containerized deployment using Docker for easy management and updates.
*   Guided interactive setup for straightforward installation.
*   Flexible deployment options: local-only, remote access with SSL, GPU acceleration.
*   Potential for auto-updates and multi-node configurations (for advanced users).

## Prerequisites

*   **Docker and Docker Compose v2:** Essential for running the containerized services. Make sure the `docker` command and the `docker compose` plugin are available.
*   **Sufficient Disk Space:** Your media library can grow large! Plan accordingly.
*   **Operating System:** Linux-based OS recommended (scripts are Bash).
*   **(Optional but Recommended)** Basic familiarity with the command line.
*   **(For Remote Access)** A domain name you own and a Cloudflare account (for SSL and DNS management). Skip if you choose local-only access.

## Getting Started

1.  **Clone the Repository (if you haven't already):**
    ```bash
    git clone <your-repository-url> # Replace with your actual repo URL
    cd <your-repository-directory>
    ```

2.  **Run the Interactive Setup (Recommended for New Installs):
    This wizard will guide you through the entire configuration process, including directory setup, permissions, and environment configuration. The very first prompt lets you choose **Local Only** or **Cloudflare Remote** access.
    ```bash
    ./interactive-setup.sh
    ```
    During the setup, you'll be asked to choose between:
    *   **Remote Access:** Configures a domain and Cloudflare SSL for secure internet access to your services.
    *   **Local Only:** Skips Cloudflare setup, making services accessible only on your local network (e.g., `http://localhost:port`).

3.  **Manual/Quick Setup (For Advanced Users or Specific Needs):
    If you prefer a more hands-on approach or are re-configuring:
    *   **Quick Directory & Permission Setup:**
        ```bash
        ./setup.sh
        ```
    *   **Initialize Environment Configuration:**
        ```bash
        ./scripts/env-manager.sh init
        ```
        This command uses `.env.example` to create your `.env` file. You can also copy it manually:
        ```bash
        cp .env.example .env
        ```

        After editing the `.env` file, validate your settings and confirm Docker is installed:
        ```bash
        ./scripts/env-manager.sh validate
        ./deploy.sh status
        ```

## Deployment & Management

Once the initial setup and configuration are complete, you can deploy and manage your media stack using the `deploy.sh` script.

*   **Deploy the Stack (Standard with Optimization):
    This is the most common command to bring your services online.
    ```bash
    ./deploy.sh deploy
    ```

*   **Deploy for Local-Only Access:
    If you configured for local-only or want to ensure no external access attempts.
    ```bash
    ./deploy.sh deploy --local
    ```
    When using this mode, Cloudflare credentials in `.env` can remain empty.

*   **Deploy with GPU Acceleration (NVIDIA Example):
    Leverage your NVIDIA GPU for hardware-accelerated transcoding in services like Jellyfin and Tdarr.
    ```bash
    ./deploy.sh deploy --gpu nvidia
    ```
    *(Note: Ensure your system has the necessary NVIDIA drivers and Docker runtime configured for GPU passthrough.)*

*   **Deploy with Advanced Options (Example):
    For users who have configured or require features like automatic updates or multi-node setups.
    ```bash
    ./deploy.sh deploy --with-auto-update --with-multi-node
    ```

*   **Stopping the Stack:**
    ```bash
    ./deploy.sh down # Or docker-compose down, depending on script structure
    ```

*   **Updating Services:**
    (Refer to project-specific documentation or `./deploy.sh help` if available for update procedures. Typically involves pulling new Docker images and redeploying.)

*   **Check Status or Logs:**
    ```bash
    ./deploy.sh status            # Show running containers
    ./deploy.sh logs jellyfin     # Tail logs for a service
    ```

## Reverse Proxy with Caddy

This stack now ships with [Caddy](https://caddyserver.com) acting as a dynamic
reverse proxy for all services. It uses the `lucaslorentz/caddy-docker-proxy`
image, which reads Docker labels from the compose file to generate configuration
automatically. Provide your Cloudflare credentials in `.env` and Caddy will
obtain HTTPS certificates for your subdomains without manual setup.

## Accessing Your Media Empire

Once deployed, your services will be accessible via specific URLs and ports. 

*   **Local Access:** Typically `http://localhost:<port_number>` or `http://<your_server_ip>:<port_number>`.
*   **Remote Access:** If configured, via your domain, e.g., `https://jellyfin.yourdomain.com`.

The interactive setup or your environment configuration files (`.env` or similar) should contain the specific ports and URLs for each service. Default credentials (if any) will also be there – **be sure to change them immediately!**

## Troubleshooting

*(This section can be expanded with common issues and solutions as they arise.)*

*   **Permission Issues:** Double-check directory permissions set by `setup.sh`.
*   **Port Conflicts:** Ensure the ports required by the services are not already in use.
*   **Docker Logs:** Use `docker logs <container_name>` to check for errors in specific services.

## Contributing

Contributions are welcome! Whether it's improving documentation, fixing bugs, or suggesting new features, please feel free to:

1.  Open an issue to discuss the change.
2.  Fork the repository and create a new branch.
3.  Make your changes and submit a pull request.

## License

*(Specify your project's license here, e.g., MIT, GPL, etc. If unsure, you can state "This project is unlicensed" or research common open-source licenses.)*

---

Happy self-hosting!

## Recommended Add-on Apps

- **Photoprism:** Self-hosted photo management and backup.
- **Audiobookshelf:** Organize and stream audiobooks.
- **Calibre Web:** Manage and read eBooks in your browser.
- **Podgrab:** Automatically download podcast episodes.
- **YTDL-Material:** Save online videos directly to your library.

### July 2025 Update
Homarr continues to be one of the top dashboards for self-hosted environments. The [Awesome Selfhosted](https://awesome-selfhosted.net) list highlights **Homarr** alongside **Dashy** and other options.
