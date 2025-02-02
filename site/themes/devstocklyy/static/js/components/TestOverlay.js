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
                        <div class="test-overlay__video-container"></div>
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
    }

    show(workflowName, status, videoUrl) {
        document.body.classList.add('overlay-active');
        this.overlay.querySelector('.test-overlay__title').textContent = `Test Results: ${workflowName}`;
        this.overlay.querySelector('.test-overlay__ci-link').href = 
            `https://github.com/pondersource/dev-stock/actions/workflows/${workflowName}.yml`;
        
        // Set up video if available
        const videoContainer = this.overlay.querySelector('.test-overlay__video-container');
        if (videoUrl) {
            const video = document.createElement('video');
            video.src = videoUrl;
            video.controls = true;
            videoContainer.innerHTML = '';
            videoContainer.appendChild(video);
            
            // Set up download link
            const downloadLink = this.overlay.querySelector('.test-overlay__download');
            downloadLink.href = videoUrl;
            downloadLink.style.display = 'inline-flex';
        } else {
            videoContainer.innerHTML = '<p>No video recording available</p>';
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
        if (video) video.pause();
    }
} 