#!/bin/bash

# Quick start script for Media Stack

set -euo pipefail

LOG_FILE="start.log"
exec > >(tee -a "$LOG_FILE") 2>&1

error_exit() {
    echo "❌ Command failed at line $1"
}

trap 'error_exit $LINENO' ERR

echo "🚀 Starting Media Stack..."

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ .env file not found! Please copy .env.example to .env and configure it first."
    echo "   cp .env.example .env"
    echo "   nano .env"
    exit 1
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Pull latest images
echo "📥 Pulling latest Docker images..."
docker compose pull

# Start services
echo "🔄 Starting services..."
docker compose up -d

# Wait a moment for services to start
sleep 5

# Show status
echo "📊 Service status:"
docker compose ps

echo ""
echo "✅ Media Stack started successfully!"
echo ""
# Show appropriate URLs based on deployment mode
DOMAIN=$(grep -E '^DOMAIN=' .env | head -n1 | cut -d= -f2- || true)
ACCESS_MODE=$(grep -E '^ACCESS_MODE=' .env | head -n1 | cut -d= -f2- || true)

if [[ -z "$DOMAIN" ]]; then
    DOMAIN="localhost"
fi

LOCAL_MODE=false
if [[ "$ACCESS_MODE" == "local" || "$DOMAIN" == "localhost" ]]; then
    LOCAL_MODE=true
fi

echo "🌐 Access your services at:"
if [[ "$LOCAL_MODE" == "true" ]]; then
    echo "   Jellyfin:     http://localhost:8096"
    echo "   Dashboard:    http://localhost:7575"
    echo "   Overseerr:    http://localhost:5055"
    echo "   Prowlarr:     http://localhost:9696"
    echo "   Sonarr:       http://localhost:8989"
    echo "   Radarr:       http://localhost:7878"
    echo "   qBittorrent:  http://localhost:8080"
    echo "   Tdarr:        http://localhost:8266"
else
    echo "   Jellyfin:     https://jellyfin.$DOMAIN"
    echo "   Dashboard:    https://dashboard.$DOMAIN"
    echo "   Overseerr:    https://overseerr.$DOMAIN"
    echo "   Prowlarr:     https://prowlarr.$DOMAIN"
    echo "   Sonarr:       https://sonarr.$DOMAIN"
    echo "   Radarr:       https://radarr.$DOMAIN"
    echo "   qBittorrent:  https://qbittorrent.$DOMAIN"
    echo "   Tdarr:        https://tdarr.$DOMAIN"
fi
echo ""
echo "📚 See MEDIA_STACK_SETUP.md for detailed configuration instructions"
echo "📋 Check logs: docker compose logs -f [service-name]"
