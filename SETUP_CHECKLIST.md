# ✅ Media Stack Setup Checklist

_Last updated: July 2025_

*Print this checklist and check off each step as you complete it*

---

## 🎯 PRE-SETUP REQUIREMENTS

### Hardware & Software
- [ ] **Computer/Server Ready** 
  - [ ] Linux, Windows, or macOS
  - [ ] 8GB+ RAM recommended
  - [ ] 100GB+ free space (for Docker & temp files)
  - [ ] Ethernet connection (Wi-Fi works but slower)

- [ ] **Storage Prepared**
  - [ ] External USB drive (4TB+ recommended)
  - [ ] OR internal drive with plenty of space
  - [ ] Drive formatted (NTFS/ext4/APFS)

- [ ] **Network Access**
  - [ ] Router admin access (for port forwarding, only if using external access)
  - [ ] Know your router IP (usually `192.168.1.1`)
  - [ ] Internet connection working
  - [ ] Decide: Local only or Cloudflare remote access

### Accounts & Services
- [ ] **Domain Name Purchased** *(only for external access)*
  - [ ] From Namecheap, Cloudflare, or other registrar
  - [ ] Example: `media-yourname.com`
  - [ ] Cost: ~$10-15/year

- [ ] **Cloudflare Account Created** *(only for external access)*
  - [ ] Free account at [cloudflare.com](https://cloudflare.com)
  - [ ] Domain added to Cloudflare
  - [ ] Nameservers changed (may take 24 hours)

---

## 🛠️ STEP 1: INSTALL DOCKER

### Linux (Ubuntu/Debian)
- [ ] **Update System**: `sudo apt update && sudo apt upgrade -y`
- [ ] **Install Docker**: `curl -fsSL https://get.docker.com | sudo sh`
- [ ] **Add User to Group**: `sudo usermod -aG docker $USER`
- [ ] **Install Compose**: `sudo apt install docker-compose-plugin`
- [ ] **Logout/Login**: To apply group changes
- [ ] **Test Docker**: `docker run hello-world`
  - [ ] ✅ Should show "Hello from Docker!"

### Windows
- [ ] **Download Docker Desktop**: From [docker.com](https://docker.com)
- [ ] **Install and Restart**: Computer
- [ ] **Enable WSL2**: When prompted
- [ ] **Test Docker**: `docker run hello-world` in PowerShell

### macOS
- [ ] **Download Docker Desktop**: From [docker.com](https://docker.com)
- [ ] **Install and Start**: Docker Desktop
- [ ] **Test Docker**: `docker run hello-world` in Terminal

---

## 🌐 STEP 2: CLOUDFLARE SETUP

*Skip this entire step if you selected **Local Only** during the installer.*

### Get API Token
- [ ] **Login to Cloudflare**: [dash.cloudflare.com](https://dash.cloudflare.com)
- [ ] **Go to API Tokens**: Profile → API Tokens
- [ ] **Create Token**: Use "Edit zone DNS" template
- [ ] **Configure Zone**: Include → Specific zone → your domain
- [ ] **Save Token**: Copy and save securely
  - [ ] Example: `1234567890abcdef1234567890abcdef12345678`

### Verify Domain Setup
- [ ] **Domain Listed**: In Cloudflare dashboard
- [ ] **Status Active**: Green checkmark next to domain
- [ ] **SSL/TLS**: Set to "Full (strict)" (SSL/TLS tab)

---

## 📁 STEP 3: PREPARE STORAGE

### Create Directory Structure

**Linux/macOS**:
- [ ] **Create Media Dirs**: 
  ```bash
  sudo mkdir -p /media/{movies,tv,music,books,anime,documentaries,4k}
  ```
- [ ] **Create Download Dirs**: 
  ```bash
  sudo mkdir -p /downloads/{complete,incomplete,convert-input,convert-output}
  ```
- [ ] **Set Permissions**: 
  ```bash
  sudo chown -R 1000:1000 /media /downloads
  sudo chmod -R 755 /media /downloads
  ```

**Windows**:
- [ ] **Create Directories**: 
  ```
  C:\MediaStack\media\movies
  C:\MediaStack\media\tv
  C:\MediaStack\downloads\complete
  C:\MediaStack\downloads\incomplete
  ```

### External Drive Setup (Optional but Recommended)
- [ ] **Connect External Drive**: USB 3.0+ recommended
- [ ] **Mount Drive**: 
  - Linux: `sudo mount /dev/sdb1 /mnt/media-drive`
  - Windows: Note drive letter (e.g., `D:\`)
- [ ] **Create Folders on Drive**: Same structure as above
- [ ] **Update Paths**: Note new paths for later

---

## 📦 STEP 4: DOWNLOAD MEDIA STACK

### Get the Code
- [ ] **Open Terminal/PowerShell**: Navigate to home directory
- [ ] **Download Stack**: 
  ```bash
  # Option A: Git clone (if available)
  git clone [repository-url] media-stack
  
  # Option B: Download ZIP and extract
  ```
- [ ] **Enter Directory**: `cd media-stack`
- [ ] **Make Scripts Executable**: 
  ```bash
  chmod +x scripts/*.sh deploy.sh
  ```

---

## ⚙️ STEP 5: INITIAL CONFIGURATION

### Run Setup Wizard
- [ ] **Start Configuration**: `./scripts/env-manager.sh init`
- [ ] **Answer Questions**:
  - [ ] **Domain**: Enter your domain (e.g., `media.yourname.com`)
  - [ ] **Timezone**: Your timezone (e.g., `America/New_York`)
  - [ ] **User IDs**: Accept auto-detected values
  - [ ] **Cloudflare Email**: Your Cloudflare account email *(external access only)*
  - [ ] **API Token**: Paste your Cloudflare API token *(external access only)*

### Customize Paths (If Using External Drive)
- [ ] **Edit Configuration**: `nano .env`
- [ ] **Update Paths**: 
  ```bash
  # Example for external drive:
  MEDIA_PATH=/mnt/media-drive
  DOWNLOADS_PATH=/mnt/media-drive/downloads
  
  # Example for Windows:
  MEDIA_PATH=D:/media
  DOWNLOADS_PATH=D:/downloads
  ```
- [ ] **Save File**: Ctrl+X, Y, Enter

### Validate Configuration
- [ ] **Check Config**: `./scripts/env-manager.sh validate`
- [ ] **Fix Any Errors**: Follow error messages
- [ ] **Validation Passes**: ✅ Green "validation passed" message

---

## 🚀 STEP 6: DEPLOY MEDIA STACK

### Deploy Services
- [ ] **Deploy Everything**: `./deploy.sh deploy`
- [ ] **Watch Output**: Should see services starting
- [ ] **Wait for Completion**: Process takes 5-10 minutes
- [ ] **Check Status**: `./deploy.sh status`
  - [ ] All core services show "Up"

### Verify Local Access
- [ ] **Test Dashboard**: `curl -k https://localhost` (should get response)
- [ ] **Check Docker**: `docker ps` (should show ~10+ containers)
- [ ] **Check Logs**: `./deploy.sh logs` (should see startup messages)

---

## 🌍 STEP 7: CONFIGURE EXTERNAL ACCESS

### Add DNS Records
- [ ] **Get Public IP**: Visit [whatismyip.com](https://whatismyip.com)
- [ ] **Cloudflare DNS**: Go to DNS tab in Cloudflare
- [ ] **Add A Records**: Point each subdomain to your public IP

| Name | Type | Content | TTL |
|------|------|---------|-----|
| dashboard | A | [your-ip] | Auto |
| jellyfin | A | [your-ip] | Auto |
| status | A | [your-ip] | Auto |
| sonarr | A | [your-ip] | Auto |
| radarr | A | [your-ip] | Auto |
| qbittorrent | A | [your-ip] | Auto |
| overseerr | A | [your-ip] | Auto |
| tdarr | A | [your-ip] | Auto |

### Configure Router Port Forwarding
- [ ] **Access Router**: Go to router IP (usually `192.168.1.1`)
- [ ] **Find Port Forwarding**: Usually under Advanced/NAT
- [ ] **Get Local IP**: `ip addr` (Linux) or `ipconfig` (Windows)
- [ ] **Add Forwarding Rules**:
  - [ ] **Port 80** → Your computer's local IP
  - [ ] **Port 443** → Your computer's local IP
- [ ] **Save Settings**: And restart router if needed

### Test External Access
- [ ] **Wait 5 Minutes**: For DNS propagation
- [ ] **Test Dashboard**: `https://dashboard.yourdomain.com`
  - [ ] ✅ Should load your dashboard
- [ ] **Test from Phone**: Using mobile data (not Wi-Fi)

---

## 🔧 STEP 8: CONFIGURE SERVICES

### Configure qBittorrent (Download Client)
- [ ] **Access**: `https://qbittorrent.yourdomain.com`
- [ ] **Login**: 
  - [ ] Username: `admin`
  - [ ] Password: `adminadmin`
- [ ] **Change Password**: Tools → Options → Web UI
- [ ] **Set Download Path**: Options → Downloads → `/downloads/complete`
- [ ] **Set Incomplete Path**: `/downloads/incomplete`

### Configure NZBGet (Usenet Client)
- [ ] **Access**: `https://nzbget.yourdomain.com`
- [ ] **Login**:
  - [ ] Username: `nzbget`
  - [ ] Password: `nzbget`
- [ ] **Change credentials**: Security → Username & Password
- [ ] **Set download paths**:
  - [ ] Complete downloads: `/downloads/complete`
  - [ ] Incomplete downloads: `/downloads/incomplete`

### Configure Prowlarr (CRITICAL - DO THIS FIRST!)
- [ ] **Access**: `https://prowlarr.yourdomain.com`
- [ ] **Add Indexers**: Indexers → Add Indexer
  - [ ] **Add "1337x"**: Public tracker
  - [ ] **Add "RARBG"**: Public tracker (if available)
  - [ ] **Add "The Pirate Bay"**: Public tracker
  - [ ] **Test Each**: Click test button for green checkmark
- [ ] **Configure Apps**: Settings → Apps → Add Application
  - [ ] Will configure after getting API keys

### Configure Jellyfin (Media Server)
- [ ] **Access**: `https://jellyfin.yourdomain.com`
- [ ] **Setup Wizard**:
  - [ ] **Language**: Choose your language
  - [ ] **Create User**: Username `admin`, strong password
  - [ ] **Add Libraries**:
    - [ ] **Movies**: Content Type=Movies, Folder=`/data/movies`
    - [ ] **TV Shows**: Content Type=TV Shows, Folder=`/data/tv`
    - [ ] **Music**: Content Type=Music, Folder=`/data/music`
- [ ] **Enable Hardware Transcoding** (if GPU available):
  - [ ] Dashboard → Playbook → Hardware acceleration
  - [ ] Select: NVENC (NVIDIA) or QSV (Intel)

### Configure Sonarr (TV Shows)
- [ ] **Access**: `https://sonarr.yourdomain.com`
- [ ] **Copy API Key**: Settings → General → API Key
- [ ] **Add Download Client**: Settings → Download Clients → qBittorrent
  - [ ] **Host**: `qbittorrent`
  - [ ] **Port**: `8080`
  - [ ] **Username**: `admin`
  - [ ] **Password**: [your qBittorrent password]
- [ ] **Add Root Folder**: Settings → Media Management → `/tv`

### Configure Radarr (Movies)
- [ ] **Access**: `https://radarr.yourdomain.com`
- [ ] **Copy API Key**: Settings → General → API Key
- [ ] **Add Download Client**: Same as Sonarr
- [ ] **Add Root Folder**: `/movies`

### Configure Overseerr (Request Management)
- [ ] **Access**: `https://overseerr.yourdomain.com`
- [ ] **Connect Jellyfin**: `http://jellyfin:8096`
- [ ] **Create Admin**: Use your Jellyfin account
- [ ] **Add Services**:
  - [ ] **Sonarr**: `http://sonarr:8989` + API key
  - [ ] **Radarr**: `http://radarr:7878` + API key

---

## 🔑 STEP 9: CONFIGURE API KEYS

### Update Dashboard Integrations
- [ ] **Run API Setup**: `./scripts/env-manager.sh setup-api-keys`
- [ ] **Enter API Keys**: From each service (Settings → General)
  - [ ] **Jellyfin**: Dashboard → Advanced → API Keys
  - [ ] **Sonarr**: Settings → General → API Key
  - [ ] **Radarr**: Settings → General → API Key
  - [ ] **Prowlarr**: Settings → General → API Key
  - [ ] **Overseerr**: Settings → General → API Key

### Configure Prowlarr Apps
- [ ] **Back to Prowlarr**: Settings → Apps
- [ ] **Add Sonarr**: 
  - [ ] URL: `http://sonarr:8989`
  - [ ] API Key: [from Sonarr]
- [ ] **Add Radarr**: 
  - [ ] URL: `http://radarr:7878`
  - [ ] API Key: [from Radarr]
- [ ] **Sync Indexers**: Force sync to push indexers

### Restart for API Keys
- [ ] **Restart Stack**: `./deploy.sh restart`
- [ ] **Check Dashboard**: Should show live data now

---

## 🎬 STEP 10: TEST YOUR SETUP

### Test Automatic Downloads
- [ ] **Add TV Show**: In Sonarr, search and add a series
- [ ] **Add Movie**: In Radarr, search and add a movie
- [ ] **Check Activity**: Monitor Activity tabs for downloads
- [ ] **Verify qBittorrent**: Should show active downloads

### Test Request System
- [ ] **Access Overseerr**: `https://overseerr.yourdomain.com`
- [ ] **Request Movie**: Search and request something
- [ ] **Check Auto-Download**: Should appear in Radarr/qBittorrent

### Test Media Playback
- [ ] **Add Sample File**: Put a movie file in `/media/movies/`
- [ ] **Scan Library**: Jellyfin → Dashboard → Scan Libraries
- [ ] **Test Playback**: Play the movie in Jellyfin

---

## 🔧 STEP 11: OPTIMIZATION (OPTIONAL)

### Enable File Compression
- [ ] **Access Tdarr**: `https://tdarr.yourdomain.com`
- [ ] **Add Library**: Point to `/media/movies`
- [ ] **Enable Processing**: Use quality optimization flow
- [ ] **Monitor Progress**: Check transcoding queue

### Setup Monitoring
- [ ] **Access Status Page**: `https://status.yourdomain.com`
- [ ] **Configure Alerts**: Add email/Discord notifications
- [ ] **Test Alerts**: Trigger test notification

### Performance Tuning
- [ ] **Enable GPU**: `./scripts/env-manager.sh enable-gpu` (if available)
- [ ] **Adjust Workers**: Edit CPU/GPU worker counts in `.env`
- [ ] **Monitor Resources**: Check CPU/RAM usage

---

## ✅ FINAL VERIFICATION

### All Services Accessible
- [ ] **Dashboard**: `https://dashboard.yourdomain.com` ✅
- [ ] **Jellyfin**: `https://jellyfin.yourdomain.com` ✅
- [ ] **Overseerr**: `https://overseerr.yourdomain.com` ✅
- [ ] **Status**: `https://status.yourdomain.com` ✅

### Core Functions Working
- [ ] **Downloads**: Can add content and it downloads ✅
- [ ] **Requests**: Family can request through Overseerr ✅
- [ ] **Playback**: Can watch content in Jellyfin ✅
- [ ] **Monitoring**: System health monitoring active ✅

### Security Checklist
- [ ] **Passwords Changed**: qBittorrent, Jellyfin admin ✅
- [ ] **HTTPS Working**: All services use SSL ✅
- [ ] **API Keys**: All dashboard integrations working ✅
- [ ] **Backups**: Configuration backed up ✅

---

## 🎉 CONGRATULATIONS!

**You now have a complete, professional media server!** 🎬

### What You Can Do Now:
✅ **Stream movies/TV** anywhere in the world  
✅ **Auto-download** new episodes and movies  
✅ **Accept requests** from family and friends  
✅ **Monitor everything** with professional dashboard  
✅ **Save storage** with automatic compression  
✅ **Scale up** by adding more drives or features  

### Share with Family:
- **Watch**: `https://jellyfin.yourdomain.com`
- **Request**: `https://overseerr.yourdomain.com`

### Monthly Maintenance:
- [ ] **Update Services**: `./deploy.sh update`
- [ ] **Check Storage**: Monitor disk space
- [ ] **Review Activity**: Check what's been downloaded
- [ ] **Backup Config**: `./scripts/env-manager.sh backup`

**Enjoy your new media server!** 🚀

---

*Estimated Setup Time: 4-6 hours for complete newbie*  
*Estimated Monthly Maintenance: 30 minutes*
## Recommended Add-on Apps

- **Photoprism:** Self-hosted photo management and backup.
- **Audiobookshelf:** Organize and stream audiobooks.
- **Calibre Web:** Manage and read eBooks in your browser.
- **Podgrab:** Automatically download podcast episodes.
- **YTDL-Material:** Save online videos directly to your library.
