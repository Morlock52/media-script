# Media Stack Setup Guide

_Last updated: June 2025_

This Docker Compose setup provides a complete media server stack with Jellyfin and the Arr suite, using Caddy for reverse proxy with Cloudflare SSL.

## Included Applications

### Core Media Stack
- **Jellyfin**: Media server with comprehensive format support (AV1, HEVC, VP9, H.264, etc.)
- **Sonarr**: TV show management and automation
- **Radarr**: Movie management and automation  
- **Lidarr**: Music management and automation
- **Readarr**: Book management and automation
- **Prowlarr**: Indexer management (replaces Jackett)
- **qBittorrent**: Download client
- **Overseerr**: Media request management
- **Tautulli**: Media server monitoring
- **Bazarr**: Subtitle management
- **FlareSolverr**: Cloudflare bypass for protected indexers
- **Caddy**: Reverse proxy with automatic SSL

### Format Processing & Conversion Tools
- **HandBrake**: Automated video conversion with presets
- **FFmpeg**: Advanced media processing with all modern codecs
- **MKVToolNix**: Container format management and manipulation

## Prerequisites

1. **Docker and Docker Compose** installed
2. **Cloudflare account** with domain managed by Cloudflare
3. **Cloudflare API token** with Zone:Read and Zone:Zone permissions
4. **Directory structure** for media storage

## Setup Instructions

### 1. Directory Structure

Create the following directory structure on your host:

```
/downloads/                    # Download directory (shared between qBittorrent and *arr apps)
  ├── complete/              # Completed downloads
  ├── incomplete/            # In-progress downloads
  ├── convert-input/         # Files to be converted
  └── convert-output/        # Converted files
/media/
  ├── movies/               # Movies library
  ├── tv/                   # TV shows library
  ├── music/                # Music library
  ├── books/                # Books library
  ├── anime/                # Anime collection
  ├── documentaries/        # Documentary films
  ├── 4k/                   # 4K/UHD content
  └── converted/            # Format-converted media
    ├── av1/              # AV1 encoded files
    ├── hevc/             # HEVC/H.265 files
    ├── h264/             # H.264 compatibility files
    ├── vp9/              # VP9 WebM files
    ├── opus/             # Opus audio files
    └── flac/             # FLAC lossless audio
/tmp/jellyfin-transcode/      # Jellyfin transcoding temp directory
```

### 2. Environment Configuration

1. Copy `.env.example` to `.env`
2. Edit `.env` and configure:
   - `DOMAIN`: Your domain (e.g., media.example.com)
   - `CLOUDFLARE_EMAIL`: Your Cloudflare account email
   - `CLOUDFLARE_API_TOKEN`: Your Cloudflare API token
   - `TZ`: Your timezone
   - `PUID/PGID`: Your user/group IDs (run `id` command)

### 3. Cloudflare DNS Setup

Create DNS A records pointing to your server's IP:
- `jellyfin.yourdomain.com`
- `sonarr.yourdomain.com`
- `radarr.yourdomain.com`
- `lidarr.yourdomain.com`
- `readarr.yourdomain.com`
- `prowlarr.yourdomain.com`
- `qbittorrent.yourdomain.com`
- `overseerr.yourdomain.com`
- `tautulli.yourdomain.com`
- `bazarr.yourdomain.com`
- `handbrake.yourdomain.com`
- `mkvtoolnix.yourdomain.com`

### 4. Start Services

```bash
# Run interactive setup to configure directories and permissions
./setup.sh

# Start all services
docker-compose up -d

# Check logs
docker-compose logs -f
```

### 5. Initial Configuration

#### Prowlarr (Configure First)
1. Access `https://prowlarr.yourdomain.com`
2. Add indexers 
3. Add applications (Sonarr, Radarr, Lidarr, Readarr) with API keys
4. Configure FlareSolverr URL: `http://flaresolverr:8191`

#### Download Client (qBittorrent)
1. Access `https://qbittorrent.yourdomain.com`
2. Login with default credentials (admin/adminadmin)
3. Change password in settings
4. Set download path to `/downloads`

#### Usenet Client (NZBGet)
1. Access `https://nzbget.yourdomain.com`
2. Login with default credentials (nzbget/nzbget)
3. Change username/password in settings
4. Set download paths:
   - Default download directory: `/downloads/complete`
   - Incomplete directory: `/downloads/incomplete`

#### Arr Applications
1. Configure download client (qBittorrent) in each app
2. Set up quality profiles and naming conventions
3. Add root folders:
   - Sonarr: `/tv`
   - Radarr: `/movies`
   - Lidarr: `/music`
   - Readarr: `/books`
4. Enable hardlinks and instant moves:
   - In each *arr app, go to Settings → Media Management → File Management
   - Enable "Use Hardlinks instead of Copy" and "Enable Instant Rename"
   - See https://trash-guides.info/File-and-Folder-Structure/Hardlinks-and-Instant-Moves for details

#### Jellyfin (Enhanced Format Support)
1. Access `https://jellyfin.yourdomain.com`
2. Complete initial setup wizard
3. Add media libraries:
   - Movies: `/data/movies`
   - TV Shows: `/data/tv`
   - Music: `/data/music`
   - Books: `/data/books`
   - Anime: `/data/anime`
   - Documentaries: `/data/documentaries`
   - 4K Content: `/data/4k`
4. Configure hardware transcoding (if GPU available):
   - Go to Dashboard > Playback
   - Enable hardware acceleration (NVENC, QSV, or VA-API)
   - Configure transcoding settings for optimal performance
5. Set up transcoding profiles for different clients and quality levels

#### Overseerr
1. Access `https://overseerr.yourdomain.com`
2. Sign in with Jellyfin account
3. Configure Sonarr and Radarr connections

## Security Considerations

- All services are behind Caddy reverse proxy with SSL
- No direct port exposure except 80/443
- Consider setting up VPN for download client
- Use strong passwords for all services
- Regular backups of configuration directories

## Backup Strategy

Important directories to backup:
- `./config/` - All application configurations
- Media libraries (separate backup strategy recommended)

## Troubleshooting

### Permission Issues
- Ensure PUID/PGID match your user
- Check directory ownership: `sudo chown -R 1000:1000 /downloads /media`

### SSL Certificate Issues  
- Verify Cloudflare API token permissions
- Check DNS propagation
- Review Caddy logs: `docker-compose logs caddy`

### Download Issues
- Check qBittorrent connection in *arr apps
- Verify download path consistency
- Ensure adequate disk space

## Maintenance

### Updates
```bash
# Pull latest images
docker-compose pull

# Restart services
docker-compose up -d
```

### Log Management
```bash
# View logs
docker-compose logs [service-name]

# Follow logs
docker-compose logs -f [service-name]
```

## Supported Media Formats

### Video Codecs (2025 Support)
- **Versatile Video Coding (VVC/H.266)**: Next-generation codec with high compression efficiency (~50% better than HEVC)
- **Low Complexity Enhancement Video Coding (LCEVC)**: Enhancement layer for improved compression efficiency on existing codecs
- **Essential Video Coding (EVC/MPEG-5)**: Modern codec with multiple profiles for broad compatibility
- **AV1**: Latest efficient codec (libaom-av1)
- **HEVC/H.265**: High efficiency codec with 10-bit support
- **VP9**: Google's open-source codec
- **H.264/AVC**: Universal compatibility codec
- **VP8**: Legacy WebM support
- **MPEG-4/DivX/Xvid**: Legacy format support

### Audio Codecs
- **Opus**: Modern efficient audio codec
- **FLAC**: Lossless compression
- **AAC**: Standard lossy compression
- **MP3**: Universal compatibility
- **Vorbis**: Open-source compression
- **DTS/DTS-HD**: Blu-ray audio
- **Dolby Digital/AC3**: DVD/Blu-ray audio
- **Dolby TrueHD/Atmos**: Premium audio formats

### Container Formats
- **MP4**: Universal compatibility
- **MKV**: Feature-rich container
- **WebM**: Web-optimized format
- **AVI**: Legacy support
- **MOV**: QuickTime format
- **TS**: Transport stream

### Subtitle Formats
- **SRT**: SubRip text subtitles
- **ASS/SSA**: Advanced subtitle styling
- **VobSub**: DVD picture subtitles
- **PGS**: Blu-ray picture subtitles
- **WebVTT**: Web subtitle format

## Format Conversion Tools

### Automated Conversion Scripts
```bash
# Convert single file
./scripts/ffmpeg/convert-formats.sh

# Batch conversion with queue management
./scripts/ffmpeg/batch-convert.sh add /path/to/file.mkv av1 high
./scripts/ffmpeg/batch-convert.sh worker  # Start worker process
./scripts/ffmpeg/batch-convert.sh status  # Check queue status
```

### HandBrake Web Interface
- Access: `https://handbrake.yourdomain.com`
- Automated conversion with presets
- Watch folder: `/downloads/convert-input`
- Output folder: `/downloads/convert-output`

### Hardware Acceleration Setup

#### NVIDIA GPU (NVENC/NVDEC)
1. Uncomment NVIDIA device mappings in docker-compose.yml
2. Install nvidia-docker2 on host
3. Supported codecs: H.264, HEVC, AV1 (RTX 40xx series)

#### Intel GPU (QSV/VA-API)
1. Uncomment Intel device mappings in docker-compose.yml
2. Add user to video group: `sudo usermod -a -G video $USER`
3. Supported codecs: H.264, HEVC, AV1 (12th gen+)

#### AMD GPU (AMF)
1. Install AMD drivers with AMF support
2. Configure VA-API for hardware acceleration

## Default Access URLs

### Media Services
- Jellyfin: `https://jellyfin.yourdomain.com`
- Overseerr: `https://overseerr.yourdomain.com`
- Tautulli: `https://tautulli.yourdomain.com`

### Management Services
- Sonarr: `https://sonarr.yourdomain.com`
- Radarr: `https://radarr.yourdomain.com`
- Lidarr: `https://lidarr.yourdomain.com`
- Readarr: `https://readarr.yourdomain.com`
- Prowlarr: `https://prowlarr.yourdomain.com`
- Bazarr: `https://bazarr.yourdomain.com`

### Download & Processing
- qBittorrent: `https://qbittorrent.yourdomain.com`
- HandBrake: `https://handbrake.yourdomain.com`
- MKVToolNix: `https://mkvtoolnix.yourdomain.com`
## Recommended Add-on Apps

- **Photoprism:** Self-hosted photo management and backup.
- **Audiobookshelf:** Organize and stream audiobooks.
- **Calibre Web:** Manage and read eBooks in your browser.
- **Podgrab:** Automatically download podcast episodes.
- **YTDL-Material:** Save online videos directly to your library.
