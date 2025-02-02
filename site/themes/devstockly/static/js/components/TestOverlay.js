export class TestOverlay {
    constructor() {
        this.overlay = null;
        this.createOverlay();
    }

    createOverlay() {
        const template = `
            <div class="test-overlay">
                <div class="test-overlay__content">
                    <button class="test-overlay__close">×</button>
                    <div class="test-overlay__header">
                        <h3 class="test-overlay__title"></h3>
                        <a class="test-overlay__ci-link" target="_blank">
                            <i class="fas fa-external-link-alt"></i> View in GitHub Actions
                        </a>
                    </div>
                    <div class="test-overlay__body">
                        <div class="test-overlay__video-container">
                            <div class="test-overlay__video-wrapper">
                                <video controls preload="none">
                                    <source type="video/webm" src="">
                                </video>
                                <div class="test-overlay__video-loading">
                                    <div class="spinner"></div>
                                </div>
                            </div>
                        </div>
                        <div class="test-overlay__info">
                            <div class="test-overlay__status"></div>
                            <a class="test-overlay__download" download>
                                <i class="fas fa-download"></i> Download Recording
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        `;

        const div = document.createElement('div');
        div.innerHTML = template;
        this.overlay = div.firstElementChild;
        document.body.appendChild(this.overlay);

        // Close handlers
        this.overlay.querySelector('.test-overlay__close').addEventListener('click', () => this.hide());
        this.overlay.addEventListener('click', (e) => {
            if (e.target === this.overlay) this.hide();
        });

        // Video loading handlers
        const video = this.overlay.querySelector('video');
        video.addEventListener('loadstart', () => this.showVideoLoading());
        video.addEventListener('canplay', () => this.hideVideoLoading());
        video.addEventListener('error', () => this.handleVideoError());
    }

    async checkImageExists(url) {
        try {
            const response = await fetch(url, { method: 'HEAD' });
            return response.ok;
        } catch (error) {
            console.warn('Failed to check thumbnail:', error);
            return false;
        }
    }

    async show(workflowName, status, videoUrl, thumbnailUrl) {
        document.body.classList.add('overlay-active');
        this.overlay.querySelector('.test-overlay__title').textContent = `Test Results: ${workflowName}`;
        this.overlay.querySelector('.test-overlay__ci-link').href = 
            `https://github.com/pondersource/dev-stock/actions/workflows/${workflowName}.yml`;
        
        // Set up video if available
        const video = this.overlay.querySelector('video');
        const source = video.querySelector('source');
        const videoContainer = this.overlay.querySelector('.test-overlay__video-container');
        
        if (videoUrl) {
            // Check if thumbnail exists before setting it
            if (thumbnailUrl) {
                const thumbnailExists = await this.checkImageExists(thumbnailUrl);
                if (thumbnailExists) {
                    video.poster = thumbnailUrl;
                } else {
                    video.removeAttribute('poster');
                }
            } else {
                video.removeAttribute('poster');
            }

            // Set video source
            source.src = videoUrl;
            video.load(); // Reload video with new source
            
            videoContainer.style.display = 'block';
            this.showVideoLoading();
            
            // Set up download link
            const downloadLink = this.overlay.querySelector('.test-overlay__download');
            downloadLink.href = videoUrl;
            downloadLink.style.display = 'inline-flex';
        } else {
            videoContainer.style.display = 'none';
            this.overlay.querySelector('.test-overlay__download').style.display = 'none';
        }

        // Show status
        const statusEl = this.overlay.querySelector('.test-overlay__status');
        statusEl.innerHTML = `<i class="fas fa-${status.icon}" style="color: ${status.color}"></i> ${status.text}`;

        this.overlay.classList.add('active');
    }

    hide() {
        document.body.classList.remove('overlay-active');
        this.overlay.classList.remove('active');
        const video = this.overlay.querySelector('video');
        if (video) {
            video.pause();
            video.currentTime = 0;
            video.removeAttribute('poster');
            video.querySelector('source').removeAttribute('src');
            video.load();
        }
    }

    showVideoLoading() {
        const loadingEl = this.overlay.querySelector('.test-overlay__video-loading');
        if (loadingEl) {
            loadingEl.style.display = 'flex';
        }
    }

    hideVideoLoading() {
        const loadingEl = this.overlay.querySelector('.test-overlay__video-loading');
        if (loadingEl) {
            loadingEl.style.display = 'none';
        }
    }

    handleVideoError() {
        const videoContainer = this.overlay.querySelector('.test-overlay__video-container');
        videoContainer.innerHTML = '<p class="test-overlay__error">Failed to load video recording</p>';
        this.overlay.querySelector('.test-overlay__download').style.display = 'none';
    }
} 