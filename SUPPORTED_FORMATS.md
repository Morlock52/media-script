# Comprehensive Media Format Support Guide
_Last updated: July 2025_

This media stack supports virtually all modern and legacy media formats through Jellyfin's enhanced FFmpeg integration and additional processing tools.

## Video Formats & Codecs

### Modern Codecs (2025)
-
-#### Versatile Video Coding (VVC/H.266)
-
- - **Benefits**: Next-generation codec with high compression efficiency (~50% better than HEVC)
- - **Use Case**: Experimental, emerging hardware support
-
-#### Low Complexity Enhancement Video Coding (LCEVC)
-
- - **Benefits**: Enhancement layer for improved compression on existing codecs
- - **Use Case**: Streaming augmentation
-
-#### Essential Video Coding (EVC/MPEG-5)
-
- - **Profiles**: Baseline, Main
- - **Benefits**: Broad compatibility and optimized licensing profiles
- - **Use Case**: Future codec for distribution
-
#### AV1 (AOMedia Video 1)
- **Encoder**: libaom-av1
- **Hardware Support**: RTX 40xx series (NVENC), Intel Arc/13th gen+ (QSV)
- **Benefits**: ~30% better compression than HEVC
- **Use Case**: Streaming, long-term archival
- **Direct Play**: Limited client support (Chrome, Edge, Firefox)

#### HEVC/H.265
- **Profiles**: Main, Main10 (10-bit), Main12 (12-bit)
- **Hardware Support**: Most modern GPUs (NVENC, QSV, AMF)
- **Benefits**: ~50% better compression than H.264
- **Use Case**: 4K content, bandwidth-limited streaming
- **Direct Play**: Most modern devices

#### VP9
- **Encoder**: libvpx-vp9
- **Container**: WebM
- **Benefits**: Open-source, good compression
- **Use Case**: Web streaming, YouTube compatibility
- **Direct Play**: Chrome, Firefox, modern browsers

#### H.264/AVC
- **Profiles**: Baseline, Main, High
- **Hardware Support**: Universal
- **Benefits**: Maximum compatibility
- **Use Case**: Legacy devices, universal playback
- **Direct Play**: All devices

### Legacy Video Codecs
- **MPEG-4 Part 2** (DivX, Xvid)
- **MPEG-2** (DVD Video)
- **MPEG-1** (VCD)
- **VP8** (WebM legacy)
- **WMV** (Windows Media Video)
- **Real Video** (RealMedia)

## Audio Formats & Codecs

### Modern Audio Codecs

#### Opus
- **Bitrates**: 6 kbps - 510 kbps
- **Benefits**: Best quality-to-bitrate ratio
- **Use Case**: Streaming, VoIP, modern applications
- **Container**: WebM, Ogg, MP4

#### FLAC (Free Lossless Audio Codec)
- **Compression**: ~50% of original size
- **Benefits**: Lossless compression, metadata support
- **Use Case**: Archival, audiophile collections
- **Container**: FLAC, MKV, MP4

#### AAC (Advanced Audio Coding)
- **Profiles**: LC, HE-AAC, HE-AACv2
- **Benefits**: Good compression, wide support
- **Use Case**: General streaming, mobile devices
- **Container**: MP4, M4A, TS

### High-Quality Audio Formats

#### Dolby Formats
- **Dolby Digital (AC3)**: 5.1 surround, DVD standard
- **Dolby Digital Plus (E-AC3)**: Enhanced compression
- **Dolby TrueHD**: Lossless, Blu-ray standard
- **Dolby Atmos**: Object-based 3D audio

#### DTS Formats
- **DTS**: 5.1 surround sound
- **DTS-HD High Resolution**: Enhanced bitrate
- **DTS-HD Master Audio**: Lossless compression
- **DTS:X**: Object-based 3D audio

#### PCM (Uncompressed)
- **Bit Depths**: 16-bit, 24-bit, 32-bit
- **Sample Rates**: 44.1 kHz, 48 kHz, 96 kHz, 192 kHz
- **Use Case**: Studio masters, maximum quality

### Legacy Audio Codecs
- **MP3**: Universal compatibility
- **Vorbis**: Open-source compression
- **WMA**: Windows Media Audio
- **Real Audio**: RealMedia format
- **ADPCM**: Compressed PCM variants

## Container Formats

### Modern Containers

#### MP4/M4V
- **Codecs**: H.264, HEVC, AV1, AAC, AC3
- **Benefits**: Universal compatibility, streaming-optimized
- **Use Case**: Web streaming, mobile devices
- **Features**: Chapter marks, metadata, subtitles

#### MKV (Matroska)
- **Codecs**: Any video/audio codec
- **Benefits**: Feature-rich, open standard
- **Use Case**: High-quality content, multiple tracks
- **Features**: Multiple audio/subtitle tracks, chapters, attachments

#### WebM
- **Codecs**: VP8/VP9, Vorbis/Opus
- **Benefits**: Web-optimized, open standard
- **Use Case**: Web streaming, browser compatibility
- **Features**: Adaptive streaming support

### Legacy Containers
- **AVI**: Audio Video Interleave
- **MOV**: QuickTime format
- **WMV**: Windows Media Video
- **FLV**: Flash Video
- **3GP**: Mobile video format
- **OGV**: Ogg Video format

## Subtitle Formats

### Text-Based Subtitles
- **SRT (SubRip)**: Simple timing and text
- **ASS/SSA**: Advanced styling and effects
- **WebVTT**: Web subtitle standard
- **TTML**: Timed Text Markup Language
- **SBV**: YouTube subtitle format

### Image-Based Subtitles
- **VobSub (SUB/IDX)**: DVD subtitle format
- **PGS/SUP**: Blu-ray subtitle format
- **DVB**: Digital TV subtitles

## Hardware Acceleration Support

### NVIDIA GPUs (NVENC/NVDEC)

#### Supported Codecs
- **Encoding**: H.264, HEVC, AV1 (RTX 40xx)
- **Decoding**: H.264, HEVC, VP8, VP9, AV1
- **Generations**: Maxwell 2.0+ (GTX 900 series+)

#### Performance Benefits
- **H.264**: ~20x faster than CPU
- **HEVC**: ~15x faster than CPU
- **AV1**: ~10x faster than CPU (RTX 40xx)

### Intel GPUs (QSV/VA-API)

#### Supported Codecs
- **Encoding**: H.264, HEVC, AV1 (12th gen+)
- **Decoding**: H.264, HEVC, VP9, AV1
- **Generations**: 4th gen Core+ (Haswell+)

#### Arc GPU Features
- **AV1 Encoding**: Hardware-accelerated
- **HEVC 10-bit**: Full support
- **Multiple Streams**: Concurrent encoding

### AMD GPUs (AMF/VA-API)

#### Supported Codecs
- **Encoding**: H.264, HEVC
- **Decoding**: H.264, HEVC, VP9
- **Generations**: GCN 2.0+ (R9 series+)

## Format Conversion Strategies

### Quality Tiers

#### Archive Quality (Lossless/Near-Lossless)
- **Video**: HEVC 10-bit CRF 18-20
- **Audio**: FLAC or TrueHD/DTS-HD MA
- **Use Case**: Long-term storage, master copies

#### High Quality (Transparent)
- **Video**: HEVC CRF 20-23 or AV1 CRF 25-28
- **Audio**: AAC 256 kbps or Opus 192 kbps
- **Use Case**: Premium streaming, large screens

#### Standard Quality (Efficient)
- **Video**: H.264 CRF 23-26 or HEVC CRF 26-28
- **Audio**: AAC 128-192 kbps or Opus 128 kbps
- **Use Case**: General streaming, mobile devices

#### Low Bandwidth (Compressed)
- **Video**: H.264 CRF 28-32 or AV1 CRF 32-35
- **Audio**: Opus 64-96 kbps
- **Use Case**: Slow connections, data-limited scenarios

### Conversion Workflows

#### 4K/UHD Content
1. **Source**: Blu-ray rip (H.264/HEVC)
2. **Target**: HEVC 10-bit or AV1
3. **Audio**: Keep lossless (TrueHD/DTS-HD)
4. **Subtitles**: Extract all tracks

#### Standard Definition Legacy
1. **Source**: DVD rip (MPEG-2)
2. **Target**: H.264 for compatibility
3. **Audio**: AC3 → AAC conversion
4. **Upscaling**: Optional AI enhancement

#### Web Content
1. **Source**: Various formats
2. **Target**: H.264 + WebM/VP9 variants
3. **Audio**: AAC + Opus variants
4. **Streaming**: Multiple bitrate ladders

## Compatibility Matrix

### Client Device Support

#### Smart TVs
- **Samsung**: H.264, HEVC (2016+), DTS
- **LG**: H.264, HEVC (2017+), Dolby Vision
- **Sony**: H.264, HEVC, Dolby Atmos
- **Limited**: AV1, VP9

#### Mobile Devices
- **iOS**: H.264, HEVC, AAC, Dolby Atmos
- **Android**: H.264, HEVC (Android 5+), VP9, Opus
- **Emerging**: AV1 support (Android 10+)

#### Game Consoles
- **PlayStation**: H.264, HEVC (PS5), DTS
- **Xbox**: H.264, HEVC, Dolby Atmos, DTS:X
- **Nintendo Switch**: H.264 only

#### Web Browsers
- **Chrome**: H.264, VP8/VP9, AV1, Opus
- **Firefox**: H.264, VP8/VP9, AV1, Opus
- **Safari**: H.264, HEVC (macOS/iOS), AAC
- **Edge**: H.264, HEVC, AV1, AAC, Opus

## Troubleshooting Format Issues

### Common Problems

#### No Audio
- **Cause**: Unsupported audio codec
- **Solution**: Transcode to AAC or AC3
- **Prevention**: Use compatible audio formats

#### Stuttering Video
- **Cause**: Insufficient bandwidth or CPU
- **Solution**: Lower bitrate or enable HW acceleration
- **Prevention**: Optimize encoding settings

#### Subtitle Issues
- **Cause**: Incompatible subtitle format
- **Solution**: Convert to SRT or burn-in subtitles
- **Prevention**: Use widely supported formats

#### Direct Play Failures
- **Cause**: Container or codec incompatibility
- **Solution**: Remux to compatible container
- **Prevention**: Check client capabilities

### Performance Optimization

#### Server-Side
- **Hardware Acceleration**: Enable GPU transcoding
- **Transcoding RAM**: Allocate sufficient memory
- **Storage**: Use SSD for transcoding temp files
- **Network**: Ensure adequate bandwidth

#### Client-Side
- **App Updates**: Keep Jellyfin clients updated
- **Codec Support**: Install codec packs if needed
- **Network**: Use wired connections for 4K
- **Settings**: Optimize client playback settings

This comprehensive format support ensures your media stack can handle any content you throw at it, from legacy formats to cutting-edge codecs, with optimal performance and compatibility across all your devices.
## Recommended Add-on Apps

- **Photoprism:** Self-hosted photo management and backup.
- **Audiobookshelf:** Organize and stream audiobooks.
- **Calibre Web:** Manage and read eBooks in your browser.
- **Podgrab:** Automatically download podcast episodes.
- **YTDL-Material:** Save online videos directly to your library.
