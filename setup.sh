#!/bin/bash

# Media Stack Setup Script
# This script creates necessary directories and sets proper permissions

set -e

# Colors and symbols for interactive output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'
CHECK='✅'
CROSS='❌'
ARROW='➜'

echo
echo -e "${CYAN}========================================${RESET}"
echo -e "${CYAN}${BOLD}      🌐 MEDIA STACK INSTALLER 🌐      ${RESET}"
echo -e "${CYAN}========================================${RESET}"
echo

PS3="${ARROW} Select your operating system: "
options=(Linux macOS Windows)
select OS in "${options[@]}"; do
    if [[ " ${options[*]} " == *" $OS "* ]]; then
        break
    else
        echo -e "${RED}Invalid selection.${RESET}"
    fi
done
echo -e "${GREEN}${CHECK} Operating system: $OS${RESET}"

# On Linux, ensure not running as root
if [[ "$OS" == "Linux" ]] && [[ $EUID -eq 0 ]]; then
   echo -e "${RED}Please run this script as a regular user, not root.${RESET}"
   exit 1
fi

# Get user and group IDs
USER_ID=$(id -u)
GROUP_ID=$(id -g)

# Prompt for directories
DEFAULT_MEDIA_DIR="/media"
if [[ "$OS" != "Linux" ]]; then
    DEFAULT_MEDIA_DIR="$HOME/media"
fi
read -rp "${ARROW} Media directory [${DEFAULT_MEDIA_DIR}]: " MEDIA_DIR
MEDIA_DIR="${MEDIA_DIR:-$DEFAULT_MEDIA_DIR}"

DEFAULT_DOWNLOADS_DIR="$HOME/downloads"
read -rp "${ARROW} Downloads directory [${DEFAULT_DOWNLOADS_DIR}]: " DOWNLOADS_DIR
DOWNLOADS_DIR="${DOWNLOADS_DIR:-$DEFAULT_DOWNLOADS_DIR}"

echo
echo -e "${YELLOW}Media directory: ${RESET}$MEDIA_DIR"
echo -e "${YELLOW}Downloads directory: ${RESET}$DOWNLOADS_DIR"
read -rp "${ARROW} Proceed with these settings? [Y/n]: " CONFIRM
CONFIRM="${CONFIRM:-Y}"
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Setup cancelled.${RESET}"
    exit 1
fi

echo -e "\n🚀 Setting up Media Stack directories and permissions..."

# Create config directories
echo "📁 Creating configuration directories..."
mkdir -p config/{jellyfin,sonarr,radarr,lidarr,readarr,prowlarr,qbittorrent,overseerr,nzbget,tautulli,bazarr,caddy/{data,config}}

# Create media directories
echo "📁 Creating media directories..."
if [[ "$OS" == "Linux" ]]; then
    sudo mkdir -p "$MEDIA_DIR"/{movies,tv,music,books}
    sudo mkdir -p "$DOWNLOADS_DIR"/{complete,incomplete}
else
    mkdir -p "$MEDIA_DIR"/{movies,tv,music,books}
    mkdir -p "$DOWNLOADS_DIR"/{complete,incomplete}
fi

# Set permissions for config directories
echo "🔐 Setting permissions for config directories..."
chmod -R 755 config/
chown -R $USER_ID:$GROUP_ID config/

# Set permissions for media directories
echo "🔐 Setting permissions for media directories..."
if [[ "$OS" == "Linux" ]]; then
    sudo chown -R $USER_ID:$GROUP_ID "$MEDIA_DIR" "$DOWNLOADS_DIR"
    sudo chmod -R 755 "$MEDIA_DIR" "$DOWNLOADS_DIR"
else
    chmod -R 755 "$MEDIA_DIR" "$DOWNLOADS_DIR"
fi

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