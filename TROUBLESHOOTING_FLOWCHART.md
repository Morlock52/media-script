# 🔧 Troubleshooting Flowchart

_Last updated: June 2025_

*Follow this flowchart to solve 90% of issues quickly*

## 🚨 Something's Not Working?

### START HERE: Basic Health Check

```
1. Are you getting an error message?
   ├─ YES → Go to "ERROR MESSAGES" section
   └─ NO → Continue to step 2

2. Can you access the dashboard at https://dashboard.yourdomain.com?
   ├─ YES → Go to "SERVICES NOT WORKING" section  
   └─ NO → Go to "CAN'T ACCESS ANYTHING" section
```

---

## 🌐 CAN'T ACCESS ANYTHING

**Symptoms**: Can't reach any services, browser shows "site can't be reached"

### Check 1: DNS Records
```bash
# Test if DNS is working
nslookup dashboard.yourdomain.com

# Should return your public IP address
# If not, DNS is the problem
```

**Fix DNS**:
1. Go to Cloudflare Dashboard
2. Click "DNS" 
3. Verify A records exist for:
   - `dashboard.yourdomain.com` → Your public IP
   - `jellyfin.yourdomain.com` → Your public IP
   - etc.
4. Wait 5 minutes and try again

### Check 2: Port Forwarding
```bash
# Find your public IP
curl ifconfig.me

# Test if ports are open (from external network)
# Use https://www.yougetsignal.com/tools/open-ports/
# Test ports 80 and 443
```

**Fix Port Forwarding**:
1. Access your router (usually `192.168.1.1`)
2. Find "Port Forwarding" or "NAT"
3. Add rules:
   - Port 80 → Your computer's local IP
   - Port 443 → Your computer's local IP
4. Save and restart router

### Check 3: Local Network
```bash
# Find your local IP
ip addr | grep "inet " | grep -v 127.0.0.1

# Test local access
curl -k https://localhost

# If this works, it's a network issue
```

**Fix Local Network**:
1. Ensure your computer has a static local IP
2. Check firewall isn't blocking ports 80/443
3. Test from another device on same network

---

## ⚙️ SERVICES NOT WORKING

**Symptoms**: Dashboard loads but some services are down

### Check Service Status
```bash
# Check what's running
./deploy.sh status

# Look for services with "Exit" status
# Example output:
# jellyfin    Up 2 hours     ✅ Good
# sonarr      Exit 1         ❌ Problem
```

### Fix Failed Services
```bash
# Restart individual service
docker-compose restart sonarr

# Check logs for errors
./deploy.sh logs sonarr

# Look for error messages in the output
```

### Common Service Issues

#### Jellyfin Won't Start
**Symptoms**: Jellyfin shows "Exit" status

**Check**:
```bash
./deploy.sh logs jellyfin
```

**Common Causes**:
- **Permission Error**: `chown: cannot access '/config'`
  ```bash
  sudo chown -R 1000:1000 ./config/jellyfin
  ```
- **Port Conflict**: `bind: address already in use`
  ```bash
  # Check what's using port 8096
  sudo netstat -tulpn | grep 8096
  ```
- **Missing Directory**: `no such file or directory`
  ```bash
  mkdir -p /media/movies /media/tv
  ```

#### Download Services Not Working
**Symptoms**: Sonarr/Radarr can't connect to qBittorrent

**Check**:
```bash
# Test qBittorrent is accessible
curl -I http://localhost:8080

# Check qBittorrent logs
./deploy.sh logs qbittorrent
```

**Fix**:
1. Verify qBittorrent is running
2. Check username/password in Sonarr/Radarr settings
3. Use hostname `qbittorrent` not `localhost`

---

## 📥 DOWNLOADS NOT WORKING

**Symptoms**: Added movie/show but nothing downloads

### Check 1: Indexers (Most Common Issue)
```bash
# Access Prowlarr
https://prowlarr.yourdomain.com

# Go to Indexers tab
# All indexers should show green checkmarks
```

**Fix Indexers**:
1. **Test Each Indexer**: Click test button
2. **Remove Broken Ones**: Delete any with red X
3. **Add Working Ones**: Add "1337x", "RARBG" for public
4. **Configure Private**: If you have private tracker accounts

### Check 2: Prowlarr → *arr Connection
```bash
# In Prowlarr, go to Settings → Apps
# Should show Sonarr, Radarr with green checkmarks
```

**Fix App Connections**:
1. **Get API Keys**: From each service (Settings → General)
2. **Add Apps in Prowlarr**: Use internal hostnames (`sonarr:8989`)
3. **Sync Indexers**: Force sync to push indexers to apps

### Check 3: Quality Profiles
```bash
# In Sonarr/Radarr, check Quality Profiles
# Should have at least one profile enabled
```

**Fix Quality**:
1. **Edit Profile**: Allow multiple qualities
2. **Set Minimum**: Don't set too high (starts with 720p)
3. **Enable Upgrades**: Allow quality upgrades

---

## 🎬 JELLYFIN ISSUES

### Problem: No Content Shows Up
**Symptoms**: Jellyfin interface loads but libraries are empty

**Check**:
```bash
# Verify files exist
ls -la /media/movies/

# Check Jellyfin can read files
docker exec jellyfin ls -la /data/movies/
```

**Fix**:
1. **File Naming**: Use proper naming conventions
   ```
   Good: /media/movies/Avatar (2009)/Avatar (2009).mkv
   Bad:  /media/movies/avatar_2009_rip.avi
   ```
2. **Permissions**: Fix file permissions
   ```bash
   sudo chown -R 1000:1000 /media
   sudo chmod -R 755 /media
   ```
3. **Force Scan**: Dashboard → Libraries → Scan All Libraries

### Problem: Buffering/Stuttering
**Symptoms**: Video starts but keeps pausing to buffer

**Immediate Fix**:
1. **Lower Quality**: In Jellyfin player, reduce quality to 720p
2. **Enable Direct Play**: Turn off transcoding in settings

**Permanent Fix**:
1. **Enable GPU Transcoding**:
   ```bash
   ./scripts/env-manager.sh enable-gpu
   ./deploy.sh restart
   ```
2. **Increase Resources**:
   ```bash
   # Give Docker more RAM (Docker Desktop settings)
   # Recommended: 4GB minimum, 8GB preferred
   ```

---

## 🔑 PERMISSION PROBLEMS

**Symptoms**: "Permission denied" errors in logs

### Fix All Permissions
```bash
# Fix config directory
sudo chown -R 1000:1000 ./config
sudo chmod -R 755 ./config

# Fix media directories  
sudo chown -R 1000:1000 /media /downloads
sudo chmod -R 755 /media /downloads

# Fix specific Docker issues
sudo usermod -aG docker $USER
# Then logout and login again
```

### Check User IDs
```bash
# Check your user ID
id

# Should match PUID/PGID in .env file
grep PUID .env
```

---

## 💾 STORAGE ISSUES

### Problem: Running Out of Space
**Check Space**:
```bash
# Check disk usage
df -h

# Check Docker usage
docker system df
```

**Fix**:
1. **Enable Tdarr**: Automatic compression saves 40-60%
2. **Clean Downloads**: 
   ```bash
   # Remove completed downloads
   rm -rf /downloads/complete/*
   ```
3. **Docker Cleanup**:
   ```bash
   docker system prune -a
   ```

### Problem: External Drive Not Working
**Check Mount**:
```bash
# List mounted drives
mount | grep media

# Check if drive is detected
lsblk
```

**Fix**:
```bash
# Remount drive
sudo umount /mnt/media-drive
sudo mount /dev/sdb1 /mnt/media-drive

# Fix fstab if needed
sudo nano /etc/fstab
```

---

## 🌡️ PERFORMANCE ISSUES

### Problem: Everything is Slow
**Check Resources**:
```bash
# Check CPU/Memory usage
htop

# Check Docker stats
docker stats
```

**Quick Fixes**:
1. **Restart Everything**:
   ```bash
   ./deploy.sh stop
   ./deploy.sh deploy
   ```
2. **Reduce Concurrent Jobs**:
   ```bash
   # Edit .env file
   TDARR_CPU_WORKERS=1
   TDARR_GPU_WORKERS=0
   ```
3. **Free Up RAM**:
   ```bash
   # Close other applications
   # Restart computer if needed
   ```

---

## 🆘 NUCLEAR OPTIONS

### When All Else Fails

#### Option 1: Fresh Restart
```bash
# Stop everything
./deploy.sh stop

# Remove containers (keeps data)
docker-compose down

# Start fresh
./deploy.sh deploy
```

#### Option 2: Reset Single Service
```bash
# Stop service
docker-compose stop jellyfin

# Remove container
docker-compose rm jellyfin

# Remove config (WARNING: loses settings)
rm -rf ./config/jellyfin

# Restart
docker-compose up -d jellyfin
```

#### Option 3: Complete Reset (DANGER!)
```bash
# BACKUP FIRST!
./scripts/env-manager.sh backup

# Remove everything
docker-compose down
docker system prune -a -f

# Remove config (loses ALL settings)
rm -rf ./config

# Start over
./deploy.sh deploy
```

---

## 📋 Diagnostic Information Collection

When asking for help, collect this information:

```bash
# System info
uname -a
docker --version
docker-compose --version

# Service status
./deploy.sh status

# Recent logs
./deploy.sh logs --tail=50

# Environment check
./scripts/env-manager.sh validate

# Disk space
df -h

# Network test
curl -I https://dashboard.yourdomain.com
```

---

## 🎯 Most Common Issues (90% of problems)

1. **DNS not configured** → Add A records in Cloudflare
2. **Port forwarding missing** → Forward ports 80/443 in router
3. **No indexers in Prowlarr** → Add working indexers first
4. **Wrong API keys** → Copy exact keys from service settings
5. **Permission errors** → Run `sudo chown -R 1000:1000 /media /downloads`
6. **Out of disk space** → Enable Tdarr compression
7. **Weak hardware** → Reduce concurrent jobs, enable GPU
8. **Firewall blocking** → Allow ports 80/443 in firewall

**Remember**: 95% of issues are configuration, not bugs. Double-check your settings! 🔍