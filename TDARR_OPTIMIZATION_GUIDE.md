# Tdarr Media Optimization Guide

This guide covers the complete setup and configuration of Tdarr for intelligent media file size reduction while maintaining high quality.

## Overview

Tdarr automatically processes your media libraries to:
- **Reduce file sizes by 40-60%** using modern codecs
- **Maintain visual quality** through intelligent encoding
- **Modernize legacy formats** and containers
- **Optimize for streaming** and device compatibility

## Architecture

### Components
- **Tdarr Server**: Web interface and job management
- **Tdarr Node 1**: GPU-accelerated transcoding
- **Tdarr Node 2**: CPU-only processing (optional)

### Processing Flow
```
Media Library → Tdarr Scanner → Quality Analysis → Encoding Queue → GPU/CPU Nodes → Quality Validation → Optimized Files
```

## Quick Start

### 1. Enable GPU Hardware Acceleration (Recommended)

#### For NVIDIA GPUs:
```bash
# Edit docker-compose.yml - uncomment NVIDIA device lines:
devices:
  - /dev/nvidia0:/dev/nvidia0
  - /dev/nvidiactl:/dev/nvidiactl
  - /dev/nvidia-modeset:/dev/nvidia-modeset
  - /dev/nvidia-uvm:/dev/nvidia-uvm
  - /dev/nvidia-uvm-tools:/dev/nvidia-uvm-tools

group_add:
  - "109"  # video group
```

#### For Intel GPUs:
```bash
# Edit docker-compose.yml - uncomment Intel device lines:
devices:
  - /dev/dri:/dev/dri

group_add:
  - "109"  # video group
```

### 2. Configure Worker Allocation

Edit `.env` file:
```bash
# Adjust based on your hardware
TDARR_CPU_WORKERS=2          # Number of CPU transcoding workers
TDARR_GPU_WORKERS=1          # Number of GPU transcoding workers
TDARR_CPU_WORKERS_2=1        # CPU workers for second node
```

### 3. Start Multi-Node Setup (Optional)

For distributed processing across multiple nodes:
```bash
# Start with multi-node profile
docker-compose --profile multi-node up -d
```

### 4. Access Tdarr Web Interface

Visit: `https://tdarr.yourdomain.com`

## Library Configuration

### Initial Setup

1. **Add Libraries**: Point to your media directories
   - Movies: `/media/movies`
   - TV Shows: `/media/tv`
   - 4K Content: `/media/4k`
   - Anime: `/media/anime`

2. **Configure Transcode Settings**:
   - Enable "Transcode cache"
   - Set temp directory: `/temp`
   - Enable hardware acceleration

### Quality Presets

#### Archive Quality (25% reduction)
- **Use Case**: Master copies, irreplaceable content
- **Settings**: CRF 16, Very Slow preset
- **Expected Quality**: Visually lossless

#### Premium Quality (35% reduction)
- **Use Case**: 4K content, high-value media
- **Settings**: CRF 18, Slow preset
- **Expected Quality**: Excellent, imperceptible loss

#### Standard Quality (50% reduction)
- **Use Case**: General collection, 1080p content
- **Settings**: CRF 23, Medium preset
- **Expected Quality**: High, very minor loss

#### Efficient Quality (60% reduction)
- **Use Case**: Storage-constrained, frequent viewing
- **Settings**: CRF 26, Fast preset
- **Expected Quality**: Good, acceptable for most uses

## Optimization Strategies

### Content-Specific Settings

#### 4K/UHD Content
```javascript
{
  "resolution": ">=3840x2160",
  "codec": "hevc",
  "crf": 18,
  "preset": "slow",
  "profile": "main10",
  "preserve_hdr": true,
  "target_reduction": 35
}
```

#### 1080p Movies
```javascript
{
  "resolution": "1920x1080",
  "codec": "hevc",
  "crf": 20,
  "preset": "medium",
  "target_reduction": 50
}
```

#### TV Shows/Series
```javascript
{
  "codec": "hevc",
  "crf": 23,
  "preset": "fast",
  "container": "mp4",
  "target_reduction": 45
}
```

#### Anime Content
```javascript
{
  "codec": "hevc",
  "crf": 20,
  "preset": "slow",
  "tune": "animation",
  "target_reduction": 55
}
```

### Legacy Format Modernization

#### Priority Processing
1. **MPEG-2** (DVD rips) → H.264/HEVC
2. **DivX/Xvid** → HEVC
3. **WMV/ASF** → MP4/HEVC
4. **AVI containers** → MP4

#### Container Optimization
- **Source**: AVI, WMV, FLV → **Target**: MP4
- **Preserve**: MKV (if multi-track)
- **Streaming**: Prefer MP4 for compatibility

## Quality Control

### Automated Validation

#### Size Checks
- **Skip if smaller**: Don't process if output would be larger
- **Size increase limit**: Maximum 10% increase allowed
- **Minimum size**: Skip files under 100MB

#### Quality Metrics
- **SSIM threshold**: 0.95 minimum
- **PSNR monitoring**: Track quality metrics
- **Visual validation**: Sample frame comparison

### Manual Quality Testing

Before processing your entire library:

1. **Test small batch**: Process 5-10 files first
2. **Compare quality**: Check before/after samples
3. **Adjust settings**: Fine-tune CRF values
4. **Monitor results**: Watch file size reductions

## Performance Optimization

### Hardware Utilization

#### GPU Acceleration Benefits
- **NVENC (NVIDIA)**: 10-20x faster than CPU
- **QSV (Intel)**: 8-15x faster than CPU
- **Quality**: Near-identical to software encoding

#### CPU Optimization
- **Multi-threading**: Use all available cores
- **Priority setting**: Lower priority for background processing
- **Temp storage**: Use SSD for transcoding temp files

### Storage Considerations

#### Temp Directory
- **Location**: Fast SSD recommended
- **Size**: 2-3x largest file size
- **Cleanup**: Automatic cleanup after processing

#### Output Strategy
- **In-place**: Replace original files
- **Separate folder**: Keep originals as backup
- **Hybrid**: Replace after validation

## Monitoring and Maintenance

### Performance Metrics

#### Processing Statistics
- **Files processed**: Track daily/weekly progress
- **Size reduction**: Monitor average savings
- **Quality scores**: Ensure standards maintained
- **Processing time**: Optimize based on hardware

#### Queue Management
- **Priority queues**: Process large files first
- **Scheduled processing**: Run during off-hours
- **Resource allocation**: Balance GPU/CPU usage

### Troubleshooting

#### Common Issues

**Encoding Failures**
- Check hardware acceleration settings
- Verify device permissions
- Review FFmpeg logs

**Poor Quality Output**
- Increase CRF value (lower number = higher quality)
- Use slower presets
- Enable two-pass encoding

**Slow Processing**
- Enable GPU acceleration
- Increase worker allocation
- Use faster temp storage

**Large Output Files**
- Adjust target bitrate
- Check skip conditions
- Review quality settings

## Advanced Configuration

### Custom Plugins

Located in: `config/tdarr/custom-plugins.js`

#### Smart HEVC Encoder
- **Intelligent quality detection**
- **Hardware acceleration optimization**
- **HDR preservation**

#### Size Reducer
- **Content-aware compression**
- **Quality threshold protection**
- **Two-pass optimization**

#### Quality Validator
- **SSIM comparison**
- **Size increase protection**
- **Automatic reversion**

### Flow Configuration

Edit: `config/tdarr/quality-optimized-flows.json`

#### Processing Rules
1. **Quality-First Optimization**: HEVC encoding with quality protection
2. **4K Content Processing**: Special handling for UHD content
3. **Legacy Modernization**: Update old formats
4. **Audio Optimization**: Compress oversized audio tracks
5. **Subtitle Processing**: Extract and optimize subtitle tracks

### Library Settings

Configure per-library in: `config/tdarr/library-settings.json`

#### Scan Intervals
- **Movies**: Every 1 hour
- **TV Shows**: Every 30 minutes  
- **4K Content**: Every 2 hours
- **Music Videos**: Every 2 hours

#### Processing Priorities
1. **Large files** (>5GB): High priority
2. **Legacy codecs**: Medium priority
3. **Recent files**: Lower priority

## Expected Results

### Typical Size Reductions

| Content Type | Original Codec | Target Codec | Size Reduction | Quality Loss |
|--------------|----------------|--------------|----------------|--------------|
| 4K Movies | H.264 | HEVC | 35-45% | Imperceptible |
| 1080p Movies | H.264 | HEVC | 45-55% | Very Minor |
| TV Shows | H.264 | HEVC | 40-50% | Minor |
| Anime | H.264 | HEVC | 50-60% | Imperceptible |
| Legacy (DivX) | MPEG-4 | HEVC | 60-70% | Improved |

### Processing Times

With GPU acceleration:
- **1080p file (2GB)**: 5-15 minutes
- **4K file (8GB)**: 15-45 minutes
- **Legacy SD file (700MB)**: 2-8 minutes

### Storage Savings

For a typical 10TB library:
- **Expected reduction**: 4-6TB savings
- **Processing time**: 2-4 weeks (continuous)
- **Quality maintained**: 95%+ visual fidelity

## Best Practices

### Setup Recommendations
1. **Start small**: Test with non-critical content first
2. **Monitor closely**: Watch first 24 hours of processing
3. **Backup strategy**: Keep originals until satisfied
4. **Quality validation**: Spot-check random samples

### Ongoing Management
1. **Regular monitoring**: Check processing statistics
2. **Queue management**: Prioritize important content
3. **Setting adjustment**: Fine-tune based on results
4. **Hardware optimization**: Upgrade for better performance

This comprehensive setup will automatically optimize your media library, significantly reducing storage requirements while maintaining excellent quality across all your content.
## Recommended Add-on Apps

- **Photoprism:** Self-hosted photo management and backup.
- **Audiobookshelf:** Organize and stream audiobooks.
- **Calibre Web:** Manage and read eBooks in your browser.
- **Podgrab:** Automatically download podcast episodes.
- **YTDL-Material:** Save online videos directly to your library.
