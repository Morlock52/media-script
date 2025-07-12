# Media Stack - In-Depth Overview

_Last updated: July 2025_

This document provides a comprehensive overview of the self-hosted media server stack found in this repository. It consolidates key information from the various guides and README files to present a single, detailed reference.

## Table of Contents

1. [Purpose](#purpose)
2. [Key Features](#key-features)
3. [Core Services](#core-services)
4. [Supporting Services](#supporting-services)
5. [Docker Images](#docker-images)
6. [Media Handling & Formats](#media-handling--formats)
7. [Hardware Acceleration](#hardware-acceleration)
8. [Environment Configuration](#environment-configuration)
9. [Deployment Workflow](#deployment-workflow)
10. [Daily Operation](#daily-operation)
11. [Advanced Options](#advanced-options)
12. [Security Considerations](#security-considerations)
13. [Backup & Maintenance](#backup--maintenance)
14. [Troubleshooting Basics](#troubleshooting-basics)
15. [Recommended Add-on Apps](#recommended-add-on-apps)
---

## Purpose

This stack aims to provide a "self-hosted Netflix" style environment using entirely containerized services. It covers everything from automated media acquisition to streaming, with optional remote access through Cloudflare-powered SSL.

## Key Features
- **20+ Integrated Applications** including Jellyfin and the \*Arr suite.
- **Automated Media Lifecycle**: discover, download, organize, and stream.
- **Customizable Deployment** for local-only or remote access.
- **GPU Acceleration Support** for NVIDIA, Intel, or AMD.
- **Interactive Setup** scripts to simplify configuration.
- **Caddy Reverse Proxy** with automatic HTTPS certificates.

## Core Services
- **Jellyfin** – primary media server.
- **Sonarr / Radarr / Lidarr / Readarr** – manage TV, movies, music, and books.
- **qBittorrent & NZBGet** – torrent and Usenet download clients.
- **Prowlarr** – indexer manager for torrent/Usenet providers.
- **Tdarr** – conditional transcoding engine with multi-node support.
- **Overseerr** – request system for new content.
- **Tautulli** – usage monitoring and statistics.
- **Caddy** – reverse proxy providing HTTPS via Cloudflare DNS.

## Supporting Services
- **Bazarr** – subtitles management.
- **FlareSolverr** – bypasses Cloudflare protection for some indexers.
- **HandBrake & FFmpeg** – advanced media conversion tools.
- **MKVToolNix** – container manipulation utilities.
- **Homarr** – dashboard aggregating all services.
- **Uptime Kuma** – status and uptime monitoring.
## Docker Images
Below is a list of the main Docker images used in this stack:

| Service | Image | Notes |
|---------|-------|-------|
| Jellyfin | `jellyfin/jellyfin:latest` | Official media server |
| Sonarr | `lscr.io/linuxserver/sonarr:latest` | TV automation |
| Radarr | `lscr.io/linuxserver/radarr:latest` | Movie automation |
| Lidarr | `lscr.io/linuxserver/lidarr:latest` | Music automation |
| Readarr | `lscr.io/linuxserver/readarr:latest` | Book management |
| qBittorrent | `lscr.io/linuxserver/qbittorrent:latest` | Torrent client |
| NZBGet | `lscr.io/linuxserver/nzbget:latest` | Usenet client |
| Prowlarr | `lscr.io/linuxserver/prowlarr:latest` | Indexer manager |
| Overseerr | `sctx/overseerr:latest` | Request management |
| Tdarr | `ghcr.io/haveagitgat/tdarr:latest` | Transcoding server |
| Caddy | `lucaslorentz/caddy-docker-proxy:2.10-alpine` | Reverse proxy |
| Tautulli | `lscr.io/linuxserver/tautulli:latest` | Usage stats |
| Bazarr | `lscr.io/linuxserver/bazarr:latest` | Subtitles |
| HandBrake | `jlesage/handbrake:latest` | Manual conversions |
| FFmpeg | `linuxserver/ffmpeg:latest` | CLI processing |
| MKVToolNix | `jlesage/mkvtoolnix:latest` | Container tools |
| Homarr | `ghcr.io/ajnart/homarr:latest` | Dashboard |
| Uptime Kuma | `louislam/uptime-kuma:latest` | Monitoring |
| Watchtower | `containrrr/watchtower:latest` | Auto updates |
## Media Handling & Formats
This stack uses Jellyfin with an enhanced FFmpeg build, plus optional HandBrake and Tdarr for automated conversions. Most modern codecs are supported out of the box including AV1, HEVC/H.265, VP9 and H.264. Legacy formats (DivX, MPEG-2, etc.) can be transcoded to modern containers like MP4 or MKV. See `SUPPORTED_FORMATS.md` for detailed tables of video, audio and container formats.



## Hardware Acceleration
The stack automatically detects available GPU hardware and adjusts Docker Compose configuration accordingly. Supported options include:
- **NVIDIA** (NVENC/NVDEC)
- **Intel** (Quick Sync Video / VA-API)
- **AMD** (AMF / VA-API)

Enable or override detection via the `--gpu` flag with `deploy.sh`.

## Environment Configuration
All settings are centralized in a single `.env` file derived from `.env.example`. Paths, ports, GPU settings, and feature flags are defined here. Run `./scripts/env-manager.sh init` for a guided setup or manually copy the example file.

Key sections of the environment file include:
- **Core configuration**: domain, timezone, user IDs.
- **Storage paths**: base media and downloads directories with derived subpaths.
- **Hardware settings**: GPU flags and device variables.
- **Service ports**: override default ports if needed.

## Deployment Workflow
1. **Initialize Environment**
   ```bash
   ./scripts/env-manager.sh init
   ```
2. **Run Initial Setup** (creates directories and sets permissions)
   ```bash
   ./setup.sh
   ```
3. **Deploy Services**
   ```bash
   ./deploy.sh deploy
   ```
4. **Check Status**
   ```bash
   ./deploy.sh status
   ```

Use `--local` for LAN-only deployments or provide Cloudflare credentials for remote access with HTTPS.

## Daily Operation
- **Dashboard Access**: `https://dashboard.yourdomain.com` (or local port).
- **Media Streaming**: `https://jellyfin.yourdomain.com`.
- **Request Content**: `https://overseerr.yourdomain.com`.
- **Check Logs**: `./deploy.sh logs [service]`.
- **Update Stack**: `./deploy.sh update`.
- **Stop/Restart**: `./deploy.sh stop` and `./deploy.sh deploy`.

## Advanced Options
- **GPU Selection**: `./deploy.sh deploy --gpu nvidia` (or intel/amd/none).
- **Optional Profiles**: enable auto-updates or multi-node processing with additional flags.
- **Custom Compose Generation**: the deployment script modifies templates based on your environment.
## Performance Optimization
- Enable hardware acceleration in Jellyfin and Tdarr for faster transcoding.
- Use SSD storage for transcode temp directories to avoid slowdowns.
- Adjust Tdarr worker counts in `.env` to match your CPU/GPU horsepower.
- Keep Docker images updated via `./deploy.sh update` or the Watchtower profile.


## Security Considerations
- Reverse proxy ensures HTTPS termination via Caddy.
- Only ports 80/443 are exposed by default.
- Strongly recommend changing default passwords on first login.
- For extra privacy, integrate a VPN container for qBittorrent or NZBGet.

## Backup & Maintenance
- Backup the `config/` directory and your media libraries regularly.
- Use `./scripts/env-manager.sh backup` to archive environment files.
- Monitor system health through Uptime Kuma and Tautulli.
- Pull new images and redeploy monthly:
   ```bash
   ./deploy.sh update
   ```

## Troubleshooting Basics
- **Permission Errors**: verify PUID/PGID match your user and re-run `setup.sh`.
- **Port Conflicts**: adjust ports in `.env` or check for existing services.
- **SSL Problems**: ensure Cloudflare DNS records are correct and review Caddy logs.
- **Download Failures**: confirm indexers in Prowlarr and client settings in Sonarr/Radarr.

## Recommended Add-on Apps
- **Photoprism** – manage personal photo collections.
- **Audiobookshelf** – organize and stream audiobooks.
- **Calibre Web** – browser-based eBook library.
- **Podgrab** – automatic podcast downloader.
- **YTDL-Material** – save online videos directly to your library.

---

This overview should help you understand the full capabilities of the media stack and act as a single reference while you explore the more detailed guides included in this repository.
