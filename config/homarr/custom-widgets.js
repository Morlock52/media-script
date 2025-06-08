// Custom Homarr Widgets for Media Stack Dashboard
// Enhanced widgets with media-specific functionality

// Media Library Statistics Widget
const mediaLibraryStats = {
  id: 'media-library-stats',
  name: 'Media Library Statistics',
  description: 'Comprehensive media library statistics from Jellyfin and Arr services',
  icon: 'fas fa-chart-bar',
  component: {
    type: 'custom',
    refreshInterval: 300000, // 5 minutes
    template: `
      <div class="media-stats-widget">
        <h3 class="widget-title">📚 Library Statistics</h3>
        <div class="stats-grid">
          <div class="stat-item movies">
            <div class="stat-icon">🎬</div>
            <div class="stat-content">
              <div class="stat-value" id="movie-count">---</div>
              <div class="stat-label">Movies</div>
              <div class="stat-detail" id="movie-size">--- TB</div>
            </div>
          </div>
          <div class="stat-item tv">
            <div class="stat-icon">📺</div>
            <div class="stat-content">
              <div class="stat-value" id="tv-count">---</div>
              <div class="stat-label">TV Shows</div>
              <div class="stat-detail" id="episode-count">--- Episodes</div>
            </div>
          </div>
          <div class="stat-item music">
            <div class="stat-icon">🎵</div>
            <div class="stat-content">
              <div class="stat-value" id="album-count">---</div>
              <div class="stat-label">Albums</div>
              <div class="stat-detail" id="track-count">--- Tracks</div>
            </div>
          </div>
          <div class="stat-item books">
            <div class="stat-icon">📖</div>
            <div class="stat-content">
              <div class="stat-value" id="book-count">---</div>
              <div class="stat-label">Books</div>
              <div class="stat-detail" id="book-size">--- GB</div>
            </div>
          </div>
        </div>
        <div class="library-health">
          <div class="health-indicator" id="library-health">
            <span class="health-dot"></span>
            <span class="health-text">Library Status: Healthy</span>
          </div>
        </div>
      </div>
    `,
    styles: `
      .media-stats-widget {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        border-radius: 12px;
        padding: 20px;
        color: white;
        height: 100%;
      }
      
      .widget-title {
        margin: 0 0 20px 0;
        font-size: 18px;
        font-weight: bold;
        text-align: center;
      }
      
      .stats-grid {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 15px;
        margin-bottom: 20px;
      }
      
      .stat-item {
        background: rgba(255, 255, 255, 0.1);
        border-radius: 8px;
        padding: 15px;
        display: flex;
        align-items: center;
        gap: 12px;
        backdrop-filter: blur(10px);
      }
      
      .stat-icon {
        font-size: 24px;
        opacity: 0.8;
      }
      
      .stat-value {
        font-size: 24px;
        font-weight: bold;
        line-height: 1;
      }
      
      .stat-label {
        font-size: 12px;
        opacity: 0.8;
        margin-top: 2px;
      }
      
      .stat-detail {
        font-size: 10px;
        opacity: 0.6;
        margin-top: 4px;
      }
      
      .library-health {
        text-align: center;
        padding-top: 15px;
        border-top: 1px solid rgba(255, 255, 255, 0.2);
      }
      
      .health-indicator {
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 8px;
      }
      
      .health-dot {
        width: 8px;
        height: 8px;
        border-radius: 50%;
        background: #4CAF50;
        animation: pulse 2s infinite;
      }
      
      @keyframes pulse {
        0% { opacity: 1; }
        50% { opacity: 0.5; }
        100% { opacity: 1; }
      }
    `,
    script: `
      async function updateMediaStats() {
        try {
          // Fetch Jellyfin library stats
          const jellyfinResponse = await fetch('/api/jellyfin/library/stats');
          const jellyfinData = await jellyfinResponse.json();
          
          // Update movie stats
          document.getElementById('movie-count').textContent = jellyfinData.movies?.count || '0';
          document.getElementById('movie-size').textContent = (jellyfinData.movies?.totalSize / 1024 / 1024 / 1024 / 1024).toFixed(1) + ' TB';
          
          // Update TV stats
          document.getElementById('tv-count').textContent = jellyfinData.series?.count || '0';
          document.getElementById('episode-count').textContent = jellyfinData.episodes?.count || '0' + ' Episodes';
          
          // Update music stats
          document.getElementById('album-count').textContent = jellyfinData.albums?.count || '0';
          document.getElementById('track-count').textContent = jellyfinData.tracks?.count || '0' + ' Tracks';
          
          // Update book stats
          document.getElementById('book-count').textContent = jellyfinData.books?.count || '0';
          document.getElementById('book-size').textContent = (jellyfinData.books?.totalSize / 1024 / 1024 / 1024).toFixed(1) + ' GB';
          
        } catch (error) {
          console.error('Error fetching media stats:', error);
          document.getElementById('library-health').innerHTML = 
            '<span class="health-dot" style="background: #f44336;"></span><span class="health-text">Library Status: Error</span>';
        }
      }
      
      // Update stats on load and every 5 minutes
      updateMediaStats();
      setInterval(updateMediaStats, 300000);
    `
  }
};

// Active Downloads Widget
const activeDownloads = {
  id: 'active-downloads',
  name: 'Active Downloads',
  description: 'Real-time download progress from qBittorrent',
  icon: 'fas fa-download',
  component: {
    type: 'custom',
    refreshInterval: 30000, // 30 seconds
    template: `
      <div class="downloads-widget">
        <h3 class="widget-title">⬇️ Active Downloads</h3>
        <div class="download-summary">
          <div class="summary-stat">
            <span class="summary-value" id="active-count">0</span>
            <span class="summary-label">Active</span>
          </div>
          <div class="summary-stat">
            <span class="summary-value" id="download-speed">0 MB/s</span>
            <span class="summary-label">Speed</span>
          </div>
          <div class="summary-stat">
            <span class="summary-value" id="eta-avg">--</span>
            <span class="summary-label">ETA</span>
          </div>
        </div>
        <div class="downloads-list" id="downloads-list">
          <div class="no-downloads">No active downloads</div>
        </div>
      </div>
    `,
    styles: `
      .downloads-widget {
        background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
        border-radius: 12px;
        padding: 20px;
        color: white;
        height: 100%;
        display: flex;
        flex-direction: column;
      }
      
      .widget-title {
        margin: 0 0 15px 0;
        font-size: 18px;
        font-weight: bold;
        text-align: center;
      }
      
      .download-summary {
        display: flex;
        justify-content: space-between;
        margin-bottom: 15px;
        padding: 10px;
        background: rgba(255, 255, 255, 0.1);
        border-radius: 8px;
      }
      
      .summary-stat {
        text-align: center;
        flex: 1;
      }
      
      .summary-value {
        display: block;
        font-size: 16px;
        font-weight: bold;
      }
      
      .summary-label {
        font-size: 11px;
        opacity: 0.8;
      }
      
      .downloads-list {
        flex: 1;
        max-height: 200px;
        overflow-y: auto;
      }
      
      .download-item {
        background: rgba(255, 255, 255, 0.1);
        border-radius: 6px;
        padding: 10px;
        margin-bottom: 8px;
      }
      
      .download-name {
        font-size: 12px;
        font-weight: bold;
        margin-bottom: 5px;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
      }
      
      .download-progress {
        background: rgba(255, 255, 255, 0.2);
        border-radius: 10px;
        height: 6px;
        margin-bottom: 5px;
        overflow: hidden;
      }
      
      .download-progress-bar {
        background: #4CAF50;
        height: 100%;
        transition: width 0.3s ease;
      }
      
      .download-details {
        display: flex;
        justify-content: space-between;
        font-size: 10px;
        opacity: 0.8;
      }
      
      .no-downloads {
        text-align: center;
        opacity: 0.6;
        font-style: italic;
        padding: 20px;
      }
    `,
    script: `
      async function updateDownloads() {
        try {
          const response = await fetch('/api/qbittorrent/torrents/info');
          const torrents = await response.json();
          
          const activeTorrents = torrents.filter(t => t.state === 'downloading');
          const totalSpeed = activeTorrents.reduce((sum, t) => sum + t.dlspeed, 0);
          
          // Update summary
          document.getElementById('active-count').textContent = activeTorrents.length;
          document.getElementById('download-speed').textContent = formatSpeed(totalSpeed);
          
          // Calculate average ETA
          const avgEta = activeTorrents.length > 0 
            ? activeTorrents.reduce((sum, t) => sum + t.eta, 0) / activeTorrents.length
            : 0;
          document.getElementById('eta-avg').textContent = formatTime(avgEta);
          
          // Update downloads list
          const downloadsList = document.getElementById('downloads-list');
          if (activeTorrents.length === 0) {
            downloadsList.innerHTML = '<div class="no-downloads">No active downloads</div>';
          } else {
            downloadsList.innerHTML = activeTorrents.slice(0, 5).map(torrent => \`
              <div class="download-item">
                <div class="download-name" title="\${torrent.name}">\${torrent.name}</div>
                <div class="download-progress">
                  <div class="download-progress-bar" style="width: \${torrent.progress * 100}%"></div>
                </div>
                <div class="download-details">
                  <span>\${formatSize(torrent.size)}</span>
                  <span>\${formatSpeed(torrent.dlspeed)}</span>
                  <span>\${formatTime(torrent.eta)}</span>
                </div>
              </div>
            \`).join('');
          }
          
        } catch (error) {
          console.error('Error fetching downloads:', error);
        }
      }
      
      function formatSpeed(bytesPerSec) {
        if (bytesPerSec < 1024) return bytesPerSec + ' B/s';
        if (bytesPerSec < 1024 * 1024) return (bytesPerSec / 1024).toFixed(1) + ' KB/s';
        return (bytesPerSec / 1024 / 1024).toFixed(1) + ' MB/s';
      }
      
      function formatSize(bytes) {
        if (bytes < 1024) return bytes + ' B';
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
        if (bytes < 1024 * 1024 * 1024) return (bytes / 1024 / 1024).toFixed(1) + ' MB';
        return (bytes / 1024 / 1024 / 1024).toFixed(1) + ' GB';
      }
      
      function formatTime(seconds) {
        if (seconds === 8640000) return '∞';
        if (seconds < 60) return seconds + 's';
        if (seconds < 3600) return Math.floor(seconds / 60) + 'm';
        if (seconds < 86400) return Math.floor(seconds / 3600) + 'h';
        return Math.floor(seconds / 86400) + 'd';
      }
      
      // Update downloads on load and every 30 seconds
      updateDownloads();
      setInterval(updateDownloads, 30000);
    `
  }
};

// System Resource Monitor Widget
const systemResources = {
  id: 'system-resources',
  name: 'System Resources',
  description: 'Real-time system resource monitoring',
  icon: 'fas fa-microchip',
  component: {
    type: 'custom',
    refreshInterval: 10000, // 10 seconds
    template: `
      <div class="resources-widget">
        <h3 class="widget-title">🖥️ System Resources</h3>
        <div class="resource-meters">
          <div class="resource-item">
            <div class="resource-label">CPU</div>
            <div class="resource-meter">
              <div class="resource-bar cpu-bar" id="cpu-bar"></div>
            </div>
            <div class="resource-value" id="cpu-value">0%</div>
          </div>
          <div class="resource-item">
            <div class="resource-label">Memory</div>
            <div class="resource-meter">
              <div class="resource-bar memory-bar" id="memory-bar"></div>
            </div>
            <div class="resource-value" id="memory-value">0%</div>
          </div>
          <div class="resource-item">
            <div class="resource-label">Storage</div>
            <div class="resource-meter">
              <div class="resource-bar storage-bar" id="storage-bar"></div>
            </div>
            <div class="resource-value" id="storage-value">0%</div>
          </div>
          <div class="resource-item">
            <div class="resource-label">Network</div>
            <div class="resource-network">
              <div class="network-stat">
                <span class="network-label">↓</span>
                <span class="network-value" id="network-down">0 MB/s</span>
              </div>
              <div class="network-stat">
                <span class="network-label">↑</span>
                <span class="network-value" id="network-up">0 MB/s</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    `,
    styles: `
      .resources-widget {
        background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
        border-radius: 12px;
        padding: 20px;
        color: white;
        height: 100%;
      }
      
      .widget-title {
        margin: 0 0 20px 0;
        font-size: 18px;
        font-weight: bold;
        text-align: center;
      }
      
      .resource-item {
        margin-bottom: 15px;
      }
      
      .resource-label {
        font-size: 12px;
        margin-bottom: 5px;
        opacity: 0.8;
      }
      
      .resource-meter {
        background: rgba(255, 255, 255, 0.2);
        border-radius: 10px;
        height: 8px;
        margin-bottom: 5px;
        overflow: hidden;
        position: relative;
      }
      
      .resource-bar {
        height: 100%;
        border-radius: 10px;
        transition: width 0.5s ease;
      }
      
      .cpu-bar { background: #ff6b6b; }
      .memory-bar { background: #4ecdc4; }
      .storage-bar { background: #45b7d1; }
      
      .resource-value {
        font-size: 12px;
        font-weight: bold;
        text-align: right;
      }
      
      .resource-network {
        display: flex;
        justify-content: space-between;
      }
      
      .network-stat {
        display: flex;
        align-items: center;
        gap: 4px;
      }
      
      .network-label {
        font-size: 16px;
        font-weight: bold;
      }
      
      .network-value {
        font-size: 12px;
      }
    `,
    script: `
      async function updateSystemResources() {
        try {
          const response = await fetch('/api/system/stats');
          const stats = await response.json();
          
          // Update CPU
          document.getElementById('cpu-bar').style.width = stats.cpu.usage + '%';
          document.getElementById('cpu-value').textContent = stats.cpu.usage.toFixed(1) + '%';
          
          // Update Memory
          const memoryPercent = (stats.memory.used / stats.memory.total) * 100;
          document.getElementById('memory-bar').style.width = memoryPercent + '%';
          document.getElementById('memory-value').textContent = memoryPercent.toFixed(1) + '%';
          
          // Update Storage
          const storagePercent = (stats.storage.used / stats.storage.total) * 100;
          document.getElementById('storage-bar').style.width = storagePercent + '%';
          document.getElementById('storage-value').textContent = storagePercent.toFixed(1) + '%';
          
          // Update Network
          document.getElementById('network-down').textContent = formatSpeed(stats.network.download);
          document.getElementById('network-up').textContent = formatSpeed(stats.network.upload);
          
        } catch (error) {
          console.error('Error fetching system stats:', error);
        }
      }
      
      function formatSpeed(bytesPerSec) {
        if (bytesPerSec < 1024) return bytesPerSec + ' B/s';
        if (bytesPerSec < 1024 * 1024) return (bytesPerSec / 1024).toFixed(1) + ' KB/s';
        return (bytesPerSec / 1024 / 1024).toFixed(1) + ' MB/s';
      }
      
      // Update resources on load and every 10 seconds
      updateSystemResources();
      setInterval(updateSystemResources, 10000);
    `
  }
};

module.exports = {
  mediaLibraryStats,
  activeDownloads,
  systemResources
};