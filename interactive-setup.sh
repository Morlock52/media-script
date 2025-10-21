#!/usr/bin/env bash
# interactive-setup.sh — guided setup wizard with persistent progress tracking for the Media Script stack

set -Eeuo pipefail
trap 'echo "❌ Error on line $LINENO"; exit 1' ERR

# ===== CONFIG =====
ENV_TEMPLATE=".env.example"
ENV_FILE=".env"
LOG_FILE="./setup.log"
PROGRESS_FILE=".setup_progress"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# ===== COLORS =====
BOLD="\033[1m"
RESET="\033[0m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"

log() {
    echo -e "${BOLD}[$TIMESTAMP]${RESET} $1"
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
}

print_header() {
    clear
    echo -e "${BOLD}${GREEN}=== Media Script Interactive Setup ===${RESET}"
    echo "Welcome! This wizard will guide you through configuration."
    echo
}

prompt_choice() {
    local prompt="$1"
    shift
    local options=("$@")
    local choice

    echo "$prompt"
    local i=1
    for opt in "${options[@]}"; do
        echo "  $i) $opt"
        ((i++))
    done

    read -rp "Enter your choice [1-${#options[@]}]: " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#options[@]})); then
        echo "${options[$((choice - 1))]}"
    else
        echo "Invalid choice. Please try again."
        prompt_choice "$prompt" "${options[@]}"
    fi
}

create_env_file() {
    log "Checking for existing $ENV_FILE..."
    if [[ -f "$ENV_FILE" ]]; then
        read -rp "An existing .env was found. Overwrite? (y/N): " overwrite
        if [[ "$overwrite" =~ ^[Yy]$ ]]; then
            rm -f "$ENV_FILE"
            cp "$ENV_TEMPLATE" "$ENV_FILE"
            log "Overwrote existing .env with template."
        else
            log "Keeping existing .env"
        fi
    else
        cp "$ENV_TEMPLATE" "$ENV_FILE"
        log "Created new $ENV_FILE from template."
    fi
}

select_mode() {
    local mode
    mode=$(prompt_choice "Choose deployment mode:" "Local Only (LAN access)" "Remote (Cloudflare + SSL)")
    if [[ "$mode" == "Local Only (LAN access)" ]]; then
        echo "DEPLOY_MODE=local" >> "$ENV_FILE"
        DEPLOY_MODE="local"
        log "Mode: Local only"
    else
        echo "DEPLOY_MODE=remote" >> "$ENV_FILE"
        DEPLOY_MODE="remote"
        log "Mode: Remote access"
        setup_cloudflare
    fi
}

setup_cloudflare() {
    echo
    log "Cloudflare setup selected."
    read -rp "Enter your domain (e.g. example.com): " domain
    read -rp "Enter your Cloudflare API token: " token
    read -rp "Enter your Cloudflare Zone ID: " zone

    {
        echo "CLOUDFLARE_DOMAIN=$domain"
        echo "CLOUDFLARE_API_TOKEN=$token"
        echo "CLOUDFLARE_ZONE_ID=$zone"
    } >> "$ENV_FILE"

    log "Cloudflare configuration written to .env"
}

choose_directories() {
    echo
    log "Let's choose directories for your media and config."
    read -rp "Enter path for media storage [/srv/media]: " media_path
    read -rp "Enter path for configuration files [/srv/config]: " config_path

    media_path=${media_path:-/srv/media}
    config_path=${config_path:-/srv/config}

    mkdir -p "$media_path" "$config_path"
    {
        echo "MEDIA_PATH=$media_path"
        echo "CONFIG_PATH=$config_path"
    } >> "$ENV_FILE"

    log "Directories set up: $media_path and $config_path"
}

confirm_and_summary() {
    echo
    echo -e "${GREEN}Setup complete!${RESET}"
    echo "Here’s a summary of your configuration:"
    echo "--------------------------------------"
    grep -E '^[A-Z0-9_]+=' "$ENV_FILE" || true
    echo "--------------------------------------"
    echo
    read -rp "Would you like to deploy now? (y/N): " deploy_now
    if [[ "$deploy_now" =~ ^[Yy]$ ]]; then
        ./deploy.sh deploy --${DEPLOY_MODE:-local}
    else
        echo "You can deploy later using: ./deploy.sh deploy"
    fi
    # cleanup progress file after completion
    rm -f "$PROGRESS_FILE"
}

# ===== Progress tracking =====
save_progress() {
    echo "$CURRENT_STEP" > "$PROGRESS_FILE"
}

load_progress() {
    if [[ -f "$PROGRESS_FILE" ]]; then
        read -r CURRENT_STEP < "$PROGRESS_FILE"
    else
        CURRENT_STEP=0
    fi
}

# ===== MAIN FLOW =====
print_header

# define ordered list of steps
steps=(create_env_file select_mode choose_directories confirm_and_summary)

# load previous progress if any
load_progress

if [[ $CURRENT_STEP -gt 0 ]]; then
    echo "It looks like you previously exited during setup."
    read -rp "Would you like to resume from where you left off? (Y/n): " resume
    if [[ ! "$resume" =~ ^[Nn]$ ]]; then
        :
    else
        CURRENT_STEP=0
    fi
fi

# run steps from current index
for ((i=CURRENT_STEP; i<${#steps[@]}; i++)); do
    CURRENT_STEP=$i
    "${steps[$i]}"
    save_progress
done

log "✅ Setup finished successfully."
