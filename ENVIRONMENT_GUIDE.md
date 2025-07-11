# Environment Management Guide

_Last updated: July 2025_

This guide explains the optimized environment variable system that reduces duplication and simplifies maintenance of your media stack.

## Overview

The media stack uses a comprehensive environment variable system that:
- **Eliminates duplication** across docker-compose services
- **Centralizes configuration** in a single `.env` file
- **Provides intelligent defaults** for most settings
- **Supports dynamic path configuration** 
- **Enables conditional features** (GPU acceleration, profiles)

## Quick Start

### 1. Initialize Environment
```bash
# Interactive setup for first time
./scripts/env-manager.sh init

# Or copy and edit manually
cp .env.example .env
nano .env
```

### 2. Deploy with Auto-Detection
```bash
# Automatic GPU detection and deployment
./deploy.sh deploy

# With optional features
./deploy.sh deploy --with-alternatives --with-auto-update
```

## Environment Structure

The `.env` file is organized into logical sections:

### Core Configuration
```bash
DOMAIN=yourdomain.com                 # Your primary domain
COMPOSE_PROJECT_NAME=media-stack      # Docker project name
TZ=America/New_York                   # Timezone
PUID=1000                            # User ID
PGID=1000                            # Group ID
```

### Storage Paths
```bash
# Base paths (customize these)
CONFIG_PATH=./config
MEDIA_PATH=/media
DOWNLOADS_PATH=/downloads
TEMP_PATH=/tmp

# Derived paths (automatically calculated)
MOVIES_PATH=${MEDIA_PATH}/movies
TV_PATH=${MEDIA_PATH}/tv
MUSIC_PATH=${MEDIA_PATH}/music
# etc...
```

### Hardware Acceleration
```bash
# GPU feature flags
ENABLE_NVIDIA_GPU=false
ENABLE_INTEL_GPU=false
ENABLE_AMD_GPU=false

# GPU environment variables (auto-configured)
NVIDIA_VISIBLE_DEVICES=all
NVIDIA_DRIVER_CAPABILITIES=compute,utility,video
VIDEO_GROUP_ID=109
```

### Service Configuration
```bash
# Tdarr processing
TDARR_CPU_WORKERS=2
TDARR_GPU_WORKERS=1
TDARR_FFMPEG_VERSION=7

# Service ports
HOMARR_PORT=7575
UPTIME_KUMA_PORT=3001
QBITTORRENT_WEBUI_PORT=8080
```

## Key Benefits

### 1. Path Flexibility
Change base paths and all dependent paths update automatically:

```bash
# Before: Hard-coded paths everywhere
volumes:
  - /media/movies:/movies
  - /media/tv:/tv
  - /media/music:/music

# After: Centralized configuration
volumes:
  - ${MOVIES_PATH}:/movies
  - ${TV_PATH}:/tv
  - ${MUSIC_PATH}:/music

# Change MEDIA_PATH and everything updates
MEDIA_PATH=/mnt/storage  # All paths now use /mnt/storage/
```

### 2. Service Reusability
Common configurations are defined once using YAML anchors:

```yaml
# Define once
x-arr-common: &arr-common
  environment:
    - TZ=${TZ:-UTC}
    - PUID=${PUID:-1000}
    - PGID=${PGID:-1000}
    - UMASK_SET=${UMASK:-002}
  restart: ${RESTART_POLICY:-unless-stopped}
  networks:
    - ${NETWORK_NAME:-media-network}

# Reuse everywhere
sonarr:
  <<: *arr-common
  # Only specify unique settings

radarr:
  <<: *arr-common
  # Only specify unique settings
```

### 3. Conditional Features
Features can be enabled/disabled without editing docker-compose:

```bash
# Enable alternative dashboards
docker-compose --profile alternative-dashboard up -d

# Enable auto-updates
docker-compose --profile auto-update up -d

# Enable multi-node processing
docker-compose --profile multi-node up -d
```

## Environment Management Commands

### env-manager.sh
Comprehensive environment management tool:

```bash
# Initialize .env from template
./scripts/env-manager.sh init

# Validate current configuration
./scripts/env-manager.sh validate

# Show current settings
./scripts/env-manager.sh show

# Setup API keys interactively
./scripts/env-manager.sh setup-api-keys

# Update storage paths
./scripts/env-manager.sh update-paths

# Configure GPU acceleration
./scripts/env-manager.sh enable-gpu

# Backup configuration
./scripts/env-manager.sh backup
```

### deploy.sh
Intelligent deployment with auto-detection:

```bash
# Basic deployment with GPU auto-detection
./deploy.sh deploy

# Deploy with specific features
./deploy.sh deploy --with-alternatives --with-auto-update

# Force specific GPU type
./deploy.sh deploy --gpu nvidia

# Other commands
./deploy.sh update      # Update all services
./deploy.sh stop        # Stop all services
./deploy.sh logs        # View all logs
./deploy.sh status      # Check service health
```

## Advanced Configuration

### Custom Docker Compose Generation

The system generates optimized docker-compose files based on your hardware:

```bash
# GPU detection happens automatically
NVIDIA GPU detected: GeForce RTX 4080
Enabling NVIDIA GPU acceleration
Docker Compose file generated with GPU support: nvidia
```

This modifies the base template to include:
- Appropriate device mappings
- GPU environment variables
- Hardware-specific optimizations

### Profile-Based Deployment

Optional services use Docker Compose profiles:

```yaml
# Only starts with --profile alternative-dashboard
heimdall:
  profiles:
    - "alternative-dashboard"

# Only starts with --profile auto-update  
watchtower:
  profiles:
    - "auto-update"

# Only starts with --profile multi-node
tdarr-node-2:
  profiles:
    - "multi-node"
```

### Environment Variable Inheritance

Variables are inherited and can be overridden:

```bash
# Base configuration
MEDIA_PATH=/media

# Derived paths (automatically calculated)
MOVIES_PATH=${MEDIA_PATH}/movies      # = /media/movies
TV_PATH=${MEDIA_PATH}/tv              # = /media/tv

# Override specific paths if needed
MOVIES_PATH=/mnt/movies               # Override just movies
# TV_PATH still = /media/tv
```

### Conditional GPU Configuration

GPU settings are applied conditionally:

```yaml
# Template has empty arrays
devices: []
group_add: []

# Script adds devices based on detection
devices:
  - /dev/nvidia0:/dev/nvidia0         # If NVIDIA detected
  - /dev/dri:/dev/dri                 # If Intel detected
group_add:
  - "109"                             # Video group
```

## Configuration Examples

### Home Server Setup
```bash
DOMAIN=media.home.local
MEDIA_PATH=/mnt/storage
DOWNLOADS_PATH=/mnt/storage/downloads
ENABLE_NVIDIA_GPU=true
TDARR_GPU_WORKERS=2
```

### VPS/Cloud Setup
```bash
DOMAIN=media.example.com
MEDIA_PATH=/opt/media
DOWNLOADS_PATH=/opt/downloads
ENABLE_NVIDIA_GPU=false
TDARR_CPU_WORKERS=4
```

### Multi-User Setup
```bash
DOMAIN=family-media.com
COMPOSE_PROJECT_NAME=family-media
BASIC_AUTH_USER=family
BASIC_AUTH_PASS=secure-password
```

## Troubleshooting

### Environment Validation
```bash
# Check for configuration issues
./scripts/env-manager.sh validate

# Common issues and solutions:
# - Missing API keys: Run setup-api-keys
# - Wrong PUID/PGID: Auto-detected during init
# - Invalid paths: Use update-paths command
```

### Path Issues
```bash
# Check current paths
./scripts/env-manager.sh show

# Update problematic paths
./scripts/env-manager.sh update-paths

# Verify directory creation
./deploy.sh deploy  # Creates missing directories
```

### GPU Problems
```bash
# Check GPU detection
./deploy.sh deploy --gpu none  # Disable GPU

# Force specific GPU
./deploy.sh deploy --gpu nvidia

# Manual GPU configuration
./scripts/env-manager.sh enable-gpu
```

## Migration from Old Setup

### From Static docker-compose.yml
1. **Backup existing**: `cp docker-compose.yml docker-compose.yml.backup`
2. **Initialize environment**: `./scripts/env-manager.sh init`
3. **Customize paths**: Edit `.env` to match your current paths
4. **Deploy optimized**: `./deploy.sh deploy`

### From Manual Configuration
1. **Extract settings**: Note your current paths, domains, etc.
2. **Run initialization**: `./scripts/env-manager.sh init`
3. **Apply your settings**: Use the interactive prompts
4. **Validate configuration**: `./scripts/env-manager.sh validate`

## Best Practices

### Environment File Management
- **Version control**: Add `.env` to `.gitignore`, track `.env.example`
- **Backup regularly**: Use `./scripts/env-manager.sh backup`
- **Document changes**: Comment custom modifications in `.env`

### Security Considerations
- **Protect API keys**: Restrict `.env` file permissions
- **Regular rotation**: Update API keys periodically
- **Secure passwords**: Use strong passwords for authentication

### Maintenance Schedule
- **Weekly**: Check service health with `./deploy.sh status`
- **Monthly**: Update services with `./deploy.sh update`
- **Quarterly**: Review and update `.env` configuration

This optimized environment system provides a robust, maintainable foundation for your media stack that grows with your needs while minimizing configuration complexity.
## Recommended Add-on Apps

- **Photoprism:** Self-hosted photo management and backup.
- **Audiobookshelf:** Organize and stream audiobooks.
- **Calibre Web:** Manage and read eBooks in your browser.
- **Podgrab:** Automatically download podcast episodes.
- **YTDL-Material:** Save online videos directly to your library.
