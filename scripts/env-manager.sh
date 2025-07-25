#!/bin/bash

# Environment Variable Management Script
# Helps manage .env file and reduces configuration duplication

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_ROOT/.env"
ENV_EXAMPLE="$PROJECT_ROOT/.env.example"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Helper: set variable in .env
set_env_var() {
    local var="$1"
    local value="$2"
    if grep -q "^${var}=" "$ENV_FILE"; then
        sed -i.bak "s|^${var}=.*|${var}=${value}|" "$ENV_FILE"
    else
        echo "${var}=${value}" >> "$ENV_FILE"
    fi
}

# Helper: get default value from .env.example
get_default() {
    grep "^$1=" "$ENV_EXAMPLE" | cut -d= -f2-
}

# Function to create .env from .env.example
init_env() {
    log "Initializing environment configuration..."
    
    if [ -f "$ENV_FILE" ]; then
        warn ".env file already exists"
        read -r -p "Do you want to overwrite it? (y/N): " response
        if [[ ! $response =~ ^[Yy]$ ]]; then
            log "Keeping existing .env file"
            return 0
        fi
    fi
    
    if [ ! -f "$ENV_EXAMPLE" ]; then
        error ".env.example file not found"
        exit 1
    fi
    
    cp "$ENV_EXAMPLE" "$ENV_FILE"
    log "Created .env file from .env.example"
    
    # Prompt for essential configuration
    info "Let's configure the essential settings..."
    
    # Domain configuration
    read -r -p "Enter your domain (e.g., media.example.com): " domain
    if [ -n "$domain" ]; then
        sed -i.bak "s/DOMAIN=yourdomain.com/DOMAIN=$domain/g" "$ENV_FILE"
        log "Set domain to: $domain"
    fi
    
    # Timezone configuration
    echo "Current timezone: $(cat /etc/timezone 2>/dev/null || date +%Z)"
    read -r -p "Enter your timezone (press Enter to use current): " timezone
    if [ -n "$timezone" ]; then
        sed -i.bak "s|TZ=America/New_York|TZ=$timezone|g" "$ENV_FILE"
        log "Set timezone to: $timezone"
    fi
    
    # User/Group ID detection
    current_uid=$(id -u)
    current_gid=$(id -g)
    
    if [ "$current_uid" != "1000" ] || [ "$current_gid" != "1000" ]; then
        warn "Your UID/GID is not 1000:1000 (current: $current_uid:$current_gid)"
        read -r -p "Update PUID/PGID to match your user? (Y/n): " response
        if [[ ! $response =~ ^[Nn]$ ]]; then
            sed -i.bak "s/PUID=1000/PUID=$current_uid/g" "$ENV_FILE"
            sed -i.bak "s/PGID=1000/PGID=$current_gid/g" "$ENV_FILE"
            log "Updated PUID/PGID to: $current_uid:$current_gid"
        fi
    fi
    
    # Cloudflare configuration
    read -r -p "Enter your Cloudflare email: " cf_email
    if [ -n "$cf_email" ]; then
        sed -i.bak "s/CLOUDFLARE_EMAIL=your-email@example.com/CLOUDFLARE_EMAIL=$cf_email/g" "$ENV_FILE"
        log "Set Cloudflare email to: $cf_email"
    fi
    
    read -r -p "Enter your Cloudflare API token: " cf_token
    if [ -n "$cf_token" ]; then
        sed -i.bak "s/CLOUDFLARE_API_TOKEN=your-cloudflare-api-token/CLOUDFLARE_API_TOKEN=$cf_token/g" "$ENV_FILE"
        log "Set Cloudflare API token"
    fi
    
    # Cleanup backup files
    rm -f "$ENV_FILE.bak"
    
    log "Environment initialization complete!"
    info "You can now run: ./start.sh to start the media stack"
    info "Remember to configure API keys after services are running"
}

# Function to validate .env file
validate_env() {
    log "Validating environment configuration..."
    
    if [ ! -f "$ENV_FILE" ]; then
        error ".env file not found. Run: $0 init"
        exit 1
    fi
    
    # Source the .env file
    set -a
    source "$ENV_FILE"
    set +a
    
    local errors=0
    
    # Check required variables
    required_vars=(
        "DOMAIN"
        "TZ"
        "PUID"
        "PGID"
        "CLOUDFLARE_EMAIL"
        "CLOUDFLARE_API_TOKEN"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ] || [[ "${!var}" == *"your-"* ]] || [[ "${!var}" == *"yourdomain"* ]]; then
            error "Required variable $var is not properly configured"
            ((errors++))
        fi
    done
    
    # Check paths
    if [ ! -d "$(dirname "$CONFIG_PATH")" ]; then
        warn "Config directory parent doesn't exist: $(dirname "$CONFIG_PATH")"
    fi
    
    # Check for common misconfigurations
    if [ "$PUID" = "0" ] || [ "$PGID" = "0" ]; then
        warn "Running as root (PUID/PGID = 0) is not recommended"
    fi
    
    if [ "$ENABLE_NVIDIA_GPU" = "true" ] && ! command -v nvidia-smi >/dev/null 2>&1; then
        warn "NVIDIA GPU enabled but nvidia-smi not found"
    fi
    
    if [ $errors -eq 0 ]; then
        log "Environment validation passed!"
    else
        error "Environment validation failed with $errors errors"
        exit 1
    fi
}

# Prompt for missing mandatory variables and update .env
check_env() {
    log "Checking for missing mandatory settings..."

    if [ ! -f "$ENV_FILE" ]; then
        error ".env file not found. Run: $0 init"
        exit 1
    fi

    # Source existing values
    set -a
    source "$ENV_FILE"
    set +a

    local updated=0
    required_vars=(DOMAIN TZ PUID PGID ACCESS_MODE)
    if [[ "${ACCESS_MODE:-remote}" != "local" ]]; then
        required_vars+=(CLOUDFLARE_EMAIL CLOUDFLARE_API_TOKEN)
    fi

    for var in "${required_vars[@]}"; do
        current="${!var:-}"
        default="$(get_default "$var")"
        if [ -z "$current" ] || [[ "$current" == "$default" ]] || [[ "$current" == *"your-"* ]] || [[ "$current" == *"yourdomain"* ]]; then
            read -r -p "Enter value for $var [${default}]: " input
            value="${input:-$default}"
            set_env_var "$var" "$value"
            export "$var=$value"
            updated=1
        fi
    done

    rm -f "$ENV_FILE.bak"

    if [ $updated -eq 0 ]; then
        log "All mandatory settings are configured"
    else
        log "Updated configuration saved to .env"
    fi
}

# Function to show current configuration
show_config() {
    if [ ! -f "$ENV_FILE" ]; then
        error ".env file not found"
        exit 1
    fi
    
    log "Current environment configuration:"
    echo
    
    # Source the .env file
    set -a
    source "$ENV_FILE"
    set +a
    
    echo -e "${BLUE}Core Configuration:${NC}"
    echo "  Domain: $DOMAIN"
    echo "  Project Name: $COMPOSE_PROJECT_NAME"
    echo "  Timezone: $TZ"
    echo "  User/Group: $PUID:$PGID"
    echo
    
    echo -e "${BLUE}Paths:${NC}"
    echo "  Config: $CONFIG_PATH"
    echo "  Media: $MEDIA_PATH"
    echo "  Downloads: $DOWNLOADS_PATH"
    echo "  Temp: $TEMP_PATH"
    echo
    
    echo -e "${BLUE}GPU Acceleration:${NC}"
    echo "  NVIDIA: $ENABLE_NVIDIA_GPU"
    echo "  Intel: $ENABLE_INTEL_GPU" 
    echo "  AMD: $ENABLE_AMD_GPU"
    echo
    
    echo -e "${BLUE}Service URLs:${NC}"
    echo "  Dashboard: https://dashboard.$DOMAIN"
    echo "  Jellyfin: https://jellyfin.$DOMAIN"
    echo "  Status: https://status.$DOMAIN"
    echo
    
    # Check API keys
    local api_keys_configured=0
    local total_api_keys=9
    
    [ -n "$JELLYFIN_API_KEY" ] && [ "$JELLYFIN_API_KEY" != "your_jellyfin_api_key" ] && ((api_keys_configured++))
    [ -n "$SONARR_API_KEY" ] && [ "$SONARR_API_KEY" != "your_sonarr_api_key" ] && ((api_keys_configured++))
    [ -n "$RADARR_API_KEY" ] && [ "$RADARR_API_KEY" != "your_radarr_api_key" ] && ((api_keys_configured++))
    [ -n "$LIDARR_API_KEY" ] && [ "$LIDARR_API_KEY" != "your_lidarr_api_key" ] && ((api_keys_configured++))
    [ -n "$READARR_API_KEY" ] && [ "$READARR_API_KEY" != "your_readarr_api_key" ] && ((api_keys_configured++))
    [ -n "$PROWLARR_API_KEY" ] && [ "$PROWLARR_API_KEY" != "your_prowlarr_api_key" ] && ((api_keys_configured++))
    [ -n "$OVERSEERR_API_KEY" ] && [ "$OVERSEERR_API_KEY" != "your_overseerr_api_key" ] && ((api_keys_configured++))
    [ -n "$TAUTULLI_API_KEY" ] && [ "$TAUTULLI_API_KEY" != "your_tautulli_api_key" ] && ((api_keys_configured++))
    [ -n "$BAZARR_API_KEY" ] && [ "$BAZARR_API_KEY" != "your_bazarr_api_key" ] && ((api_keys_configured++))
    
    echo -e "${BLUE}API Keys:${NC}"
    echo "  Configured: $api_keys_configured/$total_api_keys"
    
    if [ $api_keys_configured -lt $total_api_keys ]; then
        warn "Some API keys are not configured. Dashboard integrations may not work fully."
        info "Run: $0 setup-api-keys for assistance"
    fi
}

# Function to help setup API keys
setup_api_keys() {
    log "API Keys Setup Assistant"
    echo
    
    if [ ! -f "$ENV_FILE" ]; then
        error ".env file not found. Run: $0 init first"
        exit 1
    fi
    
    info "To get API keys, access each service web interface and go to Settings → General → API Key"
    echo
    
    services=(
        "JELLYFIN:Dashboard → Advanced → API Keys"
        "SONARR:Settings → General → API Key"
        "RADARR:Settings → General → API Key"
        "LIDARR:Settings → General → API Key"
        "READARR:Settings → General → API Key"
        "PROWLARR:Settings → General → API Key"
        "OVERSEERR:Settings → General → API Key"
        "TAUTULLI:Settings → Web Interface → API Key"
        "BAZARR:Settings → General → API Key"
    )
    
    for service_info in "${services[@]}"; do
        service=$(echo "$service_info" | cut -d: -f1)
        path=$(echo "$service_info" | cut -d: -f2)
        
        current_key=$(grep "^${service}_API_KEY=" "$ENV_FILE" | cut -d= -f2)
        
        echo -e "${BLUE}$service${NC}"
        echo "  Current: ${current_key:-not set}"
        echo "  Path: $path"
        
        read -r -p "  Enter new API key (or press Enter to skip): " new_key
        
        if [ -n "$new_key" ]; then
            sed -i.bak "s/${service}_API_KEY=.*/${service}_API_KEY=$new_key/g" "$ENV_FILE"
            log "Updated $service API key"
        fi
        echo
    done
    
    # Cleanup backup file
    rm -f "$ENV_FILE.bak"
    
    log "API keys setup complete!"
}

# Function to update paths
update_paths() {
    log "Updating storage paths..."
    
    if [ ! -f "$ENV_FILE" ]; then
        error ".env file not found"
        exit 1
    fi
    
    # Source current config
    set -a
    source "$ENV_FILE"
    set +a
    
    echo "Current paths:"
    echo "  Media: $MEDIA_PATH"
    echo "  Downloads: $DOWNLOADS_PATH"
    echo "  Config: $CONFIG_PATH"
    echo "  Temp: $TEMP_PATH"
    echo
    
    read -r -p "Enter new media path (current: $MEDIA_PATH): " new_media
    if [ -n "$new_media" ]; then
        sed -i.bak "s|MEDIA_PATH=.*|MEDIA_PATH=$new_media|g" "$ENV_FILE"
        log "Updated media path to: $new_media"
    fi
    
    read -r -p "Enter new downloads path (current: $DOWNLOADS_PATH): " new_downloads
    if [ -n "$new_downloads" ]; then
        sed -i.bak "s|DOWNLOADS_PATH=.*|DOWNLOADS_PATH=$new_downloads|g" "$ENV_FILE"
        log "Updated downloads path to: $new_downloads"
    fi
    
    # Cleanup backup file
    rm -f "$ENV_FILE.bak"
    
    log "Path update complete!"
}

# Function to enable GPU acceleration
enable_gpu() {
    log "GPU Acceleration Setup"
    
    if [ ! -f "$ENV_FILE" ]; then
        error ".env file not found"
        exit 1
    fi
    
    echo "Available GPU options:"
    echo "1. NVIDIA (NVENC/NVDEC)"
    echo "2. Intel (QSV/VA-API)"
    echo "3. AMD (AMF/VA-API)"
    echo "4. Disable GPU acceleration"
    echo
    
    read -r -p "Select GPU type (1-4): " gpu_choice
    
    case $gpu_choice in
        1)
            if command -v nvidia-smi >/dev/null 2>&1; then
                sed -i.bak "s/ENABLE_NVIDIA_GPU=.*/ENABLE_NVIDIA_GPU=true/g" "$ENV_FILE"
                sed -i.bak "s/ENABLE_INTEL_GPU=.*/ENABLE_INTEL_GPU=false/g" "$ENV_FILE"
                sed -i.bak "s/ENABLE_AMD_GPU=.*/ENABLE_AMD_GPU=false/g" "$ENV_FILE"
                log "Enabled NVIDIA GPU acceleration"
            else
                error "nvidia-smi not found. Install NVIDIA drivers first."
                exit 1
            fi
            ;;
        2)
            if [ -d /dev/dri ]; then
                sed -i.bak "s/ENABLE_NVIDIA_GPU=.*/ENABLE_NVIDIA_GPU=false/g" "$ENV_FILE"
                sed -i.bak "s/ENABLE_INTEL_GPU=.*/ENABLE_INTEL_GPU=true/g" "$ENV_FILE"
                sed -i.bak "s/ENABLE_AMD_GPU=.*/ENABLE_AMD_GPU=false/g" "$ENV_FILE"
                log "Enabled Intel GPU acceleration"
            else
                error "/dev/dri not found. Intel GPU drivers may not be installed."
                exit 1
            fi
            ;;
        3)
            sed -i.bak "s/ENABLE_NVIDIA_GPU=.*/ENABLE_NVIDIA_GPU=false/g" "$ENV_FILE"
            sed -i.bak "s/ENABLE_INTEL_GPU=.*/ENABLE_INTEL_GPU=false/g" "$ENV_FILE"
            sed -i.bak "s/ENABLE_AMD_GPU=.*/ENABLE_AMD_GPU=true/g" "$ENV_FILE"
            log "Enabled AMD GPU acceleration"
            ;;
        4)
            sed -i.bak "s/ENABLE_NVIDIA_GPU=.*/ENABLE_NVIDIA_GPU=false/g" "$ENV_FILE"
            sed -i.bak "s/ENABLE_INTEL_GPU=.*/ENABLE_INTEL_GPU=false/g" "$ENV_FILE"
            sed -i.bak "s/ENABLE_AMD_GPU=.*/ENABLE_AMD_GPU=false/g" "$ENV_FILE"
            log "Disabled GPU acceleration"
            ;;
        *)
            error "Invalid choice"
            exit 1
            ;;
    esac
    
    # Cleanup backup file
    rm -f "$ENV_FILE.bak"
    
    warn "You may need to restart containers for GPU changes to take effect"
    info "Run: docker compose down && docker compose up -d"
}

# Function to backup configuration
backup_config() {
    local backup_dir="$PROJECT_ROOT/backups"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$backup_dir/env_backup_$timestamp.tar.gz"
    
    log "Creating configuration backup..."
    
    mkdir -p "$backup_dir"
    
    # Create backup
    tar -czf "$backup_file" -C "$PROJECT_ROOT" .env config/ 2>/dev/null || {
        error "Backup failed"
        exit 1
    }
    
    log "Backup created: $backup_file"
    
    # Keep only last 10 backups
    cd "$backup_dir"
    ls -t env_backup_*.tar.gz 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true
    
    info "Configuration backed up successfully"
}

# Main script logic
case "${1:-}" in
    "init")
        init_env
        ;;
    "validate")
        validate_env
        ;;
    "check")
        check_env
        ;;
    "show"|"config")
        show_config
        ;;
    "setup-api-keys"|"api-keys")
        setup_api_keys
        ;;
    "update-paths"|"paths")
        update_paths
        ;;
    "enable-gpu"|"gpu")
        enable_gpu
        ;;
    "backup")
        backup_config
        ;;
    "help"|"")
        echo "Environment Variable Management Script"
        echo ""
        echo "Usage: $0 <command>"
        echo ""
        echo "Commands:"
        echo "  init           Initialize .env file from .env.example"
        echo "  validate       Validate current .env configuration"
        echo "  check          Prompt for any missing required settings"
        echo "  show           Show current configuration"
        echo "  setup-api-keys Configure API keys for services"
        echo "  update-paths   Update storage paths"
        echo "  enable-gpu     Configure GPU acceleration"
        echo "  backup         Backup current configuration"
        echo "  help           Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 init                    # First time setup"
        echo "  $0 validate               # Check configuration"
        echo "  $0 check                  # Fix missing settings"
        echo "  $0 setup-api-keys         # Configure API keys"
        echo "  $0 enable-gpu             # Setup GPU acceleration"
        ;;
    *)
        error "Unknown command: $1"
        echo "Run: $0 help for usage information"
        exit 1
        ;;
esac