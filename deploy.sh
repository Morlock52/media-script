#!/bin/bash

# Media Stack Deployment Script
# Intelligent deployment with environment validation and GPU detection

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${PURPLE}[SUCCESS]${NC} $1"
}

# Check if .env file exists and is configured
check_environment() {
    # Ensure Docker is installed
    if ! command -v docker >/dev/null 2>&1; then
        error "Docker is not installed or not in PATH"
        info "Install Docker and Docker Compose v2 before continuing"
        exit 1
    fi
    if ! docker compose version >/dev/null 2>&1; then
        error "Docker Compose plugin not found"
        info "Upgrade to Docker Compose v2 (use 'docker compose')"
        exit 1
    fi

    if [ ! -f "$PROJECT_ROOT/.env" ]; then
        error ".env file not found"
        info "Run: ./scripts/env-manager.sh init"
        exit 1
    fi
    
    # Source environment variables
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
    
    # Check for basic configuration
    local needs_cf_token=true
    if [[ "$ACCESS_MODE" == "local" ]]; then
        needs_cf_token=false
    fi

    if [[ "$DOMAIN" == *"yourdomain"* ]] || { [[ "$needs_cf_token" = true ]] && [[ "$CLOUDFLARE_API_TOKEN" == *"your-"* ]]; }; then
        error "Environment not properly configured"
        info "Run: ./scripts/env-manager.sh init"
        exit 1
    fi
    
    log "Environment configuration validated"
}

# Detect available GPU acceleration
detect_gpu() {
    local gpu_detected=""
    
    # Check for NVIDIA GPU
    if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
        gpu_detected="nvidia"
        info "NVIDIA GPU detected: $(nvidia-smi --query-gpu=name --format=csv,noheader,nounits | head -1)"
    fi
    
    # Check for Intel GPU
    if [ -d /dev/dri ] && ls /dev/dri/render* >/dev/null 2>&1; then
        if [ -n "$gpu_detected" ]; then
            gpu_detected="${gpu_detected}+intel"
        else
            gpu_detected="intel"
        fi
        info "Intel GPU detected: $(lspci | grep -i vga | grep -i intel | head -1 | cut -d: -f3 | xargs)"
    fi
    
    # Check for AMD GPU
    if lspci | grep -i amd | grep -i vga >/dev/null 2>&1; then
        if [ -n "$gpu_detected" ]; then
            gpu_detected="${gpu_detected}+amd"
        else
            gpu_detected="amd"
        fi
        info "AMD GPU detected: $(lspci | grep -i vga | grep -i amd | head -1 | cut -d: -f3 | xargs)"
    fi
    
    if [ -z "$gpu_detected" ]; then
        warn "No GPU acceleration detected - using CPU-only transcoding"
        gpu_detected="none"
    fi
    
    echo "$gpu_detected"
}

# Generate GPU-aware docker-compose file
generate_compose_file() {
    local gpu_type="$1"
    local output_file="$PROJECT_ROOT/docker-compose.yml"
    local source_file="$PROJECT_ROOT/docker-compose.optimized.yml"
    
    log "Generating docker-compose.yml for GPU type: $gpu_type"
    
    # Copy base file
    cp "$source_file" "$output_file.tmp"
    
    # Configure GPU settings based on detected hardware
    case "$gpu_type" in
        *nvidia*)
            info "Enabling NVIDIA GPU acceleration"
            # Update environment variables for NVIDIA
            sed -i.bak '/ENABLE_NVIDIA_GPU=/s/false/true/' "$PROJECT_ROOT/.env" 2>/dev/null || true
            
            # Enable NVIDIA devices in compose file
            sed -i.bak '/devices: \[\]/a\\n    - /dev/nvidia0:/dev/nvidia0\n    - /dev/nvidiactl:/dev/nvidiactl\n    - /dev/nvidia-modeset:/dev/nvidia-modeset\n    - /dev/nvidia-uvm:/dev/nvidia-uvm\n    - /dev/nvidia-uvm-tools:/dev/nvidia-uvm-tools' "$output_file.tmp"
            sed -i.bak '/group_add: \[\]/a\\n    - "109"' "$output_file.tmp"
            ;;
        *intel*)
            info "Enabling Intel GPU acceleration"
            sed -i.bak '/ENABLE_INTEL_GPU=/s/false/true/' "$PROJECT_ROOT/.env" 2>/dev/null || true
            
            # Enable Intel devices in compose file
            sed -i.bak '/devices: \[\]/a\\n    - /dev/dri:/dev/dri' "$output_file.tmp"
            sed -i.bak '/group_add: \[\]/a\\n    - "109"' "$output_file.tmp"
            ;;
        *amd*)
            info "Enabling AMD GPU acceleration"
            sed -i.bak '/ENABLE_AMD_GPU=/s/false/true/' "$PROJECT_ROOT/.env" 2>/dev/null || true
            
            # Enable DRI devices for AMD
            sed -i.bak '/devices: \[\]/a\\n    - /dev/dri:/dev/dri' "$output_file.tmp"
            sed -i.bak '/group_add: \[\]/a\\n    - "109"' "$output_file.tmp"
            ;;
        *)
            warn "No GPU acceleration will be used"
            ;;
    esac
    
    # Move temp file to final location
    mv "$output_file.tmp" "$output_file"
    rm -f "$output_file.tmp.bak" "$PROJECT_ROOT/.env.bak" 2>/dev/null || true
    
    success "Docker Compose file generated with GPU support: $gpu_type"
}

# Create necessary directories
create_directories() {
    log "Creating necessary directories..."
    
    # Source environment variables
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
    
    # Create base directories
    local directories=(
        "$CONFIG_PATH"
        "$DOWNLOADS_COMPLETE"
        "$DOWNLOADS_INCOMPLETE" 
        "$DOWNLOADS_CONVERT_INPUT"
        "$DOWNLOADS_CONVERT_OUTPUT"
        "$TDARR_TRANSCODE"
        "$JELLYFIN_TRANSCODE"
    )
    
    # Create media directories if they don't exist
    if [ "$MEDIA_PATH" != "/media" ]; then
        directories+=(
            "$MOVIES_PATH"
            "$TV_PATH"
            "$MUSIC_PATH"
            "$BOOKS_PATH"
            "$ANIME_PATH"
            "$DOCUMENTARIES_PATH"
            "$MEDIA_4K_PATH"
        )
    fi
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            info "Created directory: $dir"
        fi
    done
    
    # Set permissions
    if [ "$PUID" != "0" ] && [ "$PGID" != "0" ]; then
        log "Setting directory permissions..."
        sudo chown -R "$PUID:$PGID" "$CONFIG_PATH" 2>/dev/null || true
        
        # Only change media permissions if we own the parent directory
        if [ -w "$(dirname "$MEDIA_PATH")" ]; then
            sudo chown -R "$PUID:$PGID" "$MEDIA_PATH" "$DOWNLOADS_PATH" 2>/dev/null || true
        fi
    fi
    
    success "Directory structure created"
}

# Pull and start services
deploy_services() {
    local profiles="$1"
    
    log "Deploying media stack services..."
    
    # Pull latest images
    log "Pulling latest Docker images..."
    if [ -n "$profiles" ]; then
        docker compose --profile "$profiles" pull
    else
        docker compose pull
    fi
    
    # Start services
    log "Starting services..."
    if [ -n "$profiles" ]; then
        docker compose --profile "$profiles" up -d
    else
        docker compose up -d
    fi
    
    # Wait for services to start
    log "Waiting for services to initialize..."
    sleep 10
    
    # Check service health
    check_service_health
    
    success "Media stack deployed successfully!"
}

# Check service health
check_service_health() {
    log "Checking service health..."
    
    local failed_services=()
    local core_services=("caddy" "jellyfin" "sonarr" "radarr" "qbittorrent" "homarr")
    
    for service in "${core_services[@]}"; do
        if ! docker compose ps "$service" | grep -q "Up"; then
            failed_services+=("$service")
        fi
    done
    
    if [ ${#failed_services[@]} -eq 0 ]; then
        success "All core services are healthy"
    else
        warn "Some services failed to start: ${failed_services[*]}"
        info "Check logs with: docker compose logs <service-name>"
    fi
}

# Show deployment summary
show_summary() {
    # Source environment variables
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
    
    echo
    echo "================================"
    echo "🎬 MEDIA STACK DEPLOYMENT COMPLETE"
    echo "================================"
    echo
    echo -e "${BLUE}Primary Services:${NC}"
    echo "  📱 Dashboard:    https://dashboard.$DOMAIN"
    echo "  🎭 Jellyfin:     https://jellyfin.$DOMAIN"
    echo "  📊 Status:       https://status.$DOMAIN"
    echo "  🎬 Requests:     https://overseerr.$DOMAIN"
    echo
    echo -e "${BLUE}Management:${NC}"
    echo "  📺 Sonarr:       https://sonarr.$DOMAIN"
    echo "  🎬 Radarr:       https://radarr.$DOMAIN"
    echo "  🎵 Lidarr:       https://lidarr.$DOMAIN"
    echo "  📚 Readarr:      https://readarr.$DOMAIN"
    echo "  🔍 Prowlarr:     https://prowlarr.$DOMAIN"
    echo
    echo -e "${BLUE}Processing:${NC}"
    echo "  ⬇️  qBittorrent:  https://qbittorrent.$DOMAIN"
    echo "  🔄 Tdarr:        https://tdarr.$DOMAIN"
    echo "  🎞️  HandBrake:    https://handbrake.$DOMAIN"
    echo
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. Configure API keys: ./scripts/env-manager.sh setup-api-keys"
    echo "  2. Setup Prowlarr indexers first"
    echo "  3. Configure download client in *arr apps"
    echo "  4. Add media libraries to Jellyfin"
    echo
    echo -e "${GREEN}Commands:${NC}"
    echo "  Check status:  docker compose ps"
    echo "  View logs:     docker compose logs -f <service>"
    echo "  Restart:       docker compose restart <service>"
    echo "  Stop all:      docker compose down"
    echo
}

# Main deployment logic
main() {
    local command="${1:-deploy}"
    local profiles=""
    
    case "$command" in
        "init")
            log "Initializing media stack deployment..."
            ./scripts/env-manager.sh init
            ;;
        "deploy")
            check_environment
            
            # Parse additional arguments
            shift || true
            while [[ $# -gt 0 ]]; do
                case $1 in
                    --with-auto-update)
                        profiles="${profiles:+$profiles,}auto-update"
                        ;;
                    --with-multi-node)
                        profiles="${profiles:+$profiles,}multi-node"
                        ;;
                    --gpu)
                        # Force GPU detection override
                        shift
                        gpu_override="$1"
                        ;;
                    *)
                        warn "Unknown option: $1"
                        ;;
                esac
                shift
            done
            
            # Detect GPU capabilities
            local detected_gpu="${gpu_override:-$(detect_gpu)}"
            
            # Generate optimized compose file
            generate_compose_file "$detected_gpu"
            
            # Create directories
            create_directories
            
            # Deploy services
            deploy_services "$profiles"
            
            # Show summary
            show_summary
            ;;
        "update")
            log "Updating media stack..."
            docker compose pull
            docker compose up -d
            success "Media stack updated!"
            ;;
        "stop")
            log "Stopping media stack..."
            docker compose down
            success "Media stack stopped"
            ;;
        "restart")
            log "Restarting media stack..."
            docker compose restart
            success "Media stack restarted"
            ;;
        "logs")
            service="${2:-}"
            if [ -n "$service" ]; then
                docker compose logs -f "$service"
            else
                docker compose logs -f
            fi
            ;;
        "status")
            check_environment
            docker compose ps
            ;;
        "help")
            echo "Media Stack Deployment Script"
            echo ""
            echo "Usage: $0 <command> [options]"
            echo ""
            echo "Commands:"
            echo "  init                    Initialize environment configuration"
            echo "  deploy [options]        Deploy the media stack"
            echo "  update                  Update all services to latest versions"
            echo "  stop                    Stop all services"
            echo "  restart                 Restart all services"
            echo "  logs [service]          View logs for all services or specific service"
            echo "  status                  Show service status"
            echo "  help                    Show this help message"
            echo ""
            echo "Deploy Options:"
            echo "  --with-auto-update      Enable automatic container updates"
            echo "  --with-multi-node       Enable additional Tdarr processing nodes"
            echo "  --gpu <type>           Force GPU type (nvidia, intel, amd, none)"
            echo ""
            echo "Examples:"
            echo "  $0 init                 # First time setup"
            echo "  $0 deploy               # Basic deployment"
            echo "  $0 logs jellyfin        # View Jellyfin logs"
            echo "  $0 update               # Update all services"
            ;;
        *)
            error "Unknown command: $command"
            echo "Run: $0 help for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"