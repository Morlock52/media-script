#!/bin/bash

# Batch Media Conversion Script
# Queue-based processing with priority and format selection

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUEUE_DIR="/config/ffmpeg/queue"
PROCESSING_DIR="/config/ffmpeg/processing"
COMPLETED_DIR="/config/ffmpeg/completed"
ERROR_DIR="/config/ffmpeg/errors"

# Create necessary directories
mkdir -p "$QUEUE_DIR" "$PROCESSING_DIR" "$COMPLETED_DIR" "$ERROR_DIR"

# Configuration
MAX_CONCURRENT_JOBS=2
LOG_FILE="/config/ffmpeg/batch_conversion.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Job management functions
add_job() {
    local input_file="$1"
    local output_format="$2"
    local priority="${3:-normal}"
    local hw_accel="${4:-auto}"
    
    local job_id="$(date +%s%N | cut -b1-13)"
    local job_file="$QUEUE_DIR/${priority}_${job_id}.job"
    
    cat > "$job_file" << EOF
{
    "id": "$job_id",
    "input": "$input_file",
    "output_format": "$output_format",
    "priority": "$priority",
    "hw_accel": "$hw_accel",
    "created": "$(date -Iseconds)",
    "status": "queued"
}
EOF
    
    log "Added job $job_id: $(basename "$input_file") -> $output_format (priority: $priority)"
    echo "$job_id"
}

get_next_job() {
    # Get highest priority job (high > normal > low)
    for priority in high normal low; do
        local job_file=$(find "$QUEUE_DIR" -name "${priority}_*.job" -type f | head -n1)
        if [ -n "$job_file" ]; then
            echo "$job_file"
            return 0
        fi
    done
    return 1
}

process_job() {
    local job_file="$1"
    local job_id=$(basename "$job_file" .job | cut -d_ -f2-)
    
    # Move to processing
    local processing_file="$PROCESSING_DIR/$(basename "$job_file")"
    mv "$job_file" "$processing_file"
    
    # Parse job details
    local input_file=$(grep '"input"' "$processing_file" | cut -d'"' -f4)
    local output_format=$(grep '"output_format"' "$processing_file" | cut -d'"' -f4)
    local hw_accel=$(grep '"hw_accel"' "$processing_file" | cut -d'"' -f4)
    
    log "Processing job $job_id: $(basename "$input_file")"
    
    # Execute conversion based on format
    local exit_code=0
    case "$output_format" in
        "av1")
            encode_av1_job "$input_file" "$job_id" || exit_code=$?
            ;;
        "hevc"|"h265")
            encode_hevc_job "$input_file" "$job_id" "$hw_accel" || exit_code=$?
            ;;
        "h264")
            encode_h264_job "$input_file" "$job_id" "$hw_accel" || exit_code=$?
            ;;
        "vp9")
            encode_vp9_job "$input_file" "$job_id" || exit_code=$?
            ;;
        "opus")
            encode_opus_job "$input_file" "$job_id" || exit_code=$?
            ;;
        "flac")
            encode_flac_job "$input_file" "$job_id" || exit_code=$?
            ;;
        *)
            log "Unknown format: $output_format"
            exit_code=1
            ;;
    esac
    
    # Move job file based on result
    if [ $exit_code -eq 0 ]; then
        mv "$processing_file" "$COMPLETED_DIR/"
        log "Job $job_id completed successfully"
    else
        mv "$processing_file" "$ERROR_DIR/"
        log "Job $job_id failed with exit code $exit_code"
    fi
    
    return $exit_code
}

# Format-specific encoding functions
encode_av1_job() {
    local input="$1"
    local job_id="$2"
    local output_dir="/media/converted/av1"
    local filename=$(basename "$input")
    local basename_no_ext="${filename%.*}"
    local output="$output_dir/${basename_no_ext}_av1.mkv"
    
    mkdir -p "$output_dir"
    
    ffmpeg -i "$input" \
        -c:v libaom-av1 \
        -crf 30 \
        -cpu-used 6 \
        -row-mt 1 \
        -tiles 2x2 \
        -c:a libopus \
        -b:a 128k \
        -ac 2 \
        "$output" 2>&1 | tee -a "$LOG_FILE"
}

encode_hevc_job() {
    local input="$1"
    local job_id="$2"
    local hw_accel="$3"
    local output_dir="/media/converted/hevc"
    local filename=$(basename "$input")
    local basename_no_ext="${filename%.*}"
    local output="$output_dir/${basename_no_ext}_hevc.mp4"
    
    mkdir -p "$output_dir"
    
    if [ "$hw_accel" = "nvenc" ] && nvidia-smi >/dev/null 2>&1; then
        ffmpeg -hwaccel cuda -i "$input" \
            -c:v hevc_nvenc \
            -preset fast \
            -crf 23 \
            -c:a aac \
            -b:a 128k \
            "$output" 2>&1 | tee -a "$LOG_FILE"
    else
        ffmpeg -i "$input" \
            -c:v libx265 \
            -preset medium \
            -crf 23 \
            -c:a aac \
            -b:a 128k \
            "$output" 2>&1 | tee -a "$LOG_FILE"
    fi
}

encode_h264_job() {
    local input="$1"
    local job_id="$2"
    local hw_accel="$3"
    local output_dir="/media/converted/h264"
    local filename=$(basename "$input")
    local basename_no_ext="${filename%.*}"
    local output="$output_dir/${basename_no_ext}_h264.mp4"
    
    mkdir -p "$output_dir"
    
    if [ "$hw_accel" = "nvenc" ] && nvidia-smi >/dev/null 2>&1; then
        ffmpeg -hwaccel cuda -i "$input" \
            -c:v h264_nvenc \
            -preset fast \
            -crf 23 \
            -c:a aac \
            -b:a 128k \
            "$output" 2>&1 | tee -a "$LOG_FILE"
    else
        ffmpeg -i "$input" \
            -c:v libx264 \
            -preset medium \
            -crf 23 \
            -c:a aac \
            -b:a 128k \
            "$output" 2>&1 | tee -a "$LOG_FILE"
    fi
}

encode_vp9_job() {
    local input="$1"
    local job_id="$2"
    local output_dir="/media/converted/vp9"
    local filename=$(basename "$input")
    local basename_no_ext="${filename%.*}"
    local output="$output_dir/${basename_no_ext}_vp9.webm"
    
    mkdir -p "$output_dir"
    
    ffmpeg -i "$input" \
        -c:v libvpx-vp9 \
        -crf 30 \
        -b:v 0 \
        -row-mt 1 \
        -tile-columns 2 \
        -c:a libopus \
        -b:a 128k \
        "$output" 2>&1 | tee -a "$LOG_FILE"
}

encode_opus_job() {
    local input="$1"
    local job_id="$2"
    local output_dir="/media/converted/opus"
    local filename=$(basename "$input")
    local basename_no_ext="${filename%.*}"
    local output="$output_dir/${basename_no_ext}.opus"
    
    mkdir -p "$output_dir"
    
    ffmpeg -i "$input" \
        -c:a libopus \
        -b:a 128k \
        -vbr on \
        -compression_level 10 \
        "$output" 2>&1 | tee -a "$LOG_FILE"
}

encode_flac_job() {
    local input="$1"
    local job_id="$2"
    local output_dir="/media/converted/flac"
    local filename=$(basename "$input")
    local basename_no_ext="${filename%.*}"
    local output="$output_dir/${basename_no_ext}.flac"
    
    mkdir -p "$output_dir"
    
    ffmpeg -i "$input" \
        -c:a flac \
        -compression_level 8 \
        "$output" 2>&1 | tee -a "$LOG_FILE"
}

# Queue management commands
queue_status() {
    local queued=$(find "$QUEUE_DIR" -name "*.job" | wc -l)
    local processing=$(find "$PROCESSING_DIR" -name "*.job" | wc -l)
    local completed=$(find "$COMPLETED_DIR" -name "*.job" | wc -l)
    local errors=$(find "$ERROR_DIR" -name "*.job" | wc -l)
    
    echo "Queue Status:"
    echo "  Queued: $queued"
    echo "  Processing: $processing"
    echo "  Completed: $completed"
    echo "  Errors: $errors"
}

clear_completed() {
    rm -f "$COMPLETED_DIR"/*.job
    log "Cleared completed jobs"
}

clear_errors() {
    rm -f "$ERROR_DIR"/*.job
    log "Cleared error jobs"
}

# Worker process
start_worker() {
    log "Starting batch conversion worker (max $MAX_CONCURRENT_JOBS concurrent jobs)"
    
    while true; do
        local active_jobs=$(find "$PROCESSING_DIR" -name "*.job" | wc -l)
        
        if [ "$active_jobs" -lt "$MAX_CONCURRENT_JOBS" ]; then
            if job_file=$(get_next_job); then
                process_job "$job_file" &
            else
                sleep 5  # No jobs available, wait
            fi
        else
            sleep 2  # Max jobs running, wait for completion
        fi
        
        # Clean up completed background jobs
        wait -n 2>/dev/null || true
    done
}

# Command line interface
case "${1:-}" in
    "add")
        if [ $# -lt 3 ]; then
            echo "Usage: $0 add <input_file> <format> [priority] [hw_accel]"
            echo "Formats: av1, hevc, h264, vp9, opus, flac"
            echo "Priority: high, normal, low (default: normal)"
            echo "HW Accel: auto, nvenc, vaapi, none (default: auto)"
            exit 1
        fi
        add_job "$2" "$3" "${4:-normal}" "${5:-auto}"
        ;;
    "worker")
        start_worker
        ;;
    "status")
        queue_status
        ;;
    "clear-completed")
        clear_completed
        ;;
    "clear-errors")
        clear_errors
        ;;
    *)
        echo "Usage: $0 {add|worker|status|clear-completed|clear-errors}"
        echo ""
        echo "Commands:"
        echo "  add <file> <format> [priority] [hw_accel] - Add conversion job"
        echo "  worker                                    - Start worker process"
        echo "  status                                    - Show queue status"
        echo "  clear-completed                           - Clear completed jobs"
        echo "  clear-errors                              - Clear error jobs"
        exit 1
        ;;
esac