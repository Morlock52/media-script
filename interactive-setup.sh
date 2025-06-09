#!/usr/bin/env bash

# Require Bash 4+ for associative array support
if [[ "${BASH_VERSINFO[0]:-0}" -lt 4 ]]; then
  echo "Error: Bash version >= 4 is required."
  echo "On macOS, install a newer bash (e.g. 'brew install bash') and run this script with it."
  exit 1
fi

# Interactive Media Stack Setup Wizard
# Beautiful, detailed, step-by-step setup with explanations
# Designed for complete beginners with zero technical experience

# GUI/TUI/Native dialog frontend selection
USE_APPLESCRIPT=false
USE_DIALOG=false
if [ "$(uname)" = "Darwin" ] && command -v osascript >/dev/null 2>&1; then
    echo "Detected macOS."
    echo "Choose dialog mode:"
    echo "  1) Native macOS dialogs"
    echo "  2) Whiptail TUI (if installed)"
    echo "  3) Plain text prompts"
    read -rp "Enter choice [1]: " _mode
    case "${_mode:-1}" in
        2) USE_DIALOG=true ;;
        3) ;;
        *) USE_APPLESCRIPT=true ;;
    esac
elif command -v whiptail >/dev/null 2>&1; then
    USE_DIALOG=true
fi
BACKTITLE="Media Stack Setup Wizard"

set -e

# ============================================================================
# CONFIGURATION AND GLOBALS
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
SETUP_LOG="$PROJECT_ROOT/setup.log"
PROGRESS_FILE="$PROJECT_ROOT/.setup_progress"

# Colors and formatting
declare -A COLORS=(
    [RED]='\033[0;31m'
    [GREEN]='\033[0;32m'
    [YELLOW]='\033[1;33m'
    [BLUE]='\033[0;34m'
    [PURPLE]='\033[0;35m'
    [CYAN]='\033[0;36m'
    [WHITE]='\033[1;37m'
    [BOLD]='\033[1m'
    [DIM]='\033[2m'
    [RESET]='\033[0m'
)

# Unicode symbols
declare -A SYMBOLS=(
    [CHECK]='✅'
    [CROSS]='❌'
    [ARROW]='➜'
    [BULLET]='•'
    [STAR]='⭐'
    [ROCKET]='🚀'
    [GEAR]='⚙️'
    [FOLDER]='📁'
    [GLOBE]='🌐'
    [KEY]='🔑'
    [SHIELD]='🛡️'
    [MOVIE]='🎬'
    [MUSIC]='🎵'
    [BOOK]='📚'
    [TV]='📺'
    [DOWNLOAD]='⬇️'
    [UPLOAD]='⬆️'
    [WARNING]='⚠️'
    [INFO]='ℹ️'
    [SPARKLES]='✨'
    [TROPHY]='🏆'
    [PARTY]='🎉'
)

# Progress tracking
TOTAL_STEPS=12
CURRENT_STEP=0

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$SETUP_LOG"
}

# Save progress
save_progress() {
    echo "$CURRENT_STEP" > "$PROGRESS_FILE"
    log "Progress saved: Step $CURRENT_STEP/$TOTAL_STEPS"
}

# Load progress
load_progress() {
    if [ -f "$PROGRESS_FILE" ]; then
        CURRENT_STEP=$(cat "$PROGRESS_FILE")
        log "Progress loaded: Step $CURRENT_STEP/$TOTAL_STEPS"
    fi
}

# Clear screen with style
clear_screen() {
    clear
    echo -e "${COLORS[CYAN]}╔══════════════════════════════════════════════════════════════════════════╗${COLORS[RESET]}"
    echo -e "${COLORS[CYAN]}║${COLORS[WHITE]}${COLORS[BOLD]}                      🎬 MEDIA STACK SETUP WIZARD 🎬                      ${COLORS[RESET]}${COLORS[CYAN]}║${COLORS[RESET]}"
    echo -e "${COLORS[CYAN]}║${COLORS[WHITE]}           Professional Media Server Setup - Made Simple & Beautiful      ${COLORS[RESET]}${COLORS[CYAN]}║${COLORS[RESET]}"
    echo -e "${COLORS[CYAN]}╚══════════════════════════════════════════════════════════════════════════╝${COLORS[RESET]}"
    echo
}

# Progress bar
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    echo -ne "${COLORS[CYAN]}Progress: [${COLORS[GREEN]}"
    for ((i=0; i<filled; i++)); do echo -n "█"; done
    echo -ne "${COLORS[DIM]}"
    for ((i=0; i<empty; i++)); do echo -n "░"; done
    echo -e "${COLORS[CYAN]}] ${percentage}% (${current}/${total})${COLORS[RESET]}"
}

# Beautiful section header
section_header() {
    local title="$1"
    local description="$2"
    local icon="$3"
    
    echo
    echo -e "${COLORS[PURPLE]}┌─────────────────────────────────────────────────────────────────────────┐${COLORS[RESET]}"
    echo -e "${COLORS[PURPLE]}│ ${icon} ${COLORS[BOLD]}${COLORS[WHITE]}${title}${COLORS[RESET]}${COLORS[PURPLE]}${COLORS[RESET]}"
    echo -e "${COLORS[PURPLE]}│ ${COLORS[DIM]}${description}${COLORS[RESET]}${COLORS[PURPLE]}${COLORS[RESET]}"
    echo -e "${COLORS[PURPLE]}└─────────────────────────────────────────────────────────────────────────┘${COLORS[RESET]}"
    echo
}

# Success message
success_message() {
    local message="$1"
    echo -e "${COLORS[GREEN]}${SYMBOLS[CHECK]} ${COLORS[BOLD]}${message}${COLORS[RESET]}"
}

# Error message
error_message() {
    local message="$1"
    echo -e "${COLORS[RED]}${SYMBOLS[CROSS]} ${COLORS[BOLD]}${message}${COLORS[RESET]}"
}

# Warning message
warning_message() {
    local message="$1"
    echo -e "${COLORS[YELLOW]}${SYMBOLS[WARNING]} ${COLORS[BOLD]}${message}${COLORS[RESET]}"
}

# Info message
info_message() {
    local message="$1"
    echo -e "${COLORS[BLUE]}${SYMBOLS[INFO]} ${message}${COLORS[RESET]}"
}

# Interactive prompt with validation
prompt_input() {
    local prompt="$1"
    local default="$2"
    local validator="$3"
    local help_text="$4"
    local result=""

    # macOS native dialogs via AppleScript
    if [ "$USE_APPLESCRIPT" = true ]; then
        while true; do
            result=$(osascript <<EOF
try
    set theDialog to display dialog "${prompt}\n\n${help_text}" default answer "${default}" with title "Media Stack Setup Wizard" buttons {"Cancel", "OK"} default button "OK"
    text returned of theDialog
on error number -128
    error "User cancelled"
end try
EOF
)
            if [ $? -ne 0 ]; then
                echo
                error_message "Cancelled."
                exit 1
            fi
            if [ -z "$result" ] && [ -n "$default" ]; then
                result="$default"
            fi
            if [ -n "$validator" ]; then
                if $validator "$result"; then
                    break
                else
                    osascript <<EOF
display dialog "Invalid input. Please try again." buttons {"OK"} with title "Invalid input"
EOF
                    continue
                fi
            else
                break
            fi
        done
        echo "$result"
        return
    fi

    # whiptail TUI prompts
    if [ "$USE_DIALOG" = true ]; then
        while true; do
            result=$(whiptail --backtitle "$BACKTITLE" --title "$prompt" \
                             --inputbox "$help_text" 10 60 "$default" \
                             3>&1 1>&2 2>&3)
            [ $? -eq 0 ] || { echo; error_message "Cancelled."; exit 1; }
            if [ -n "$validator" ] && ! $validator "$result"; then
                whiptail --backtitle "$BACKTITLE" --title "Invalid input" \
                         --msgbox "Invalid input. Please try again." 8 60
            else
                break
            fi
        done
        echo "$result"
        return
    fi
    
    while true; do
        echo
        echo -e "${COLORS[CYAN]}${SYMBOLS[ARROW]} ${COLORS[BOLD]}${prompt}${COLORS[RESET]}"
        if [ -n "$default" ]; then
            echo -e "${COLORS[DIM]}   Default: ${default}${COLORS[RESET]}"
        fi
        if [ -n "$help_text" ]; then
            echo -e "${COLORS[DIM]}   Help: ${help_text}${COLORS[RESET]}"
        fi
        echo -ne "${COLORS[GREEN]}${SYMBOLS[ARROW]} ${COLORS[RESET]}"
        read -r result
        
        # Use default if empty
        if [ -z "$result" ] && [ -n "$default" ]; then
            result="$default"
        fi
        
        # Validate if validator provided
        if [ -n "$validator" ]; then
            if $validator "$result"; then
                break
            else
                error_message "Invalid input. Please try again."
                continue
            fi
        else
            break
        fi
    done
    
    echo "$result"
}

# Yes/No prompt
prompt_yn() {
    local prompt="$1"
    local default="$2"

    # macOS native yes/no via AppleScript
    if [ "$USE_APPLESCRIPT" = true ]; then
        local ok_btn="Yes" cancel_btn="No"
        if [ "$default" = "y" ]; then ok_btn="Yes"; cancel_btn="No"; else ok_btn="No"; cancel_btn="Yes"; fi
        local resp
        resp=$(osascript <<EOF
try
    set theResp to display dialog "${prompt}" buttons {"${cancel_btn}", "${ok_btn}"} default button "${ok_btn}" with title "Media Stack Setup Wizard"
    if button returned of theResp is "${ok_btn}" then
        return "y"
    else
        return "n"
    end if
on error number -128
    return "cancel"
end try
EOF
)
        case "$resp" in
            y) return 0 ;; n) return 1 ;; *) echo; error_message "Cancelled."; exit 1 ;;
        esac
    fi

    # whiptail TUI yes/no prompt
    if [ "$USE_DIALOG" = true ]; then
        if whiptail --backtitle "$BACKTITLE" --title "$prompt" --yesno "$prompt" 8 60; then
            return 0
        else
            return 1
        fi
    fi

    # fallback to plain-text prompts
    local result=""
    while true; do
        echo
        echo -e "${COLORS[CYAN]}${SYMBOLS[ARROW]} ${COLORS[BOLD]}${prompt}${COLORS[RESET]}"
        if [ "$default" = "y" ]; then
            echo -ne "${COLORS[GREEN]}${SYMBOLS[ARROW]} [Y/n]: ${COLORS[RESET]}"
        else
            echo -ne "${COLORS[GREEN]}${SYMBOLS[ARROW]} [y/N]: ${COLORS[RESET]}"
        fi
        read -r result

        case "$result" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;; n|[Nn]|[Nn][Oo]) return 1 ;;
            "")
                if [ "$default" = "y" ]; then return 0; else return 1; fi
                ;;
            *) error_message "Please answer yes or no." ;;
        esac
    done
}

# Spinner for long operations
spinner() {
    local pid=$1
    local message="$2"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    echo -ne "${COLORS[CYAN]}${message}${COLORS[RESET]}"
    while kill -0 $pid 2>/dev/null; do
        local char="${spin:$i%${#spin}:1}"
        echo -ne "\r${COLORS[CYAN]}${message} ${COLORS[YELLOW]}${char}${COLORS[RESET]}"
        sleep 0.1
        ((i++))
    done
    echo -ne "\r${COLORS[CYAN]}${message} ${COLORS[GREEN]}${SYMBOLS[CHECK]}${COLORS[RESET]}\n"
}

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

validate_domain() {
    local domain="$1"
    if [[ "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 0
    else
        error_message "Invalid domain format. Example: media.yourname.com"
        return 1
    fi
}

validate_email() {
    local email="$1"
    if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        error_message "Invalid email format. Example: you@gmail.com"
        return 1
    fi
}

validate_path() {
    local path="$1"
    if [[ "$path" =~ ^/[a-zA-Z0-9/_-]*$ ]]; then
        return 0
    else
        error_message "Invalid path format. Must start with / and contain only letters, numbers, -, _, /"
        return 1
    fi
}

validate_api_key() {
    local key="$1"
    if [ ${#key} -ge 10 ]; then
        return 0
    else
        error_message "API key too short. Should be at least 10 characters."
        return 1
    fi
}

# ============================================================================
# SETUP STEPS
# ============================================================================

step_welcome() {
    clear_screen
    CURRENT_STEP=1
    show_progress $CURRENT_STEP $TOTAL_STEPS
    
    echo -e "${COLORS[PURPLE]}${SYMBOLS[ROCKET]} ${COLORS[BOLD]}${COLORS[WHITE]}Welcome to the Media Stack Setup Wizard!${COLORS[RESET]}"
    echo
    echo -e "${COLORS[CYAN]}This wizard will guide you through setting up your own professional media server.${COLORS[RESET]}"
    echo -e "${COLORS[CYAN]}You'll get:${COLORS[RESET]}"
    echo
    echo -e "  ${SYMBOLS[MOVIE]} ${COLORS[GREEN]}Jellyfin Media Server${COLORS[RESET]} - Stream movies, TV shows, music anywhere"
    echo -e "  ${SYMBOLS[DOWNLOAD]} ${COLORS[GREEN]}Automatic Downloads${COLORS[RESET]} - New episodes appear overnight"
    echo -e "  ${SYMBOLS[GLOBE]} ${COLORS[GREEN]}Request System${COLORS[RESET]} - Family can request new content"
    echo -e "  ${SYMBOLS[GEAR]} ${COLORS[GREEN]}Professional Dashboard${COLORS[RESET]} - Monitor everything beautifully"
    echo -e "  ${SYMBOLS[SHIELD]} ${COLORS[GREEN]}Secure HTTPS Access${COLORS[RESET]} - SSL certificates and encryption"
    echo -e "  ${SYMBOLS[SPARKLES]} ${COLORS[GREEN]}Storage Optimization${COLORS[RESET]} - Automatic file compression"
    echo
    echo -e "${COLORS[YELLOW]}${SYMBOLS[INFO]} ${COLORS[BOLD]}What you'll need:${COLORS[RESET]}"
    echo -e "  ${SYMBOLS[BULLET]} A computer with Docker installed"
    echo -e "  ${SYMBOLS[BULLET]} A domain name (\$10-15/year)"
    echo -e "  ${SYMBOLS[BULLET]} Cloudflare account (free)"
    echo -e "  ${SYMBOLS[BULLET]} 30-60 minutes of your time"
    echo
    echo -e "${COLORS[GREEN]}${SYMBOLS[TROPHY]} ${COLORS[BOLD]}Result: Save \$1,500+/year vs Netflix, Hulu, Disney+!${COLORS[RESET]}"
    echo
    
    if ! prompt_yn "Ready to build your own media empire?" "y"; then
        echo -e "${COLORS[YELLOW]}Come back when you're ready! ${SYMBOLS[SPARKLES]}${COLORS[RESET]}"
        exit 0
    fi
    
    save_progress
}

step_system_check() {
    clear_screen
    CURRENT_STEP=2
    show_progress $CURRENT_STEP $TOTAL_STEPS
    
    section_header "System Requirements Check" "Verifying your system is ready for the media stack" "${SYMBOLS[GEAR]}"
    
    info_message "Checking system compatibility..."
    echo
    
    # Check OS
    echo -ne "Operating System: "
    case "$(uname -s)" in
        Linux*) echo -e "${COLORS[GREEN]}Linux ${SYMBOLS[CHECK]}${COLORS[RESET]}" ;;
        Darwin*) echo -e "${COLORS[GREEN]}macOS ${SYMBOLS[CHECK]}${COLORS[RESET]}" ;;
        CYGWIN*|MINGW*|MSYS*) echo -e "${COLORS[GREEN]}Windows ${SYMBOLS[CHECK]}${COLORS[RESET]}" ;;
        *) echo -e "${COLORS[RED]}Unknown ${SYMBOLS[CROSS]}${COLORS[RESET]}" ;;
    esac
    
    # Check Docker
    echo -ne "Docker Installation: "
    if command -v docker >/dev/null 2>&1; then
        if docker --version >/dev/null 2>&1; then
            echo -e "${COLORS[GREEN]}Installed ${SYMBOLS[CHECK]}${COLORS[RESET]}"
        else
            echo -e "${COLORS[RED]}Not working ${SYMBOLS[CROSS]}${COLORS[RESET]}"
            error_message "Docker is installed but not working. Please check Docker Desktop is running."
            exit 1
        fi
    else
        echo -e "${COLORS[RED]}Not installed ${SYMBOLS[CROSS]}${COLORS[RESET]}"
        error_message "Docker is required. Please install Docker Desktop first."
        echo
        info_message "Download from: https://www.docker.com/products/docker-desktop/"
        exit 1
    fi
    
    # Check Docker Compose
    echo -ne "Docker Compose: "
    if docker compose version >/dev/null 2>&1; then
        echo -e "${COLORS[GREEN]}Available ${SYMBOLS[CHECK]}${COLORS[RESET]}"
    else
        echo -e "${COLORS[RED]}Not available ${SYMBOLS[CROSS]}${COLORS[RESET]}"
        error_message "Docker Compose is required but not available."
        exit 1
    fi
    
    # Check available space (use df -k for Linux and macOS portability)
    echo -ne "Available Disk Space: "
    if df -k . >/dev/null 2>&1; then
        avail_kb=$(df -k . | awk 'NR==2 {print $4}')
        available=$(( avail_kb / 1024 / 1024 ))
    else
        available=0
    fi
    if [ "$available" -gt 20 ]; then
        echo -e "${COLORS[GREEN]}${available}GB ${SYMBOLS[CHECK]}${COLORS[RESET]}"
    elif [ "$available" -gt 10 ]; then
        echo -e "${COLORS[YELLOW]}${available}GB ${SYMBOLS[WARNING]}${COLORS[RESET]}"
        warning_message "Low disk space. Consider external storage for media files."
    else
        echo -e "${COLORS[RED]}${available}GB ${SYMBOLS[CROSS]}${COLORS[RESET]}"
        error_message "Insufficient disk space. Need at least 10GB free."
        exit 1
    fi
    
    # Check RAM
    echo -ne "Available Memory: "
    case "$(uname)" in
      Linux)
        if command -v free >/dev/null 2>&1; then
            total_mem_kb=$(free -k | awk 'NR==2{print $2}')
            ram_gb=$(( total_mem_kb / 1024 / 1024 ))
        else
            ram_gb=8
        fi
        ;;
      Darwin)
        if command -v sysctl >/dev/null 2>&1; then
            mem_bytes=$(sysctl -n hw.memsize)
            ram_gb=$(( mem_bytes / 1024 / 1024 / 1024 ))
        else
            ram_gb=8
        fi
        ;;
      *)
        ram_gb=8
        ;;
    esac

    if [ "$ram_gb" -ge 8 ]; then
        echo -e "${COLORS[GREEN]}${ram_gb}GB ${SYMBOLS[CHECK]}${COLORS[RESET]}"
    elif [ "$ram_gb" -ge 4 ]; then
        echo -e "${COLORS[YELLOW]}${ram_gb}GB ${SYMBOLS[WARNING]}${COLORS[RESET]}"
        warning_message "4GB RAM is minimum. 8GB+ recommended for best performance."
    else
        echo -e "${COLORS[RED]}${ram_gb}GB ${SYMBOLS[CROSS]}${COLORS[RESET]}"
        error_message "Insufficient RAM. Need at least 4GB."
        exit 1
    fi
    
    echo
    success_message "System check completed! Your computer is ready."
    
    if prompt_yn "Continue to domain configuration?" "y"; then
        save_progress
        return 0
    else
        exit 0
    fi
}

step_domain_setup() {
    clear_screen
    CURRENT_STEP=3
    show_progress $CURRENT_STEP $TOTAL_STEPS
    
    section_header "Domain & DNS Configuration" "Setting up your domain name for secure HTTPS access" "${SYMBOLS[GLOBE]}"
    
    echo -e "${COLORS[CYAN]}A domain name gives you:${COLORS[RESET]}"
    echo -e "  ${SYMBOLS[BULLET]} Professional URLs (https://movies.yourname.com)"
    echo -e "  ${SYMBOLS[BULLET]} Free SSL certificates (secure green lock)"
    echo -e "  ${SYMBOLS[BULLET]} Remote access from anywhere in the world"
    echo -e "  ${SYMBOLS[BULLET]} Easy sharing with family and friends"
    echo
    echo -e "${COLORS[YELLOW]}${SYMBOLS[INFO]} Cost: \$10-15/year (cheaper than 1 month of Netflix!)${COLORS[RESET]}"
    echo
    
    # Check if domain is already configured
    if [ -f ".env" ] && grep -q "DOMAIN=" ".env" && ! grep -q "yourdomain.com" ".env"; then
        local existing_domain=$(grep "DOMAIN=" ".env" | cut -d= -f2)
        info_message "Found existing domain: $existing_domain"
        if prompt_yn "Use this domain?" "y"; then
            DOMAIN="$existing_domain"
            save_progress
            return 0
        fi
    fi
    
    echo -e "${COLORS[BLUE]}${SYMBOLS[INFO]} ${COLORS[BOLD]}Don't have a domain yet?${COLORS[RESET]}"
    echo -e "  1. Go to ${COLORS[CYAN]}https://namecheap.com${COLORS[RESET]} or ${COLORS[CYAN]}https://cloudflare.com${COLORS[RESET]}"
    echo -e "  2. Search for something like: ${COLORS[GREEN]}media-yourname.com${COLORS[RESET]}"
    echo -e "  3. Purchase for ~\$12/year"
    echo -e "  4. Come back here with your domain name"
    echo
    
    DOMAIN=$(prompt_input "Enter your domain name:" "" validate_domain "Example: media.smith.com")
    
    echo
    info_message "Domain set to: $DOMAIN"
    info_message "You'll access your media server at: https://jellyfin.$DOMAIN"
    
    save_progress
}

step_cloudflare_setup() {
    clear_screen
    CURRENT_STEP=4
    show_progress $CURRENT_STEP $TOTAL_STEPS
    
    section_header "Cloudflare Configuration" "Setting up free SSL certificates and DNS management" "${SYMBOLS[SHIELD]}"
    
    echo -e "${COLORS[CYAN]}Cloudflare provides:${COLORS[RESET]}"
    echo -e "  ${SYMBOLS[BULLET]} Free SSL certificates (normally \$100+/year)"
    echo -e "  ${SYMBOLS[BULLET]} Fast global DNS resolution"
    echo -e "  ${SYMBOLS[BULLET]} DDoS protection for your server"
    echo -e "  ${SYMBOLS[BULLET]} Easy DNS management"
    echo
    
    # Check for existing Cloudflare config
    if [ -f ".env" ] && grep -q "CLOUDFLARE_EMAIL=" ".env" && ! grep -q "your-email" ".env"; then
        local existing_email=$(grep "CLOUDFLARE_EMAIL=" ".env" | cut -d= -f2)
        info_message "Found existing Cloudflare email: $existing_email"
        if prompt_yn "Use this configuration?" "y"; then
            save_progress
            return 0
        fi
    fi
    
    echo -e "${COLORS[BLUE]}${SYMBOLS[INFO]} ${COLORS[BOLD]}Don't have Cloudflare setup yet?${COLORS[RESET]}"
    echo -e "  1. Go to ${COLORS[CYAN]}https://cloudflare.com${COLORS[RESET]} and create free account"
    echo -e "  2. Add your domain ($DOMAIN)"
    echo -e "  3. Change nameservers at your domain registrar"
    echo -e "  4. Wait for DNS to activate (up to 24 hours)"
    echo
    
    CLOUDFLARE_EMAIL=$(prompt_input "Enter your Cloudflare email:" "" validate_email "The email you used to register with Cloudflare")
    
    echo
    echo -e "${COLORS[BLUE]}${SYMBOLS[KEY]} ${COLORS[BOLD]}Now we need your API token:${COLORS[RESET]}"
    echo -e "  1. Go to ${COLORS[CYAN]}https://dash.cloudflare.com/profile/api-tokens${COLORS[RESET]}"
    echo -e "  2. Click ${COLORS[GREEN]}\"Create Token\"${COLORS[RESET]}"
    echo -e "  3. Use ${COLORS[GREEN]}\"Edit zone DNS\"${COLORS[RESET]} template"
    echo -e "  4. Configure: Zone Resources → Include → Specific zone → $DOMAIN"
    echo -e "  5. Click ${COLORS[GREEN]}\"Continue to summary\"${COLORS[RESET]} → ${COLORS[GREEN]}\"Create Token\"${COLORS[RESET]}"
    echo -e "  6. Copy the token (starts with numbers/letters)"
    echo
    
    CLOUDFLARE_API_TOKEN=$(prompt_input "Paste your Cloudflare API token:" "" validate_api_key "Should be 40+ characters long")
    
    echo
    success_message "Cloudflare configuration saved!"
    info_message "SSL certificates will be automatically generated"
    
    save_progress
}

step_storage_setup() {
    clear_screen
    CURRENT_STEP=5
    show_progress $CURRENT_STEP $TOTAL_STEPS
    
    section_header "Storage Configuration" "Setting up directories for your media collection" "${SYMBOLS[FOLDER]}"
    
    echo -e "${COLORS[CYAN]}Your media stack needs directories for:${COLORS[RESET]}"
    echo -e "  ${SYMBOLS[MOVIE]} Movies, TV shows, music, books"
    echo -e "  ${SYMBOLS[DOWNLOAD]} Downloaded content and processing"
    echo -e "  ${SYMBOLS[GEAR]} Application configuration and logs"
    echo
    
    echo -e "${COLORS[YELLOW]}${SYMBOLS[INFO]} ${COLORS[BOLD]}Storage Recommendations:${COLORS[RESET]}"
    echo -e "  ${SYMBOLS[BULLET]} ${COLORS[GREEN]}External USB Drive:${COLORS[RESET]} 4TB+ for large collections"
    echo -e "  ${SYMBOLS[BULLET]} ${COLORS[GREEN]}Internal Drive:${COLORS[RESET]} Fast for smaller collections"
    echo -e "  ${SYMBOLS[BULLET]} ${COLORS[GREEN]}Network Storage:${COLORS[RESET]} NAS or cloud storage"
    echo
    
    # Detect storage options
    echo -e "${COLORS[BLUE]}${SYMBOLS[INFO]} Detecting available storage...${COLORS[RESET]}"
    echo
    
    # Show current disk usage
    echo -e "${COLORS[DIM]}Current storage:${COLORS[RESET]}"
    df -h | grep -E '^/dev/' | while read -r line; do
        echo -e "  ${SYMBOLS[BULLET]} $line"
    done
    echo
    
    # Check for external drives
    echo -e "${COLORS[BLUE]}${SYMBOLS[INFO]} Looking for external drives...${COLORS[RESET]}"
    external_drives=()
    if command -v lsblk >/dev/null 2>&1; then
        while IFS= read -r line; do
            if [[ "$line" =~ /mnt/|/media/ ]] && [[ ! "$line" =~ "loop" ]]; then
                external_drives+=("$line")
            fi
        done < <(lsblk -f 2>/dev/null | grep -E '/mnt/|/media/')
    fi
    
    if [ ${#external_drives[@]} -gt 0 ]; then
        echo -e "${COLORS[GREEN]}Found external storage:${COLORS[RESET]}"
        for drive in "${external_drives[@]}"; do
            echo -e "  ${SYMBOLS[CHECK]} $drive"
        done
        echo
    else
        warning_message "No external drives detected. Using internal storage."
        echo
    fi
    
    # Get storage preferences
    if [ ${#external_drives[@]} -gt 0 ]; then
        if prompt_yn "Use external drive for media storage?" "y"; then
            MEDIA_PATH=$(prompt_input "Enter external drive path:" "/mnt/media-drive" validate_path "Example: /mnt/media-drive")
        else
            MEDIA_PATH=$(prompt_input "Enter media storage path:" "/media" validate_path "Example: /media")
        fi
    else
        MEDIA_PATH=$(prompt_input "Enter media storage path:" "/media" validate_path "Example: /media")
    fi
    
    DOWNLOADS_PATH=$(prompt_input "Enter downloads path:" "$MEDIA_PATH/downloads" validate_path "Example: $MEDIA_PATH/downloads")
    
    echo
    info_message "Creating directory structure..."
    
    # Create directories
    directories=(
        "$MEDIA_PATH/movies"
        "$MEDIA_PATH/tv"
        "$MEDIA_PATH/music"
        "$MEDIA_PATH/books"
        "$MEDIA_PATH/anime"
        "$MEDIA_PATH/documentaries"
        "$MEDIA_PATH/4k"
        "$DOWNLOADS_PATH/complete"
        "$DOWNLOADS_PATH/incomplete"
        "$DOWNLOADS_PATH/convert-input"
        "$DOWNLOADS_PATH/convert-output"
        "./config"
    )
    
    for dir in "${directories[@]}"; do
        if mkdir -p "$dir" 2>/dev/null; then
            echo -e "  ${SYMBOLS[CHECK]} Created: $dir"
        else
            echo -e "  ${SYMBOLS[WARNING]} Need sudo for: $dir"
            if sudo mkdir -p "$dir"; then
                echo -e "  ${SYMBOLS[CHECK]} Created with sudo: $dir"
            else
                error_message "Failed to create: $dir"
                exit 1
            fi
        fi
    done
    
    # Set permissions
    echo
    info_message "Setting permissions..."
    user_id=$(id -u)
    group_id=$(id -g)
    
    if [ "$user_id" != "0" ]; then
        if sudo chown -R "$user_id:$group_id" "$MEDIA_PATH" "$DOWNLOADS_PATH" "./config" 2>/dev/null; then
            success_message "Permissions set successfully"
        else
            warning_message "Could not set all permissions. May need manual adjustment."
        fi
    fi
    
    echo
    success_message "Storage configuration completed!"
    info_message "Media path: $MEDIA_PATH"
    info_message "Downloads path: $DOWNLOADS_PATH"
    
    save_progress
}

step_environment_config() {
    clear_screen
    CURRENT_STEP=6
    show_progress $CURRENT_STEP $TOTAL_STEPS
    
    section_header "Environment Configuration" "Creating your personalized configuration file" "${SYMBOLS[GEAR]}"
    
    echo -e "${COLORS[CYAN]}Creating your .env configuration file...${COLORS[RESET]}"
    echo
    
    # Create .env file
    cat > .env << EOF
# Media Stack Configuration - Generated by Setup Wizard
# Generated on: $(date)

# ================================
# CORE CONFIGURATION
# ================================

# Domain Configuration
DOMAIN=$DOMAIN
COMPOSE_PROJECT_NAME=media-stack

# System Configuration
TZ=$(prompt_input "Enter your timezone:" "$(date +%Z)" "" "Examples: America/New_York, Europe/London, Asia/Tokyo")
PUID=$(id -u)
PGID=$(id -g)
UMASK=002

# ================================
# INFRASTRUCTURE
# ================================

# Cloudflare SSL Configuration
CLOUDFLARE_EMAIL=$CLOUDFLARE_EMAIL
CLOUDFLARE_API_TOKEN=$CLOUDFLARE_API_TOKEN

# Network Configuration
NETWORK_NAME=media-network
EXTERNAL_HTTP_PORT=80
EXTERNAL_HTTPS_PORT=443
EXTERNAL_HTTPS_UDP_PORT=443

# ================================
# STORAGE PATHS
# ================================

# Base Paths
CONFIG_PATH=./config
MEDIA_PATH=$MEDIA_PATH
DOWNLOADS_PATH=$DOWNLOADS_PATH
TEMP_PATH=/tmp

# Media Library Paths
MOVIES_PATH=\${MEDIA_PATH}/movies
TV_PATH=\${MEDIA_PATH}/tv
MUSIC_PATH=\${MEDIA_PATH}/music
BOOKS_PATH=\${MEDIA_PATH}/books
ANIME_PATH=\${MEDIA_PATH}/anime
DOCUMENTARIES_PATH=\${MEDIA_PATH}/documentaries
4K_PATH=\${MEDIA_PATH}/4k

# Processing Paths
DOWNLOADS_COMPLETE=\${DOWNLOADS_PATH}/complete
DOWNLOADS_INCOMPLETE=\${DOWNLOADS_PATH}/incomplete
DOWNLOADS_CONVERT_INPUT=\${DOWNLOADS_PATH}/convert-input
DOWNLOADS_CONVERT_OUTPUT=\${DOWNLOADS_PATH}/convert-output
TDARR_TRANSCODE=\${DOWNLOADS_PATH}/tdarr-transcode
JELLYFIN_TRANSCODE=\${TEMP_PATH}/jellyfin-transcode

# ================================
# HARDWARE ACCELERATION
# ================================

# GPU Configuration
ENABLE_NVIDIA_GPU=false
ENABLE_INTEL_GPU=false
ENABLE_AMD_GPU=false

# ================================
# SERVICE CONFIGURATION
# ================================

# Jellyfin
JELLYFIN_PUBLISHED_SERVER_URL=https://jellyfin.\${DOMAIN}
JELLYFIN_FFMPEG_PROBESIZE=50000000
JELLYFIN_FFMPEG_ANALYZEDURATION=50000000

# Tdarr Processing
TDARR_SERVER_IP=0.0.0.0
TDARR_SERVER_PORT=8265
TDARR_WEBUI_PORT=8266
TDARR_NODE_NAME=TdarrMainNode
TDARR_CPU_WORKERS=2
TDARR_GPU_WORKERS=1
TDARR_HEALTHCHECK_CPU_WORKERS=1
TDARR_HEALTHCHECK_GPU_WORKERS=1
TDARR_CPU_WORKERS_2=1
TDARR_FFMPEG_VERSION=7

# qBittorrent
QBITTORRENT_WEBUI_PORT=8080
QBITTORRENT_USERNAME=admin
QBITTORRENT_PASSWORD=adminadmin

# API Keys (will be configured later)
JELLYFIN_API_KEY=
SONARR_API_KEY=
RADARR_API_KEY=
LIDARR_API_KEY=
READARR_API_KEY=
PROWLARR_API_KEY=
OVERSEERR_API_KEY=
TAUTULLI_API_KEY=
BAZARR_API_KEY=

# Monitoring & Alerts
DISCORD_WEBHOOK_URL=
SMTP_HOST=smtp.gmail.com
SMTP_USERNAME=
SMTP_PASSWORD=
ALERT_EMAIL=admin@\${DOMAIN}

# Container Restart Policy
RESTART_POLICY=unless-stopped
EOF

    echo
    success_message "Configuration file created successfully!"
    info_message "Location: $(pwd)/.env"
    
    save_progress
}

step_gpu_detection() {
    clear_screen
    CURRENT_STEP=7
    show_progress $CURRENT_STEP $TOTAL_STEPS
    
    section_header "GPU Detection & Hardware Acceleration" "Optimizing performance with hardware acceleration" "${SYMBOLS[ROCKET]}"
    
    echo -e "${COLORS[CYAN]}Hardware acceleration provides:${COLORS[RESET]}"
    echo -e "  ${SYMBOLS[BULLET]} 10-20x faster video transcoding"
    echo -e "  ${SYMBOLS[BULLET]} Multiple simultaneous streams"
    echo -e "  ${SYMBOLS[BULLET]} Lower CPU usage and power consumption"
    echo -e "  ${SYMBOLS[BULLET]} Better quality at lower file sizes"
    echo
    
    info_message "Detecting available GPU hardware..."
    echo
    
    # Detect NVIDIA GPU
    gpu_detected=""
    if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
        gpu_name=$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits | head -1)
        echo -e "  ${SYMBOLS[CHECK]} ${COLORS[GREEN]}NVIDIA GPU detected: $gpu_name${COLORS[RESET]}"
        gpu_detected="nvidia"
        
        # Check for newer features
        if nvidia-smi --query-gpu=compute_cap --format=csv,noheader,nounits | head -1 | awk '{print ($1 >= 7.5)}' | grep -q 1; then
            echo -e "    ${SYMBOLS[SPARKLES]} ${COLORS[GREEN]}Supports modern features (Turing+)${COLORS[RESET]}"
        fi
    else
        echo -e "  ${SYMBOLS[CROSS]} ${COLORS[DIM]}NVIDIA GPU: Not detected${COLORS[RESET]}"
    fi
    
    # Detect Intel GPU
    if [ -d /dev/dri ] && ls /dev/dri/render* >/dev/null 2>&1; then
        intel_gpu=$(lspci | grep -i "vga.*intel" | head -1 | cut -d: -f3 | xargs)
        if [ -n "$intel_gpu" ]; then
            echo -e "  ${SYMBOLS[CHECK]} ${COLORS[GREEN]}Intel GPU detected: $intel_gpu${COLORS[RESET]}"
            if [ -n "$gpu_detected" ]; then
                gpu_detected="${gpu_detected}+intel"
            else
                gpu_detected="intel"
            fi
        fi
    else
        echo -e "  ${SYMBOLS[CROSS]} ${COLORS[DIM]}Intel GPU: Not detected${COLORS[RESET]}"
    fi
    
    # Detect AMD GPU
    if lspci | grep -i "vga.*amd" >/dev/null 2>&1; then
        amd_gpu=$(lspci | grep -i "vga.*amd" | head -1 | cut -d: -f3 | xargs)
        echo -e "  ${SYMBOLS[CHECK]} ${COLORS[GREEN]}AMD GPU detected: $amd_gpu${COLORS[RESET]}"
        if [ -n "$gpu_detected" ]; then
            gpu_detected="${gpu_detected}+amd"
        else
            gpu_detected="amd"
        fi
    else
        echo -e "  ${SYMBOLS[CROSS]} ${COLORS[DIM]}AMD GPU: Not detected${COLORS[RESET]}"
    fi
    
    echo
    
    if [ -z "$gpu_detected" ]; then
        warning_message "No GPU acceleration detected - will use CPU transcoding"
        echo -e "${COLORS[DIM]}CPU transcoding is slower but works on any hardware${COLORS[RESET]}"
    else
        success_message "GPU acceleration available: $gpu_detected"
        
        if prompt_yn "Enable GPU acceleration for faster transcoding?" "y"; then
            case "$gpu_detected" in
                *nvidia*)
                    sed -i.bak 's/ENABLE_NVIDIA_GPU=false/ENABLE_NVIDIA_GPU=true/' .env
                    info_message "NVIDIA GPU acceleration enabled"
                    ;;
                *intel*)
                    sed -i.bak 's/ENABLE_INTEL_GPU=false/ENABLE_INTEL_GPU=true/' .env
                    info_message "Intel GPU acceleration enabled"
                    ;;
                *amd*)
                    sed -i.bak 's/ENABLE_AMD_GPU=false/ENABLE_AMD_GPU=true/' .env
                    info_message "AMD GPU acceleration enabled"
                    ;;
            esac
            rm -f .env.bak
        fi
    fi
    
    save_progress
}

step_deployment() {
    clear_screen
    CURRENT_STEP=8
    show_progress $CURRENT_STEP $TOTAL_STEPS
    
    section_header "Service Deployment" "Downloading and starting your media stack services" "${SYMBOLS[DOWNLOAD]}"
    
    echo -e "${COLORS[CYAN]}Deploying services:${COLORS[RESET]}"
    echo -e "  ${SYMBOLS[MOVIE]} Jellyfin Media Server"
    echo -e "  ${SYMBOLS[TV]} Sonarr (TV Shows)"
    echo -e "  ${SYMBOLS[MOVIE]} Radarr (Movies)"
    echo -e "  ${SYMBOLS[MUSIC]} Lidarr (Music)"
    echo -e "  ${SYMBOLS[BOOK]} Readarr (Books)"
    echo -e "  ${SYMBOLS[DOWNLOAD]} qBittorrent (Downloads)"
    echo -e "  ${SYMBOLS[GEAR]} Tdarr (Optimization)"
    echo -e "  ${SYMBOLS[GLOBE]} Caddy (Reverse Proxy)"
    echo -e "  ${SYMBOLS[SPARKLES]} Dashboard & Monitoring"
    echo
    
    # Generate optimized docker-compose.yml
    info_message "Generating optimized Docker Compose configuration..."
    
    # Copy the optimized template
    if [ -f "docker-compose.optimized.yml" ]; then
        cp docker-compose.optimized.yml docker-compose.yml
        success_message "Docker Compose configuration ready"
    else
        error_message "docker-compose.optimized.yml not found!"
        exit 1
    fi
    
    # Pull images
    echo
    info_message "Downloading Docker images (this may take 10-15 minutes)..."
    echo
    
    (
        docker compose pull 2>&1 | while read -r line; do
            if [[ "$line" =~ "Pulling" ]]; then
                service=$(echo "$line" | awk '{print $2}')
                echo -e "  ${SYMBOLS[ARROW]} Downloading: ${COLORS[CYAN]}$service${COLORS[RESET]}"
            fi
        done
    ) &
    pull_pid=$!
    spinner $pull_pid "Downloading images"
    wait $pull_pid
    
    if [ $? -eq 0 ]; then
        success_message "All images downloaded successfully"
    else
        error_message "Failed to download some images"
        exit 1
    fi
    
    # Start services
    echo
    info_message "Starting services..."
    echo
    
    (docker compose up -d) &
    start_pid=$!
    spinner $start_pid "Starting containers"
    wait $start_pid
    
    if [ $? -eq 0 ]; then
        success_message "All services started successfully"
    else
        error_message "Failed to start some services"
        exit 1
    fi
    
    # Wait for services to initialize
    echo
    info_message "Waiting for services to initialize..."
    sleep 15
    
    # Check service health
    echo
    info_message "Checking service health..."
    
    services=("caddy" "jellyfin" "sonarr" "radarr" "qbittorrent" "homarr")
    failed_services=()
    
    for service in "${services[@]}"; do
        if docker compose ps "$service" 2>/dev/null | grep -q "Up"; then
            echo -e "  ${SYMBOLS[CHECK]} ${COLORS[GREEN]}$service: Running${COLORS[RESET]}"
        else
            echo -e "  ${SYMBOLS[CROSS]} ${COLORS[RED]}$service: Failed${COLORS[RESET]}"
            failed_services+=("$service")
        fi
    done
    
    if [ ${#failed_services[@]} -eq 0 ]; then
        echo
        success_message "All core services are healthy and running!"
    else
        echo
        warning_message "Some services failed to start: ${failed_services[*]}"
        info_message "You can check logs later with: ./deploy.sh logs [service-name]"
    fi
    
    save_progress
}

step_dns_configuration() {
    clear_screen
    CURRENT_STEP=9
    show_progress $CURRENT_STEP $TOTAL_STEPS
    
    section_header "DNS Records Configuration" "Setting up domain records for external access" "${SYMBOLS[GLOBE]}"
    
    echo -e "${COLORS[CYAN]}Your services are running locally. Now let's make them accessible from anywhere!${COLORS[RESET]}"
    echo
    
    # Get public IP
    echo -e "${COLORS[BLUE]}${SYMBOLS[INFO]} Getting your public IP address...${COLORS[RESET]}"
    public_ip=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "Unable to detect")
    
    if [ "$public_ip" = "Unable to detect" ]; then
        warning_message "Could not automatically detect your public IP"
        public_ip=$(prompt_input "Please enter your public IP:" "" "" "Visit https://whatismyip.com to find it")
    else
        success_message "Your public IP: $public_ip"
    fi
    
    echo
    echo -e "${COLORS[YELLOW]}${SYMBOLS[WARNING]} ${COLORS[BOLD]}IMPORTANT DNS SETUP REQUIRED${COLORS[RESET]}"
    echo
    echo -e "${COLORS[CYAN]}You need to add these DNS records in Cloudflare:${COLORS[RESET]}"
    echo
    
    # DNS records table
    echo -e "${COLORS[BLUE]}┌─────────────────────┬──────┬─────────────────┬─────┐${COLORS[RESET]}"
    echo -e "${COLORS[BLUE]}│ ${COLORS[BOLD]}Name${COLORS[RESET]}${COLORS[BLUE]}                │ ${COLORS[BOLD]}Type${COLORS[RESET]}${COLORS[BLUE]} │ ${COLORS[BOLD]}Content${COLORS[RESET]}${COLORS[BLUE]}         │ ${COLORS[BOLD]}TTL${COLORS[RESET]}${COLORS[BLUE]} │${COLORS[RESET]}"
    echo -e "${COLORS[BLUE]}├─────────────────────┼──────┼─────────────────┼─────┤${COLORS[RESET]}"
    
    subdomains=("dashboard" "jellyfin" "status" "sonarr" "radarr" "qbittorrent" "overseerr" "tdarr")
    for subdomain in "${subdomains[@]}"; do
        printf "${COLORS[BLUE]}│${COLORS[RESET]} %-19s ${COLORS[BLUE]}│${COLORS[RESET]} A    ${COLORS[BLUE]}│${COLORS[RESET]} %-15s ${COLORS[BLUE]}│${COLORS[RESET]} Auto ${COLORS[BLUE]}│${COLORS[RESET]}\n" "$subdomain" "$public_ip"
    done
    
    echo -e "${COLORS[BLUE]}└─────────────────────┴──────┴─────────────────┴─────┘${COLORS[RESET]}"
    echo
    
    echo -e "${COLORS[BLUE]}${SYMBOLS[INFO]} ${COLORS[BOLD]}Steps to add DNS records:${COLORS[RESET]}"
    echo -e "  1. Go to ${COLORS[CYAN]}https://dash.cloudflare.com${COLORS[RESET]}"
    echo -e "  2. Click on your domain: ${COLORS[GREEN]}$DOMAIN${COLORS[RESET]}"
    echo -e "  3. Click ${COLORS[GREEN]}\"DNS\"${COLORS[RESET]} tab"
    echo -e "  4. For each subdomain above:"
    echo -e "     ${SYMBOLS[BULLET]} Click ${COLORS[GREEN]}\"Add record\"${COLORS[RESET]}"
    echo -e "     ${SYMBOLS[BULLET]} Type: ${COLORS[GREEN]}A${COLORS[RESET]}"
    echo -e "     ${SYMBOLS[BULLET]} Name: ${COLORS[GREEN]}[subdomain]${COLORS[RESET]} (e.g., dashboard)"
    echo -e "     ${SYMBOLS[BULLET]} IPv4 address: ${COLORS[GREEN]}$public_ip${COLORS[RESET]}"
    echo -e "     ${SYMBOLS[BULLET]} Proxy status: ${COLORS[YELLOW]}DNS only${COLORS[RESET]} (gray cloud)"
    echo -e "     ${SYMBOLS[BULLET]} TTL: ${COLORS[GREEN]}Auto${COLORS[RESET]}"
    echo
    
    if prompt_yn "Have you added all DNS records in Cloudflare?" "n"; then
        echo
        info_message "DNS records configured! They may take a few minutes to propagate."
    else
        echo
        warning_message "You'll need to add DNS records before external access works."
        info_message "You can continue setup and add them later."
    fi
    
    save_progress
}

step_port_forwarding() {
    clear_screen
    CURRENT_STEP=10
    show_progress $CURRENT_STEP $TOTAL_STEPS
    
    section_header "Router Port Forwarding" "Configuring your router for external access" "${SYMBOLS[GLOBE]}"
    
    echo -e "${COLORS[CYAN]}Port forwarding allows external access to your media server.${COLORS[RESET]}"
    echo
    echo -e "${COLORS[YELLOW]}${SYMBOLS[INFO]} ${COLORS[BOLD]}Required ports:${COLORS[RESET]}"
    echo -e "  ${SYMBOLS[BULLET]} Port 80 (HTTP) → Redirects to HTTPS"
    echo -e "  ${SYMBOLS[BULLET]} Port 443 (HTTPS) → Secure web access"
    echo
    
    # Detect local IP
    local_ip=""
    if command -v ip >/dev/null 2>&1; then
        local_ip=$(ip route get 8.8.8.8 | awk '{print $7; exit}' 2>/dev/null)
    elif command -v ifconfig >/dev/null 2>&1; then
        local_ip=$(ifconfig | grep 'inet ' | grep -v '127.0.0.1' | head -1 | awk '{print $2}' | cut -d: -f2)
    fi
    
    if [ -n "$local_ip" ]; then
        success_message "Your computer's local IP: $local_ip"
    else
        warning_message "Could not detect local IP automatically"
        local_ip=$(prompt_input "Enter your computer's local IP:" "192.168.1.100" "" "Find it with: ip addr or ipconfig")
    fi
    
    # Detect router IP
    router_ip=""
    if command -v ip >/dev/null 2>&1; then
        router_ip=$(ip route | grep default | head -1 | awk '{print $3}')
    elif command -v netstat >/dev/null 2>&1; then
        router_ip=$(netstat -rn | grep '^0.0.0.0' | head -1 | awk '{print $2}')
    fi
    
    if [ -n "$router_ip" ]; then
        info_message "Your router IP: $router_ip"
    else
        router_ip="192.168.1.1"
        info_message "Using common router IP: $router_ip"
    fi
    
    echo
    echo -e "${COLORS[BLUE]}${SYMBOLS[INFO]} ${COLORS[BOLD]}Port forwarding steps:${COLORS[RESET]}"
    echo -e "  1. Open web browser and go to: ${COLORS[CYAN]}http://$router_ip${COLORS[RESET]}"
    echo -e "  2. Login with admin credentials (often on router label)"
    echo -e "  3. Find ${COLORS[GREEN]}\"Port Forwarding\"${COLORS[RESET]} or ${COLORS[GREEN]}\"NAT\"${COLORS[RESET]} section"
    echo -e "  4. Add two rules:"
    echo
    echo -e "${COLORS[GREEN]}Rule 1:${COLORS[RESET]}"
    echo -e "     ${SYMBOLS[BULLET]} Service Name: ${COLORS[GREEN]}Media-Stack-HTTP${COLORS[RESET]}"
    echo -e "     ${SYMBOLS[BULLET]} External Port: ${COLORS[GREEN]}80${COLORS[RESET]}"
    echo -e "     ${SYMBOLS[BULLET]} Internal IP: ${COLORS[GREEN]}$local_ip${COLORS[RESET]}"
    echo -e "     ${SYMBOLS[BULLET]} Internal Port: ${COLORS[GREEN]}80${COLORS[RESET]}"
    echo -e "     ${SYMBOLS[BULLET]} Protocol: ${COLORS[GREEN]}TCP${COLORS[RESET]}"
    echo
    echo -e "${COLORS[GREEN]}Rule 2:${COLORS[RESET]}"
    echo -e "     ${SYMBOLS[BULLET]} Service Name: ${COLORS[GREEN]}Media-Stack-HTTPS${COLORS[RESET]}"
    echo -e "     ${SYMBOLS[BULLET]} External Port: ${COLORS[GREEN]}443${COLORS[RESET]}"
    echo -e "     ${SYMBOLS[BULLET]} Internal IP: ${COLORS[GREEN]}$local_ip${COLORS[RESET]}"
    echo -e "     ${SYMBOLS[BULLET]} Internal Port: ${COLORS[GREEN]}443${COLORS[RESET]}"
    echo -e "     ${SYMBOLS[BULLET]} Protocol: ${COLORS[GREEN]}TCP${COLORS[RESET]}"
    echo
    echo -e "  5. Save settings and restart router"
    echo
    
    echo -e "${COLORS[YELLOW]}${SYMBOLS[WARNING]} ${COLORS[BOLD]}Common router interfaces:${COLORS[RESET]}"
    echo -e "  ${SYMBOLS[BULLET]} ${COLORS[DIM]}Netgear:${COLORS[RESET]} Advanced → Dynamic DNS/Port Forwarding"
    echo -e "  ${SYMBOLS[BULLET]} ${COLORS[DIM]}Linksys:${COLORS[RESET]} Smart Wi-Fi Tools → Port Forwarding"
    echo -e "  ${SYMBOLS[BULLET]} ${COLORS[DIM]}ASUS:${COLORS[RESET]} Adaptive QoS → Port Forwarding"
    echo -e "  ${SYMBOLS[BULLET]} ${COLORS[DIM]}TP-Link:${COLORS[RESET]} Advanced → NAT Forwarding → Port Forwarding"
    echo
    
    if prompt_yn "Have you configured port forwarding in your router?" "n"; then
        success_message "Port forwarding configured!"
    else
        warning_message "External access won't work until port forwarding is set up."
        info_message "You can set this up later and still use the system locally."
    fi
    
    save_progress
}

step_service_configuration() {
    clear_screen
    CURRENT_STEP=11
    show_progress $CURRENT_STEP $TOTAL_STEPS
    
    section_header "Initial Service Configuration" "Setting up your media applications" "${SYMBOLS[GEAR]}"
    
    echo -e "${COLORS[CYAN]}Now let's configure your media services with secure passwords and settings.${COLORS[RESET]}"
    echo
    
    # Test local connectivity
    info_message "Testing local service connectivity..."
    echo
    
    services_to_test=("dashboard:7575" "jellyfin:8096" "qbittorrent:8080")
    for service_port in "${services_to_test[@]}"; do
        service=$(echo "$service_port" | cut -d: -f1)
        port=$(echo "$service_port" | cut -d: -f2)
        
        if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port" | grep -q "200\|302\|401"; then
            echo -e "  ${SYMBOLS[CHECK]} ${COLORS[GREEN]}$service: Accessible${COLORS[RESET]}"
        else
            echo -e "  ${SYMBOLS[WARNING]} ${COLORS[YELLOW]}$service: Not ready yet${COLORS[RESET]}"
        fi
    done
    
    echo
    echo -e "${COLORS[BLUE]}${SYMBOLS[INFO]} ${COLORS[BOLD]}Access your services:${COLORS[RESET]}"
    echo -e "  ${SYMBOLS[MOVIE]} Dashboard: ${COLORS[CYAN]}https://dashboard.$DOMAIN${COLORS[RESET]} or ${COLORS[DIM]}http://localhost:7575${COLORS[RESET]}"
    echo -e "  ${SYMBOLS[MOVIE]} Jellyfin: ${COLORS[CYAN]}https://jellyfin.$DOMAIN${COLORS[RESET]} or ${COLORS[DIM]}http://localhost:8096${COLORS[RESET]}"
    echo -e "  ${SYMBOLS[DOWNLOAD]} qBittorrent: ${COLORS[CYAN]}https://qbittorrent.$DOMAIN${COLORS[RESET]} or ${COLORS[DIM]}http://localhost:8080${COLORS[RESET]}"
    echo
    
    echo -e "${COLORS[YELLOW]}${SYMBOLS[WARNING]} ${COLORS[BOLD]}IMPORTANT SECURITY STEP:${COLORS[RESET]}"
    echo -e "${COLORS[RED]}Change the default qBittorrent password immediately!${COLORS[RESET]}"
    echo
    echo -e "${COLORS[BLUE]}qBittorrent default login:${COLORS[RESET]}"
    echo -e "  Username: ${COLORS[GREEN]}admin${COLORS[RESET]}"
    echo -e "  Password: ${COLORS[GREEN]}adminadmin${COLORS[RESET]}"
    echo
    echo -e "${COLORS[BLUE]}After logging in:${COLORS[RESET]}"
    echo -e "  1. Go to ${COLORS[GREEN]}Tools → Options → Web UI${COLORS[RESET]}"
    echo -e "  2. Change password to something secure"
    echo -e "  3. Set download paths:"
    echo -e "     ${SYMBOLS[BULLET]} Default Save Path: ${COLORS[GREEN]}$DOWNLOADS_PATH/complete${COLORS[RESET]}"
    echo -e "     ${SYMBOLS[BULLET]} Incomplete downloads: ${COLORS[GREEN]}$DOWNLOADS_PATH/incomplete${COLORS[RESET]}"
    echo
    
    if prompt_yn "Open qBittorrent configuration now?" "y"; then
        info_message "Opening qBittorrent in your browser..."
        if command -v xdg-open >/dev/null 2>&1; then
            xdg-open "http://localhost:8080" >/dev/null 2>&1 &
        elif command -v open >/dev/null 2>&1; then
            open "http://localhost:8080" >/dev/null 2>&1 &
        fi
    fi
    
    echo
    echo -e "${COLORS[BLUE]}${SYMBOLS[INFO]} ${COLORS[BOLD]}Next steps (can be done later):${COLORS[RESET]}"
    echo -e "  1. ${COLORS[GREEN]}Jellyfin Setup${COLORS[RESET]}: Create admin user and add media libraries"
    echo -e "  2. ${COLORS[GREEN]}Prowlarr Setup${COLORS[RESET]}: Add indexers for content discovery"
    echo -e "  3. ${COLORS[GREEN]}API Keys${COLORS[RESET]}: Configure dashboard integrations"
    echo -e "  4. ${COLORS[GREEN]}Test Download${COLORS[RESET]}: Add a movie or TV show"
    echo
    
    save_progress
}

step_completion() {
    clear_screen
    CURRENT_STEP=12
    show_progress $CURRENT_STEP $TOTAL_STEPS
    
    echo -e "${COLORS[PURPLE]}╔══════════════════════════════════════════════════════════════════════════╗${COLORS[RESET]}"
    echo -e "${COLORS[PURPLE]}║${COLORS[WHITE]}${COLORS[BOLD]}                   🎉 SETUP COMPLETE! CONGRATULATIONS! 🎉                  ${COLORS[RESET]}${COLORS[PURPLE]}║${COLORS[RESET]}"
    echo -e "${COLORS[PURPLE]}╚══════════════════════════════════════════════════════════════════════════╝${COLORS[RESET]}"
    echo
    
    echo -e "${COLORS[GREEN]}${SYMBOLS[TROPHY]} ${COLORS[BOLD]}Your professional media server is now running!${COLORS[RESET]}"
    echo
    echo -e "${COLORS[CYAN]}${SYMBOLS[SPARKLES]} ${COLORS[BOLD]}What you've accomplished:${COLORS[RESET]}"
    echo -e "  ${SYMBOLS[CHECK]} Professional media server with HTTPS"
    echo -e "  ${SYMBOLS[CHECK]} Automatic content downloading system"
    echo -e "  ${SYMBOLS[CHECK]} Beautiful management dashboard"
    echo -e "  ${SYMBOLS[CHECK]} Request system for family & friends"
    echo -e "  ${SYMBOLS[CHECK]} Storage optimization and monitoring"
    echo -e "  ${SYMBOLS[CHECK]} Secure remote access from anywhere"
    echo
    
    echo -e "${COLORS[BLUE]}${SYMBOLS[GLOBE]} ${COLORS[BOLD]}Access your services:${COLORS[RESET]}"
    echo -e "┌─────────────────────────────────────────────────────────────────────────┐"
    echo -e "│ ${SYMBOLS[MOVIE]} ${COLORS[BOLD]}Main Dashboard:${COLORS[RESET]} ${COLORS[CYAN]}https://dashboard.$DOMAIN${COLORS[RESET]}              │"
    echo -e "│ ${SYMBOLS[TV]} ${COLORS[BOLD]}Watch Movies/TV:${COLORS[RESET]} ${COLORS[CYAN]}https://jellyfin.$DOMAIN${COLORS[RESET]}             │"
    echo -e "│ ${SYMBOLS[STAR]} ${COLORS[BOLD]}Request Content:${COLORS[RESET]} ${COLORS[CYAN]}https://overseerr.$DOMAIN${COLORS[RESET]}            │"
    echo -e "│ ${SYMBOLS[GEAR]} ${COLORS[BOLD]}System Status:${COLORS[RESET]} ${COLORS[CYAN]}https://status.$DOMAIN${COLORS[RESET]}               │"
    echo -e "└─────────────────────────────────────────────────────────────────────────┘"
    echo
    
    echo -e "${COLORS[YELLOW]}${SYMBOLS[INFO]} ${COLORS[BOLD]}Important next steps:${COLORS[RESET]}"
    echo -e "  1. ${COLORS[GREEN]}Change qBittorrent password${COLORS[RESET]} (security!)"
    echo -e "  2. ${COLORS[GREEN]}Configure Jellyfin${COLORS[RESET]} (create admin user)"
    echo -e "  3. ${COLORS[GREEN]}Add indexers in Prowlarr${COLORS[RESET]} (content sources)"
    echo -e "  4. ${COLORS[GREEN]}Setup API keys${COLORS[RESET]} for dashboard: ${COLORS[CYAN]}./scripts/env-manager.sh setup-api-keys${COLORS[RESET]}"
    echo
    
    echo -e "${COLORS[GREEN]}${SYMBOLS[ROCKET]} ${COLORS[BOLD]}Useful commands:${COLORS[RESET]}"
    echo -e "  ${SYMBOLS[BULLET]} Check status: ${COLORS[CYAN]}./deploy.sh status${COLORS[RESET]}"
    echo -e "  ${SYMBOLS[BULLET]} View logs: ${COLORS[CYAN]}./deploy.sh logs [service]${COLORS[RESET]}"
    echo -e "  ${SYMBOLS[BULLET]} Update services: ${COLORS[CYAN]}./deploy.sh update${COLORS[RESET]}"
    echo -e "  ${SYMBOLS[BULLET]} Stop everything: ${COLORS[CYAN]}./deploy.sh stop${COLORS[RESET]}"
    echo
    
    echo -e "${COLORS[PURPLE]}${SYMBOLS[SPARKLES]} ${COLORS[BOLD]}Money saved vs commercial services:${COLORS[RESET]}"
    echo -e "  ${SYMBOLS[BULLET]} Netflix + Hulu + Disney+: ${COLORS[RED]}\$600+/year${COLORS[RESET]}"
    echo -e "  ${SYMBOLS[BULLET]} Your media stack: ${COLORS[GREEN]}\$15/year${COLORS[RESET]} (just domain cost)"
    echo -e "  ${SYMBOLS[BULLET]} ${COLORS[BOLD]}Annual savings: ${COLORS[GREEN]}\$585+${COLORS[RESET]} ${SYMBOLS[TROPHY]}"
    echo
    
    echo -e "${COLORS[CYAN]}${SYMBOLS[INFO]} Need help? Check these guides:${COLORS[RESET]}"
    echo -e "  ${SYMBOLS[BULLET]} Complete guide: ${COLORS[DIM]}COMPLETE_NEWBIE_GUIDE.md${COLORS[RESET]}"
    echo -e "  ${SYMBOLS[BULLET]} Troubleshooting: ${COLORS[DIM]}TROUBLESHOOTING_FLOWCHART.md${COLORS[RESET]}"
    echo -e "  ${SYMBOLS[BULLET]} Dashboard setup: ${COLORS[DIM]}DASHBOARD_MANAGEMENT_GUIDE.md${COLORS[RESET]}"
    echo
    
    # Clean up
    rm -f "$PROGRESS_FILE"
    
    echo -e "${COLORS[GREEN]}${SYMBOLS[PARTY]} ${COLORS[BOLD]}Enjoy your new media empire! ${SYMBOLS[PARTY]}${COLORS[RESET]}"
    echo
    
    if prompt_yn "Open the dashboard now?" "y"; then
        info_message "Opening dashboard in your browser..."
        if command -v xdg-open >/dev/null 2>&1; then
            xdg-open "https://dashboard.$DOMAIN" >/dev/null 2>&1 &
        elif command -v open >/dev/null 2>&1; then
            open "https://dashboard.$DOMAIN" >/dev/null 2>&1 &
        fi
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    # Initialize logging
    touch "$SETUP_LOG"
    log "Setup wizard started"
    
    # Load previous progress
    load_progress
    
    # Check for resume
    if [ "$CURRENT_STEP" -gt 0 ]; then
        clear_screen
        echo -e "${COLORS[YELLOW]}${SYMBOLS[INFO]} Previous setup detected at step $CURRENT_STEP/$TOTAL_STEPS${COLORS[RESET]}"
        if prompt_yn "Resume from where you left off?" "y"; then
            log "Resuming setup from step $CURRENT_STEP"
        else
            CURRENT_STEP=0
            rm -f "$PROGRESS_FILE"
            log "Starting fresh setup"
        fi
    fi
    
    # Execute setup steps
    case $CURRENT_STEP in
        0|1) step_welcome ;;
    esac
    
    case $CURRENT_STEP in
        1|2) step_system_check ;;
    esac
    
    case $CURRENT_STEP in
        2|3) step_domain_setup ;;
    esac
    
    case $CURRENT_STEP in
        3|4) step_cloudflare_setup ;;
    esac
    
    case $CURRENT_STEP in
        4|5) step_storage_setup ;;
    esac
    
    case $CURRENT_STEP in
        5|6) step_environment_config ;;
    esac
    
    case $CURRENT_STEP in
        6|7) step_gpu_detection ;;
    esac
    
    case $CURRENT_STEP in
        7|8) step_deployment ;;
    esac
    
    case $CURRENT_STEP in
        8|9) step_dns_configuration ;;
    esac
    
    case $CURRENT_STEP in
        9|10) step_port_forwarding ;;
    esac
    
    case $CURRENT_STEP in
        10|11) step_service_configuration ;;
    esac
    
    case $CURRENT_STEP in
        11|12) step_completion ;;
    esac
    
    log "Setup wizard completed successfully"
}

# Handle interruption
trap 'echo; warning_message "Setup interrupted. Run again to resume."; save_progress; exit 130' INT

# Run main function
main "$@"