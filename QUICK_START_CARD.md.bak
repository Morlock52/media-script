# 🚀 Quick Start Card - Media Stack Setup

_Last updated: June 2025_

*Print this card and keep it handy during setup!*

## ✅ Pre-Setup Checklist

- [ ] **Domain purchased** (e.g., `media.yourname.com`)
- [ ] **Cloudflare account** created and domain added
- [ ] **Cloudflare API token** obtained
- [ ] **Docker installed** and tested (`docker run hello-world`)
- [ ] **Storage prepared** (external drive recommended)
- [ ] **Router access** (for port forwarding)

## 🎯 Essential Commands

```bash
# Initialize setup (first time)
./scripts/env-manager.sh init

# Deploy everything
./deploy.sh deploy

# Check status
./deploy.sh status

# View logs
./deploy.sh logs

# Update services
./deploy.sh update

# Stop everything
./deploy.sh stop
```

## 🌐 Your Service URLs

Replace `yourdomain.com` with your actual domain:

| Service | URL | Purpose |
|---------|-----|---------|
| **Dashboard** | `https://dashboard.yourdomain.com` | Main control panel |
| **Jellyfin** | `https://jellyfin.yourdomain.com` | Watch movies/TV |
| **Requests** | `https://overseerr.yourdomain.com` | Request new content |
| **Status** | `https://status.yourdomain.com` | System health |
| **Downloads** | `https://qbittorrent.yourdomain.com` | Download manager |

## 📁 Important File Paths

**Configuration**: `./config/`  
**Movies**: `/media/movies/` (or your external drive)  
**TV Shows**: `/media/tv/`  
**Downloads**: `/downloads/`  
**Logs**: Use `./deploy.sh logs [service]`

## 🔑 Default Credentials

| Service | Username | Password |
|---------|----------|----------|
| **qBittorrent** | `admin` | `adminadmin` |
| **Jellyfin** | Create during setup | [Your choice] |

⚠️ **Change these immediately after first login!**

## 🆘 Emergency Commands

```bash
# Something broken? Try this first:
./deploy.sh restart

# Still broken? Check what's wrong:
./deploy.sh status
./deploy.sh logs

# Nuclear option (restart everything):
./deploy.sh stop
./deploy.sh deploy
```

## 📞 Quick Troubleshooting

**Can't access services?** → Check DNS records in Cloudflare  
**Downloads not working?** → Configure Prowlarr indexers first  
**Jellyfin empty?** → Add media files and scan library  
**Slow performance?** → Check Docker has enough RAM  
**Permission errors?** → Run: `sudo chown -R 1000:1000 /media /downloads`

## 🎯 Setup Order (DO IN THIS ORDER!)

1. **Install Docker** → Test with `docker run hello-world`
2. **Get Domain** → Buy and add to Cloudflare  
3. **Get API Token** → From Cloudflare dashboard
4. **Prepare Storage** → Create directories or mount external drive
5. **Run Setup** → `./scripts/env-manager.sh init`
6. **Deploy Stack** → `./deploy.sh deploy`
7. **Configure DNS** → Add A records in Cloudflare
8. **Port Forward** → Router: ports 80 and 443 to your PC
9. **Configure Prowlarr** → Add indexers FIRST
10. **Configure Others** → Sonarr, Radarr, qBittorrent
11. **Add API Keys** → `./scripts/env-manager.sh setup-api-keys`
12. **Test Everything** → Request a movie in Overseerr

## 💡 Pro Tips

- **Start Small**: Add 1-2 indexers, test with 1 movie
- **Use External Drive**: Prevents filling up main drive
- **Enable GPU**: Massive performance boost if available
- **Set Up Monitoring**: Discord/email alerts for issues
- **Regular Updates**: `./deploy.sh update` monthly

---

**Need detailed help?** See `COMPLETE_NEWBIE_GUIDE.md`  
**Having issues?** See `TROUBLESHOOTING_FLOWCHART.md`