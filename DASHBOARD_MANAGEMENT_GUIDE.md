# Dashboard Management Guide

_Last updated: July 2025_

This guide covers the comprehensive dashboard setup for managing your media stack with modern web interfaces and monitoring capabilities.

## Dashboard Overview

### Primary Dashboard: Homarr
- **URL**: `https://dashboard.yourdomain.com`
- **Features**: Modern interface, service integrations, real-time monitoring
- **Best For**: Daily management and overview


### Monitoring Dashboard: Uptime Kuma
- **URL**: `https://status.yourdomain.com`
- **Features**: Service health monitoring, status pages, alerting
- **Best For**: System monitoring and uptime tracking

## Quick Start

### 1. Enable Dashboard Services

```bash
# Start default dashboards (Homarr & Uptime Kuma)
docker compose up -d homarr uptime-kuma

# Enable auto-updates (optional)
docker compose --profile auto-update up -d
```

### 2. Configure DNS Records

Add these DNS A records in Cloudflare:
- `dashboard.yourdomain.com` → Your server IP
- `status.yourdomain.com` → Your server IP

### 3. Access Your Dashboards

- **Main Dashboard**: `https://dashboard.yourdomain.com`
- **System Status**: `https://status.yourdomain.com`

## Homarr Configuration

### Initial Setup

1. **Access Homarr**: Visit `https://dashboard.yourdomain.com`
2. **Complete Setup Wizard**: Follow the initial configuration
3. **Import Configuration**: Use the pre-configured layout from `config/homarr/default-config.yaml`

### Service Integration

#### Enable API Keys
To get full functionality, configure API keys for each service:

```bash
# Get API keys from each service web interface:
# Sonarr: Settings → General → API Key
# Radarr: Settings → General → API Key
# Jellyfin: Dashboard → Advanced → API Keys
# etc.

# Add to your .env file:
JELLYFIN_API_KEY=your_jellyfin_api_key
SONARR_API_KEY=your_sonarr_api_key
RADARR_API_KEY=your_radarr_api_key
# ... and so on
```

#### Widget Features
- **Real-time Statistics**: Library counts, file sizes, recent activity
- **Download Monitoring**: Active downloads, speeds, progress
- **System Resources**: CPU, memory, storage, network usage
- **Service Health**: Quick status indicators for all services

### Custom Widgets

Located in: `config/homarr/custom-widgets.js`

#### Media Library Statistics
- **Movies**: Count, total size, quality distribution
- **TV Shows**: Series count, episode count, storage usage
- **Music**: Albums, tracks, bitrate analysis
- **Books**: Collection size, format breakdown

#### Active Downloads Monitor
- **Real-time Progress**: Download speeds, ETA, completion status
- **Queue Management**: Priority adjustment, pause/resume
- **Storage Impact**: Space usage, download location status

#### System Resource Monitor
- **Hardware Status**: CPU usage, memory consumption, temperature
- **Storage Health**: Disk usage, I/O performance, SMART status
- **Network Activity**: Bandwidth usage, connection quality

## Dashboard Layout

### Recommended Layout

```yaml
Layout Structure:
┌─────────────────────────────────────┐
│           Header & Search           │
├─────────────────┬───────────────────┤
│  Media Services │  Content Mgmt     │
│  ├─ Jellyfin    │  ├─ Sonarr        │
│  ├─ Overseerr   │  ├─ Radarr        │
│  └─ Tautulli    │  ├─ Lidarr        │
│                 │  └─ Prowlarr      │
├─────────────────┼───────────────────┤
│  Downloads      │  System Tools     │
│  ├─ qBittorrent │  ├─ Tdarr         │
│  ├─ Downloads   │  ├─ HandBrake     │
│  └─ Processing  │  └─ Status        │
├─────────────────┴───────────────────┤
│            Widgets                  │
│  ┌─ Library Stats ─┬─ Downloads ─┐  │
│  └─ System Monitor ─┴─ Calendar ─┘  │
└─────────────────────────────────────┘
```

### Customization Options

#### Themes
- **Dark Mode**: Default theme optimized for 24/7 viewing
- **Light Mode**: Clean interface for daytime use
- **Custom CSS**: Personalized styling and branding

#### Categories
- **Media Services**: Core streaming and request management
- **Content Management**: Arr stack for automation
- **Downloads & Processing**: Download clients and converters
- **System Management**: Monitoring and maintenance tools

## Monitoring Setup

### Uptime Kuma Configuration

#### Service Monitors
Pre-configured monitors for all stack components:

| Service | Check Type | Interval | Purpose |
|---------|------------|----------|---------|
| Jellyfin | HTTP + API | 60s | Media server health |
| Sonarr/Radarr | API Status | 2m | Content management |
| qBittorrent | Web + API | 3m | Download client |
| Tdarr | HTTP Health | 5m | Processing status |
| Caddy Proxy | HTTPS | 1m | Reverse proxy health |

#### Status Page
Public status page available at: `https://status.yourdomain.com`

Features:
- **Service Groups**: Organized by function
- **Real-time Status**: Live updates and incident tracking
- **Historical Data**: Uptime statistics and trends
- **Maintenance Windows**: Scheduled downtime notifications

### Alert Configuration

#### Notification Channels
```bash
# Configure in .env file:
DISCORD_WEBHOOK_URL=your_discord_webhook
SMTP_HOST=smtp.gmail.com
SMTP_USERNAME=your_email@gmail.com
SMTP_PASSWORD=your_app_password
ALERT_EMAIL=admin@yourdomain.com
```

#### Alert Rules
- **Critical Services**: Immediate alerts (Jellyfin, Caddy)
- **Content Management**: 5-minute delay (Arr stack)
- **Processing Tools**: 10-minute delay (Tdarr, HandBrake)
- **Maintenance**: Scheduled silence periods

## Advanced Features

### Docker Integration

#### Container Management
- **Live Status**: Real-time container health
- **Resource Usage**: Per-container CPU and memory
- **Log Access**: Quick log viewing and troubleshooting
- **Start/Stop Control**: Container lifecycle management

#### Auto-Updates with Watchtower
```bash
# Enable automatic updates
docker-compose --profile auto-update up -d watchtower
```

Features:
- **Daily Checks**: Automatic image updates
- **Cleanup**: Remove old images after updates
- **Notifications**: Update completion alerts
- **Rollback**: Quick recovery from failed updates

### Performance Optimization

#### Dashboard Performance
- **Caching**: API response caching for faster loading
- **Lazy Loading**: Widgets load on demand
- **Compression**: Optimized asset delivery
- **CDN Ready**: Static asset optimization

#### Resource Monitoring
- **Real-time Metrics**: CPU, memory, network, storage
- **Historical Trends**: Performance over time
- **Threshold Alerts**: Automated notifications
- **Capacity Planning**: Growth trend analysis

## Troubleshooting

### Common Issues

#### Dashboard Not Loading
```bash
# Check container status
docker-compose logs homarr

# Verify network connectivity
docker exec homarr ping jellyfin

# Check SSL certificates
docker-compose logs caddy
```

#### API Integration Failures
1. **Verify API Keys**: Check service settings
2. **Network Access**: Ensure internal connectivity
3. **Service Status**: Confirm target services are running
4. **Firewall Rules**: Check internal network access

#### Slow Performance
1. **Resource Allocation**: Increase container resources
2. **Widget Refresh**: Reduce update frequencies
3. **Database Optimization**: Clean old monitoring data
4. **Network Latency**: Optimize internal routing

### Maintenance Tasks

#### Weekly Tasks
- **Review Status Page**: Check for any recurring issues
- **Update Dashboard Config**: Add new services or widgets
- **Clean Monitoring Data**: Remove old logs and metrics
- **Test Alerts**: Verify notification channels

#### Monthly Tasks
- **Performance Review**: Analyze dashboard metrics
- **Configuration Backup**: Export dashboard settings
- **Security Audit**: Review access logs and permissions
- **Capacity Planning**: Assess resource requirements


## Security Considerations

### Access Control
- **HTTPS Only**: All dashboard access over SSL
- **Internal Networks**: Services communicate internally
- **API Key Protection**: Secure storage and rotation
- **Reverse Proxy**: Single point of SSL termination

### Best Practices
1. **Regular Updates**: Keep dashboard containers updated
2. **Strong Passwords**: Use complex authentication
3. **Network Segmentation**: Isolate from other services
4. **Audit Logs**: Monitor access and changes
5. **Backup Configuration**: Regular config exports

This comprehensive dashboard setup provides a professional interface for managing your entire media stack with real-time monitoring, intuitive controls, and extensive customization options.
## Recommended Add-on Apps

- **Photoprism:** Self-hosted photo management and backup.
- **Audiobookshelf:** Organize and stream audiobooks.
- **Calibre Web:** Manage and read eBooks in your browser.
- **Podgrab:** Automatically download podcast episodes.
- **YTDL-Material:** Save online videos directly to your library.
