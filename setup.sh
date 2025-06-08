#!/bin/bash

# Media Stack Setup Script
# This script creates necessary directories and sets proper permissions

set -e

echo "🚀 Setting up Media Stack directories and permissions..."

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "❌ This script should not be run as root. Please run as your regular user."
   exit 1
fi

# Get user ID and group ID
USER_ID=$(id -u)
GROUP_ID=$(id -g)

echo "📋 User ID: $USER_ID, Group ID: $GROUP_ID"

# Create config directories
echo "📁 Creating configuration directories..."
mkdir -p config/{jellyfin,sonarr,radarr,lidarr,readarr,prowlarr,qbittorrent,overseerr,nzbget,tautulli,bazarr,caddy/{data,config}}

# Create media directories (adjust paths as needed)
echo "📁 Creating media directories..."
sudo mkdir -p /media/{movies,tv,music,books}
sudo mkdir -p /downloads/{complete,incomplete}

# Set permissions for config directories
echo "🔐 Setting permissions for config directories..."
chmod -R 755 config/
chown -R $USER_ID:$GROUP_ID config/

# Set permissions for media directories
echo "🔐 Setting permissions for media directories..."
sudo chown -R $USER_ID:$GROUP_ID /media /downloads
sudo chmod -R 755 /media /downloads

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file..."
    cp .env .env.example 2>/dev/null || true
    echo "⚠️  Please edit .env file with your configuration before starting services"
fi

# Set correct PUID/PGID in docker-compose.yml if needed
echo "🔧 Updating user IDs in docker-compose.yml..."
if command -v sed >/dev/null 2>&1; then
    # Update PUID and PGID in docker-compose.yml
    sed -i.bak "s/PUID=1000/PUID=$USER_ID/g" docker-compose.yml
    sed -i.bak "s/PGID=1000/PGID=$GROUP_ID/g" docker-compose.yml
    rm -f docker-compose.yml.bak
fi

# Create systemd service (optional)
if command -v systemctl >/dev/null 2>&1; then
    echo "🔧 Creating systemd service..."
    sudo tee /etc/systemd/system/media-stack.service > /dev/null <<EOF
[Unit]
Description=Media Stack
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$(pwd)
    ExecStart=/usr/bin/docker compose up -d
    ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    echo "✅ Systemd service created. Enable with: sudo systemctl enable media-stack"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Edit .env file with your domain and Cloudflare credentials"
echo "2. Configure DNS records in Cloudflare"
echo "3. Start services: docker compose up -d"
echo "4. Configure applications as described in MEDIA_STACK_SETUP.md"
echo ""
echo "🌐 After setup, your services will be available at:"
echo "   https://jellyfin.yourdomain.com"
echo "   https://overseerr.yourdomain.com"
echo "   https://prowlarr.yourdomain.com"
echo "   (and other configured subdomains)"