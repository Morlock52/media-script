#!/bin/bash

# Comprehensive Media Format Conversion Script
# Supports all modern codecs and formats including AV1, HEVC, VP9, etc.

set -e

# Configuration
INPUT_DIR="/downloads"
OUTPUT_DIR="/media/converted"
LOG_FILE="/config/ffmpeg_conversion.log"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to detect video codec
detect_codec() {
    local file="$1"
    ffprobe -v quiet -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$file" 2>/dev/null || echo "unknown"
}

# Function to detect audio codec
detect_audio_codec() {
    local file="$1"
    ffprobe -v quiet -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$file" 2>/dev/null || echo "unknown"
}

# Function to get video resolution
get_resolution() {
    local file="$1"
    ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$file" 2>/dev/null | tr ',' 'x' || echo "unknown"
}

# AV1 encoding function (modern, efficient)
encode_av1() {
    local input="$1"
    local output="$2"
    local preset="${3:-6}"  # 0-8, higher = slower but better compression
    
    log "Converting to AV1: $(basename "$input")"
    
    ffmpeg -i "$input" \
        -c:v libaom-av1 \
        -crf 30 \
        -cpu-used "$preset" \
        -row-mt 1 \
        -tiles 2x2 \
        -c:a libopus \
        -b:a 128k \
        -ac 2 \
        -movflags +faststart \
        "$output" 2>&1 | tee -a "$LOG_FILE"
}

# HEVC/H.265 encoding function
encode_hevc() {
    local input="$1"
    local output="$2"
    local preset="${3:-medium}"
    
    log "Converting to HEVC: $(basename "$input")"
    
    ffmpeg -i "$input" \
        -c:v libx265 \
        -preset "$preset" \
        -crf 23 \
        -c:a aac \
        -b:a 128k \
        -ac 2 \
        -movflags +faststart \
        "$output" 2>&1 | tee -a "$LOG_FILE"
}

# VP9 encoding function
encode_vp9() {
    local input="$1"
    local output="$2"
    
    log "Converting to VP9: $(basename "$input")"
    
    ffmpeg -i "$input" \
        -c:v libvpx-vp9 \
        -crf 30 \
        -b:v 0 \
        -row-mt 1 \
        -tile-columns 2 \
        -c:a libopus \
        -b:a 128k \
        -ac 2 \
        "$output" 2>&1 | tee -a "$LOG_FILE"
}

# H.264 encoding function (compatibility)
encode_h264() {
    local input="$1"
    local output="$2"
    local preset="${3:-medium}"
    
    log "Converting to H.264: $(basename "$input")"
    
    ffmpeg -i "$input" \
        -c:v libx264 \
        -preset "$preset" \
        -crf 23 \
        -c:a aac \
        -b:a 128k \
        -ac 2 \
        -movflags +faststart \
        "$output" 2>&1 | tee -a "$LOG_FILE"
}

# Audio conversion functions
convert_audio_flac() {
    local input="$1"
    local output="$2"
    
    log "Converting audio to FLAC: $(basename "$input")"
    
    ffmpeg -i "$input" \
        -c:a flac \
        -compression_level 8 \
        "$output" 2>&1 | tee -a "$LOG_FILE"
}

convert_audio_opus() {
    local input="$1"
    local output="$2"
    local bitrate="${3:-128k}"
    
    log "Converting audio to Opus: $(basename "$input")"
    
    ffmpeg -i "$input" \
        -c:a libopus \
        -b:a "$bitrate" \
        -vbr on \
        -compression_level 10 \
        "$output" 2>&1 | tee -a "$LOG_FILE"
}

# Subtitle extraction and conversion
extract_subtitles() {
    local input="$1"
    local output_base="$2"
    
    log "Extracting subtitles from: $(basename "$input")"
    
    # Extract all subtitle streams
    ffprobe -v quiet -select_streams s -show_entries stream=index:stream_tags=language -of csv=p=0 "$input" | while IFS=',' read -r index language; do
        if [ -n "$index" ]; then
            sub_file="${output_base}.${language:-unknown}.${index}.srt"
            ffmpeg -i "$input" -map 0:s:$((index)) -c:s srt "$sub_file" 2>/dev/null || true
        fi
    done
}

# Hardware acceleration detection
detect_hw_accel() {
    # Check for NVIDIA GPU
    if nvidia-smi >/dev/null 2>&1; then
        echo "nvenc"
    # Check for Intel GPU
    elif [ -d /dev/dri ]; then
        echo "vaapi"
    # Check for AMD GPU
    elif lspci | grep -i amd | grep -i vga >/dev/null; then
        echo "amf"
    else
        echo "none"
    fi
}

# Hardware-accelerated encoding
encode_hw_h264() {
    local input="$1"
    local output="$2"
    local hw_accel="$3"
    
    case "$hw_accel" in
        "nvenc")
            ffmpeg -hwaccel cuda -i "$input" -c:v h264_nvenc -preset fast -crf 23 -c:a aac -b:a 128k "$output"
            ;;
        "vaapi")
            ffmpeg -hwaccel vaapi -hwaccel_device /dev/dri/renderD128 -i "$input" -c:v h264_vaapi -qp 23 -c:a aac -b:a 128k "$output"
            ;;
        "amf")
            ffmpeg -hwaccel d3d11va -i "$input" -c:v h264_amf -quality speed -qp_i 23 -qp_p 23 -c:a aac -b:a 128k "$output"
            ;;
        *)
            encode_h264 "$input" "$output"
            ;;
    esac
}

# Main processing function
process_file() {
    local input_file="$1"
    local filename=$(basename "$input_file")
    local extension="${filename##*.}"
    local basename_no_ext="${filename%.*}"
    
    log "Processing: $filename"
    
    # Get file info
    local video_codec=$(detect_codec "$input_file")
    local audio_codec=$(detect_audio_codec "$input_file")
    local resolution=$(get_resolution "$input_file")
    local hw_accel=$(detect_hw_accel)
    
    log "File info - Video: $video_codec, Audio: $audio_codec, Resolution: $resolution, HW Accel: $hw_accel"
    
    # Create output subdirectory based on content type
    local output_subdir=""
    case "$extension" in
        mp4|mkv|avi|mov|wmv|flv|webm|m4v)
            output_subdir="video"
            ;;
        mp3|flac|aac|ogg|opus|m4a|wav)
            output_subdir="audio"
            ;;
        *)
            output_subdir="other"
            ;;
    esac
    
    mkdir -p "$OUTPUT_DIR/$output_subdir"
    
    # Process based on file type and codec
    if [[ "$extension" =~ ^(mp4|mkv|avi|mov|wmv|flv|webm|m4v)$ ]]; then
        # Video processing
        local output_file="$OUTPUT_DIR/$output_subdir/${basename_no_ext}"
        
        # Extract subtitles first
        extract_subtitles "$input_file" "$output_file"
        
        # Convert video based on current codec and desired output
        case "$video_codec" in
            "h264"|"avc")
                if [ "$resolution" != "unknown" ] && [[ "$resolution" =~ 4K|2160 ]]; then
                    # 4K content - use HEVC for better compression
                    encode_hevc "$input_file" "${output_file}_hevc.mp4"
                fi
                ;;
            "hevc"|"h265")
                # Already HEVC, check if we need AV1 for even better compression
                encode_av1 "$input_file" "${output_file}_av1.mkv" 6
                ;;
            "vp8"|"vp9")
                # Convert VP8/9 to more compatible format
                encode_h264 "$input_file" "${output_file}_h264.mp4"
                ;;
            "av1")
                # Already AV1, create H.264 version for compatibility
                encode_h264 "$input_file" "${output_file}_h264.mp4"
                ;;
            *)
                # Unknown or legacy codec, convert to H.264
                if [ "$hw_accel" != "none" ]; then
                    encode_hw_h264 "$input_file" "${output_file}_h264.mp4" "$hw_accel"
                else
                    encode_h264 "$input_file" "${output_file}_h264.mp4"
                fi
                ;;
        esac
        
    elif [[ "$extension" =~ ^(mp3|flac|aac|ogg|opus|m4a|wav)$ ]]; then
        # Audio processing
        local output_file="$OUTPUT_DIR/$output_subdir/${basename_no_ext}"
        
        case "$audio_codec" in
            "mp3")
                # Convert to FLAC for lossless and Opus for streaming
                convert_audio_flac "$input_file" "${output_file}.flac"
                convert_audio_opus "$input_file" "${output_file}.opus" "128k"
                ;;
            "flac")
                # Create Opus version for streaming
                convert_audio_opus "$input_file" "${output_file}.opus" "192k"
                ;;
            "aac")
                # Convert to FLAC for archival
                convert_audio_flac "$input_file" "${output_file}.flac"
                ;;
            *)
                # Convert to both FLAC and Opus
                convert_audio_flac "$input_file" "${output_file}.flac"
                convert_audio_opus "$input_file" "${output_file}.opus" "128k"
                ;;
        esac
    fi
    
    log "Completed processing: $filename"
}

# Main script execution
main() {
    log "Starting format conversion process"
    log "Hardware acceleration: $(detect_hw_accel)"
    
    # Find all media files in input directory
    find "$INPUT_DIR" -type f \( \
        -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.mov" -o \
        -iname "*.wmv" -o -iname "*.flv" -o -iname "*.webm" -o -iname "*.m4v" -o \
        -iname "*.mp3" -o -iname "*.flac" -o -iname "*.aac" -o -iname "*.ogg" -o \
        -iname "*.opus" -o -iname "*.m4a" -o -iname "*.wav" \
    \) | while read -r file; do
        process_file "$file"
    done
    
    log "Format conversion process completed"
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi