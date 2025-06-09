# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a comprehensive media server stack that provides automated media management and streaming. It deploys 20+ containerized services including Jellyfin (media server), Sonarr/Radarr/Lidarr (media automation), Tdarr (transcoding), and supporting infrastructure for a complete "self-hosted Netflix" solution.

## Key Commands

### Initial Setup
```bash
./interactive-setup.sh           # Full guided setup wizard (recommended for new installs)
./setup.sh                       # Quick directory and permission setup
./scripts/env-manager.sh init    # Initialize environment configuration
```

**Setup Options:**
- **Remote Access**: Configure domain + Cloudflare SSL for internet access
- **Local Only**: Skip Cloudflare setup for LAN-only access (localhost)

### Deployment & Management
```bash
./deploy.sh deploy               # Deploy stack with automatic optimization
./deploy.sh deploy --local       # Local-only deployment (no SSL/domain required)
./deploy.sh deploy --gpu nvidia  # Deploy with specific GPU acceleration
./deploy.sh deploy --with-auto-update --with-multi-node  # Full deployment with extras
./deploy.sh status               # Check all service status
./deploy.sh logs [service_name]  # View service logs
./deploy.sh update               # Update all services
./deploy.sh stop                 # Stop all services
```

### Environment Management
```bash
./scripts/env-manager.sh show            # Display current configuration
./scripts/env-manager.sh setup-api-keys  # Configure API keys for services
./scripts/env-manager.sh enable-gpu      # Setup GPU acceleration
./scripts/env-manager.sh backup          # Backup configuration
```

### Quick Operations
```bash
./start.sh                       # Quick start all services
docker compose ps                # View service status
docker compose logs -f [service] # Follow service logs
```

## Architecture

### Core Services Structure
- **Media Servers**: Jellyfin (primary streaming), Tautulli (monitoring)
- **Media Automation**: Sonarr (TV), Radarr (movies), Lidarr (music), Readarr (books)
- **Download Clients**: qBittorrent (torrents), NZBGet (usenet)
- **Processing**: Tdarr (transcoding with multi-node support), HandBrake, FFmpeg
- **Infrastructure**: Caddy (reverse proxy), Homarr (dashboard), Uptime Kuma (monitoring)

### Configuration Management
- Environment-driven configuration via `.env` file
- GPU acceleration auto-detection (NVIDIA, Intel, AMD)
- Hardware-specific Docker Compose generation
- Optional Cloudflare SSL integration for secure remote access
- Local-only mode available (set `LOCAL_ONLY=true`)

### Key Files
- `docker-compose.yml`: Main service definitions (generated)
- `docker-compose.optimized.yml`: Template for remote access with SSL
- `docker-compose.local.yml`: Template for local-only access 
- `deploy.sh`: Intelligent deployment with hardware detection
- `interactive-setup.sh`: Comprehensive setup wizard (1400+ lines)
- `scripts/env-manager.sh`: Environment and configuration management
- `config/`: Service-specific configurations (Caddy, Tdarr, Homarr)

## Development Notes

### Cross-Platform Compatibility
This stack runs on macOS, Linux, and Windows WSL with platform-specific optimizations:

- **GPU Detection**: Automatically detects NVIDIA, Intel, AMD GPUs on Linux/WSL, Apple Silicon/Metal on macOS
- **Docker Compose**: Uses v2 syntax (`docker compose`) throughout for compatibility
- **Platform Detection**: Built-in platform detection handles Linux, macOS, WSL, and Windows environments
- **Path Handling**: Environment-driven paths prevent hard-coded Unix path issues

### GPU Acceleration Support
Hardware transcoding support varies by platform:
- **Linux/WSL**: NVIDIA (NVENC), Intel (QSV), AMD (AMF)
- **macOS**: Apple Silicon GPU, Metal support, legacy NVIDIA
- **Windows**: NVIDIA GPUs via Docker Desktop

GPU detection is automatic but can be overridden with `--gpu` flag.

### Multi-Node Processing
Tdarr supports distributed processing across multiple nodes for heavy transcoding workloads. Enable with `--with-multi-node` deployment flag.

### Service Dependencies
Services have complex interdependencies managed through Docker Compose. Always use `deploy.sh` rather than raw `docker compose` commands to ensure proper startup order and configuration.

### Configuration Backup
Environment configurations should be backed up using `env-manager.sh backup` before major changes.

### VPN Protection (Optional)
**Security Recommendation**: The current stack includes download clients (qBittorrent, NZBGet) with standard network configuration. For enhanced privacy protection, consider implementing VPN integration.

**Current Configuration:**
- Download clients use standard Docker networking
- Direct internet access for torrent/usenet downloads
- Web interfaces accessible via Caddy reverse proxy

**VPN Enhancement Options:**
- Add PIA VPN container with killswitch functionality
- Configure download clients to use `network_mode: container:pia-vpn`
- Implement zero internet access when VPN is down (killswitch protection)
- Route all torrent/usenet traffic through encrypted VPN tunnel

**Note**: The documentation mentions VPN consideration but implementation is not included in the current docker-compose configuration. Users should add VPN containers manually if required for their use case.

### Local vs Remote Deployment
- **Local Mode** (`--local`): Uses `docker-compose.local.yml` with direct port mapping, no SSL
  - Access via: `http://localhost:8096` (Jellyfin), `http://localhost:7575` (Dashboard)
  - No domain or Cloudflare setup required
  - Best for LAN-only access or development

- **Remote Mode** (default): Uses `docker-compose.optimized.yml` with Caddy reverse proxy
  - Access via: `https://jellyfin.yourdomain.com`, `https://dashboard.yourdomain.com`
  - Requires domain and Cloudflare API configuration
  - Automatic SSL certificate generation

### Platform-Specific Notes
- **macOS**: Requires Docker Desktop, limited GPU acceleration compared to Linux
- **WSL**: Full GPU passthrough support with proper Docker Desktop configuration
- **Linux**: Best performance and full hardware acceleration support