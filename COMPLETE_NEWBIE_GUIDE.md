# Complete Newbie Setup Guide

_Last updated: June 2025_

This guide will walk you through setting up a complete media server stack from scratch. No prior experience required!

## 📋 What You'll Get

By the end of this guide, you'll have:
- **Jellyfin**: Stream your movies, TV shows, music anywhere
- **Automatic Downloads**: TV shows and movies download automatically
- **Request System**: Family can request new content via web interface
- **Professional Dashboard**: Manage everything from one place
- **Secure Access**: HTTPS with your own domain
- **Optimized Storage**: Automatically compress files to save space

## 🎯 Prerequisites

### What You Need
1. **A Computer/Server** running Linux, Windows, or macOS
2. **A Domain Name** (e.g., `media.example.com`) - $10-15/year
3. **Cloudflare Account** (free) - for SSL certificates
4. **Basic Storage** - External drive or NAS for your media
5. **Internet Connection** - For downloading content and remote access

### Example Hardware Recommendations

#### Budget Setup ($300-500)
- **Mini PC**: Intel NUC or similar
- **Storage**: 4TB External USB Drive
- **RAM**: 8GB minimum
- **Network**: Ethernet connection preferred

#### Enthusiast Setup ($800-1500)
- **Custom PC**: AMD Ryzen 5 or Intel i5
- **Storage**: 2x 8TB HDDs in RAID
- **GPU**: NVIDIA RTX 4060 (for transcoding)
- **RAM**: 16GB+

#### Advanced Setup ($2000+)
- **Server**: Dedicated server or powerful NAS
- **Storage**: Multiple large drives with redundancy
- **GPU**: RTX 4070+ for multiple streams
- **Network**: 10Gb networking

## 🚀 Step 1: Initial Setup

### Install Docker (Required)

#### On Ubuntu/Debian:
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt install docker-compose-plugin

# Logout and login again for group changes
```

#### On Windows:
1. Download [Docker Desktop](https://www.docker.com/products/docker-desktop/)
2. Install and restart your computer
3. Enable WSL2 when prompted
4. Open PowerShell as Administrator

#### On macOS:
1. Download [Docker Desktop](https://www.docker.com/products/docker-desktop/)
2. Install and start Docker Desktop
3. Open Terminal

### Verify Docker Installation
```bash
# Check Docker version
docker --version

# Check Docker Compose
docker compose version

# Test Docker works
docker run hello-world
```

You should see: `Hello from Docker!`

## 🌐 Step 2: Domain and DNS Setup

### Get a Domain Name
1. Go to [Namecheap](https://namecheap.com) or [Cloudflare](https://cloudflare.com)
2. Search for and buy a domain (e.g., `yourname-media.com`)
3. Cost: ~$10-15/year

### Setup Cloudflare (Free SSL)
1. **Create Account**: Go to [Cloudflare.com](https://cloudflare.com) and sign up
2. **Add Domain**: Click "Add Site" and enter your domain
3. **Change Nameservers**: 
   - Cloudflare will show you 2 nameservers
   - Go to your domain registrar (Namecheap, etc.)
   - Change nameservers to the ones Cloudflare provided
   - Wait 24 hours for propagation

### Get Cloudflare API Token
1. **Go to API Tokens**: [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens)
2. **Create Token**: Click "Create Token"
3. **Use Template**: Choose "Edit zone DNS"
4. **Configure**:
   - Zone Resources: Include → Specific zone → your domain
   - Account Resources: Include → All accounts
5. **Save the Token**: You'll need this later!

**Example Token**: `1234567890abcdef1234567890abcdef12345678`

## 📁 Step 3: Prepare Your Storage

### Create Directory Structure

#### Linux/macOS:
```bash
# Create main directories
sudo mkdir -p /media/{movies,tv,music,books,anime,documentaries,4k}
sudo mkdir -p /downloads/{complete,incomplete,convert-input,convert-output}

# Set permissions (replace 1000 with your user ID)
id  # Shows your user ID
sudo chown -R 1000:1000 /media /downloads
sudo chmod -R 755 /media /downloads
```

#### Windows (using WSL2):
```bash
# In PowerShell as Administrator
mkdir C:\MediaStack\media\movies, C:\MediaStack\media\tv, C:\MediaStack\media\music
mkdir C:\MediaStack\downloads\complete, C:\MediaStack\downloads\incomplete

# Note the paths for later: C:\MediaStack\media and C:\MediaStack\downloads
```

### External Drive Setup (Recommended)

#### Mount External Drive (Linux):
```bash
# Find your drive
lsblk

# Example output:
# sdb1    8:17   0  3.7T  0 part
# This is your 4TB external drive

# Create mount point
sudo mkdir /mnt/media-drive

# Mount the drive
sudo mount /dev/sdb1 /mnt/media-drive

# Make it permanent
echo '/dev/sdb1 /mnt/media-drive ext4 defaults 0 0' | sudo tee -a /etc/fstab

# Create your media directories on the external drive
sudo mkdir -p /mnt/media-drive/{movies,tv,music,books}
sudo chown -R 1000:1000 /mnt/media-drive
```

**Update your paths** to use `/mnt/media-drive` instead of `/media`

## 📦 Step 4: Download and Setup Media Stack

### Download the Media Stack
```bash
# Go to your home directory
cd ~

# Download the media stack
git clone https://github.com/your-repo/media-stack.git
# OR download and extract the ZIP file

cd media-stack
```

### Run Initial Setup
```bash
# Make scripts executable
chmod +x scripts/*.sh deploy.sh

# Initialize your environment
./scripts/env-manager.sh init
```

The script will ask you questions. Here are example answers:

```
Enter your domain: media.yourname.com
Enter your timezone: America/New_York  (or your timezone)
Update PUID/PGID to match your user? Y
Enter your Cloudflare email: you@email.com
Enter your Cloudflare API token: [paste your token from Step 2]
```

### Customize Your Paths (If Using External Drive)
```bash
# Edit the configuration
nano .env

# Find these lines and update them:
MEDIA_PATH=/mnt/media-drive          # Your external drive path
DOWNLOADS_PATH=/mnt/media-drive/downloads
```

## 🔧 Step 5: Deploy Your Media Stack

### Deploy with Auto-Detection
```bash
# Deploy everything automatically
./deploy.sh deploy

# OR deploy with extra features
./deploy.sh deploy --with-alternatives --with-auto-update
```

You'll see output like:
```
[2025-06-01 12:00:15] Detecting GPU capabilities...
NVIDIA GPU detected: GeForce RTX 4060
[2025-06-01 12:00:16] Enabling NVIDIA GPU acceleration
[2025-06-01 12:00:17] Creating necessary directories...
[2025-06-01 12:00:18] Pulling latest Docker images...
[2025-06-01 12:00:45] Starting services...
[2025-06-01 12:01:00] All core services are healthy

🎬 MEDIA STACK DEPLOYMENT COMPLETE
```

### Check Everything is Working
```bash
# Check service status
./deploy.sh status

# Should show all services as "Up"
```

## 🌍 Step 6: Configure DNS Records

### Add DNS Records in Cloudflare
1. **Go to DNS**: In Cloudflare dashboard, click "DNS"
2. **Add A Records**: For each subdomain, add an A record pointing to your public IP

**Find Your Public IP**: Go to [whatismyip.com](https://whatismyip.com)

**Add these A records** (replace `1.2.3.4` with your IP):

| Type | Name | Content | TTL |
|------|------|---------|-----|
| A | dashboard | 1.2.3.4 | Auto |
| A | jellyfin | 1.2.3.4 | Auto |
| A | status | 1.2.3.4 | Auto |
| A | sonarr | 1.2.3.4 | Auto |
| A | radarr | 1.2.3.4 | Auto |
| A | qbittorrent | 1.2.3.4 | Auto |
| A | overseerr | 1.2.3.4 | Auto |
| A | tdarr | 1.2.3.4 | Auto |

### Configure Router Port Forwarding
1. **Access Router**: Go to `192.168.1.1` (or your router IP)
2. **Find Port Forwarding**: Usually under "Advanced" or "NAT"
3. **Add Rules**:
   - **Port 80** → Your computer's local IP
   - **Port 443** → Your computer's local IP

**Find Your Local IP**:
```bash
# Linux/macOS
ip addr | grep "inet " | grep -v 127.0.0.1

# Windows
ipconfig
```

Example: If your computer is `192.168.1.100`, forward ports 80 and 443 to that IP.

## ⚙️ Step 7: Initial Service Configuration

### Access Your Dashboard
Go to: `https://dashboard.yourdomain.com`

You should see your beautiful dashboard!

### Configure Jellyfin (Media Server)
1. **Access**: `https://jellyfin.yourdomain.com`
2. **Setup Wizard**:
   - Choose your language
   - Create admin user: `admin` / `[secure-password]`
   - Add Media Libraries:

#### Add Movie Library:
- **Content Type**: Movies
- **Display Name**: Movies
- **Folder**: `/data/movies`
- **Language**: English (or your preference)

#### Add TV Library:
- **Content Type**: TV Shows
- **Display Name**: TV Shows  
- **Folder**: `/data/tv`

#### Add Music Library:
- **Content Type**: Music
- **Display Name**: Music
- **Folder**: `/data/music`

3. **Enable Hardware Transcoding** (if you have a GPU):
   - Go to Dashboard → Playback
   - **Hardware acceleration**: NVENC (NVIDIA) or QSV (Intel)
   - **Enable hardware decoding**: Check all boxes

### Configure Download Client (qBittorrent)
1. **Access**: `https://qbittorrent.yourdomain.com`
2. **Login**: 
   - Username: `admin`
   - Password: `adminadmin`
3. **Change Password**:
   - Go to Tools → Options → Web UI
   - Change password to something secure
4. **Configure Paths**:
   - Default Save Path: `/downloads/complete`
   - Incomplete downloads: `/downloads/incomplete`

### Configure Prowlarr (Indexer Manager) - Do This First!
1. **Access**: `https://prowlarr.yourdomain.com`
2. **Add Indexers**:
   - Go to Indexers → Add Indexer
   - **Public Trackers**: Add "1337x", "RARBG", "The Pirate Bay"
   - **Private Trackers**: Add any you have accounts for
3. **Add Applications**:
   - Go to Settings → Apps → Add Application
   - Add Sonarr, Radarr, Lidarr with their API keys (get from each app's settings)

### Configure Sonarr (TV Shows)
1. **Access**: `https://sonarr.yourdomain.com`
2. **Get API Key**: Settings → General → API Key (copy this)
3. **Add Download Client**:
   - Settings → Download Clients → Add → qBittorrent
   - **Host**: `qbittorrent`
   - **Port**: `8080`
   - **Username**: `admin`
   - **Password**: [your qBittorrent password]
4. **Add Root Folder**:
   - Settings → Media Management → Add Root Folder
   - **Path**: `/tv`

### Configure Radarr (Movies)
1. **Access**: `https://radarr.yourdomain.com`
2. **Get API Key**: Settings → General → API Key (copy this)
3. **Add Download Client**: Same as Sonarr
4. **Add Root Folder**: `/movies`

### Configure Overseerr (Request Management)
1. **Access**: `https://overseerr.yourdomain.com`
2. **Setup Wizard**:
   - **Jellyfin**: Configure connection to `http://jellyfin:8096`
   - **Admin Account**: Use your Jellyfin account
3. **Add Services**:
   - **Sonarr**: `http://sonarr:8989` + API key
   - **Radarr**: `http://radarr:7878` + API key

## 🔑 Step 8: Configure API Keys in Dashboard

### Set Up Dashboard Integrations
```bash
# Interactive API key setup
./scripts/env-manager.sh setup-api-keys
```

For each service, go to the URL and get the API key:

#### Get API Keys:
1. **Jellyfin**: Dashboard → Advanced → API Keys → Create New Key
2. **Sonarr**: Settings → General → API Key (copy)
3. **Radarr**: Settings → General → API Key (copy)
4. **Prowlarr**: Settings → General → API Key (copy)
5. **Overseerr**: Settings → General → API Key (copy)
6. **Tautulli**: Settings → Web Interface → API Key (copy)

#### Update Configuration:
```bash
# Edit your environment file
nano .env

# Add your API keys:
JELLYFIN_API_KEY=abc123def456...
SONARR_API_KEY=def456ghi789...
RADARR_API_KEY=ghi789jkl012...
# etc.

# Restart to apply changes
./deploy.sh restart
```

## 📚 Step 9: Add Your First Content

### Method 1: Manual Addition
1. **Copy Files**: Put movie files in `/media/movies/` (or your external drive)
2. **Scan Library**: In Jellyfin → Dashboard → Libraries → Scan All Libraries

### Method 2: Automatic Downloads
1. **Add TV Show in Sonarr**:
   - Go to `https://sonarr.yourdomain.com`
   - Click "Add Series"
   - Search for a show (e.g., "Breaking Bad")
   - Choose quality profile
   - Click "Add Series"

2. **Add Movie in Radarr**:
   - Go to `https://radarr.yourdomain.com`
   - Click "Add Movie"
   - Search for a movie
   - Choose quality profile
   - Click "Add Movie"

### Method 3: Family Requests
1. **Share Overseerr**: Give family access to `https://overseerr.yourdomain.com`
2. **They can request**: Movies and TV shows
3. **Auto-approved**: Configure auto-approval for trusted users

## 📊 Step 10: Monitor Your System

### Check System Status
- **Dashboard**: `https://dashboard.yourdomain.com` - Overview of everything
- **System Status**: `https://status.yourdomain.com` - Uptime monitoring
- **Tautulli**: `https://tautulli.yourdomain.com` - Viewing statistics

### Monitor Downloads
- **qBittorrent**: `https://qbittorrent.yourdomain.com` - Active downloads
- **Sonarr/Radarr Activity**: Check the Activity tab for download progress

## 🔧 Step 11: Optimization Setup

### Enable File Compression (Tdarr)
1. **Access**: `https://tdarr.yourdomain.com`
2. **Add Library**:
   - Library Name: "Movies"
   - Source: `/media/movies`
   - Cache: `/cache/movies`
3. **Configure Flow**:
   - Use "Quality-First Size Optimization" flow
   - Target: 50% size reduction while maintaining quality

### Set Up Monitoring Alerts
1. **Discord Notifications** (Optional):
   - Create Discord webhook in your server
   - Add webhook URL to `.env` file:
     ```bash
     DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...
     ```

2. **Email Notifications**:
   - Configure SMTP settings in `.env`:
     ```bash
     SMTP_HOST=smtp.gmail.com
     SMTP_USERNAME=your-email@gmail.com
     SMTP_PASSWORD=your-app-password
     ```

## 🎯 Common Beginner Scenarios

### Scenario 1: Family Movie Night
**Problem**: "I want to add the latest Marvel movie for tonight"

**Solution**:
1. Go to `https://overseerr.yourdomain.com`
2. Search for the movie
3. Click "Request"
4. It will auto-download and appear in Jellyfin within 1-2 hours

### Scenario 2: Binge-Watching a Series
**Problem**: "I want all seasons of The Office"

**Solution**:
1. Go to `https://sonarr.yourdomain.com`
2. Search "The Office"
3. Select series and choose "All Seasons"
4. Click "Add Series"
5. Episodes will download automatically as they become available

### Scenario 3: Running Out of Space
**Problem**: "My drive is getting full"

**Solution**:
1. **Enable Tdarr**: Automatically compresses files (saves 40-60% space)
2. **Clean Old Downloads**: qBittorrent can auto-delete after seeding
3. **Add More Storage**: External drives can be added anytime

### Scenario 4: Remote Access
**Problem**: "I want to watch my content while traveling"

**Solution**:
- Access `https://jellyfin.yourdomain.com` from anywhere
- Mobile apps available for iOS/Android
- Automatic transcoding for slower connections

## 🚨 Troubleshooting Guide

### Problem: Can't Access Services
**Check**:
```bash
# Are services running?
./deploy.sh status

# Check logs
./deploy.sh logs

# Check Docker
docker ps
```

**Solution**: Usually DNS or port forwarding issue

### Problem: Downloads Not Working
**Check**:
1. **Prowlarr**: Are indexers working? (Test them)
2. **qBittorrent**: Is it connected in Sonarr/Radarr?
3. **Permissions**: Can services write to download folder?

**Fix**:
```bash
# Fix permissions
sudo chown -R 1000:1000 /downloads
```

### Problem: Jellyfin Not Finding Media
**Check**:
1. **File naming**: Use proper naming (Plex naming guide)
2. **Permissions**: Can Jellyfin read the files?
3. **Library scan**: Force a library scan

**Example Good Naming**:
```
Movies/
  Avatar (2009)/
    Avatar (2009).mkv
    
TV Shows/
  Breaking Bad/
    Season 01/
      Breaking Bad - S01E01 - Pilot.mkv
```

### Problem: Slow Performance
**Solutions**:
1. **Enable GPU**: For transcoding (if available)
2. **Increase RAM**: Docker containers need memory
3. **Use SSD**: For Docker and temp files
4. **Reduce Quality**: Lower bitrate for remote streaming

## 📱 Mobile Apps

### Jellyfin Apps
- **iOS**: "Jellyfin Mobile" (App Store)
- **Android**: "Jellyfin for Android" (Play Store)
- **TV**: Available for Apple TV, Android TV, Roku, etc.

### Request Apps (Overseerr)
- Use any web browser on mobile
- Add to home screen for app-like experience

## 🔒 Security Best Practices

### Change Default Passwords
```bash
# qBittorrent: admin/adminadmin → admin/[strong-password]
# Jellyfin: Create strong admin password
# Router: Change from admin/admin
```

### Enable 2FA (Recommended)
- **Cloudflare**: Enable 2FA on your account
- **Email**: Use 2FA on email used for alerts

### Regular Updates
```bash
# Update monthly
./deploy.sh update
```

## 🎉 Congratulations!

You now have a complete, professional media server that:

✅ **Automatically downloads** TV shows and movies  
✅ **Serves content** to any device, anywhere  
✅ **Optimizes storage** by compressing files  
✅ **Monitors health** and sends alerts  
✅ **Accepts requests** from family/friends  
✅ **Uses HTTPS** with valid SSL certificates  
✅ **Looks professional** with a modern dashboard  

## 📞 Getting Help

### If Something Goes Wrong:
1. **Check the logs**: `./deploy.sh logs [service-name]`
2. **Validate config**: `./scripts/env-manager.sh validate`
3. **Check status**: `./deploy.sh status`
4. **Restart services**: `./deploy.sh restart`

### Community Resources:
- **Jellyfin**: [jellyfin.org/docs](https://jellyfin.org/docs)
- **Sonarr**: [wiki.servarr.com/sonarr](https://wiki.servarr.com/sonarr)
- **Radarr**: [wiki.servarr.com/radarr](https://wiki.servarr.com/radarr)

### Example First Month Journey:

**Week 1**: Set up and add 10 favorite movies  
**Week 2**: Add 3 TV series, invite family to Overseerr  
**Week 3**: Enable Tdarr to save space, set up monitoring  
**Week 4**: Fine-tune quality settings, add more indexers  

**Result**: Professional media server that rivals Netflix! 🎬✨

---

**Time Investment**: 4-6 hours initial setup, then 30 minutes/month maintenance  
**Cost**: $10-15/year domain + hardware (one-time)  
**Benefit**: Unlimited movies/TV shows for the whole family! 🚀