export class VideoPlayer {
    constructor(videoElement) {
        this.video = videoElement;
        this.controls = {
            playPause: () => this.video.paused ? this.video.play() : this.video.pause(),
            rewind: () => this.video.currentTime = Math.max(0, this.video.currentTime - 10),
            forward: () => this.video.currentTime = Math.min(this.video.duration, this.video.currentTime + 10),
            toggleFullscreen: () => {
                if (document.fullscreenElement) {
                    document.exitFullscreen();
                } else {
                    this.video.requestFullscreen();
                }
            }
        };
    }

    init() {
        this.setupKeyboardControls();
        this.setupTouchControls();
        this.setupCustomControls();
    }

    setupKeyboardControls() {
        this.video.addEventListener('keydown', (e) => {
            switch(e.code) {
                case 'Space': 
                    e.preventDefault();
                    this.controls.playPause();
                    break;
                case 'ArrowLeft':
                    this.controls.rewind();
                    break;
                case 'ArrowRight':
                    this.controls.forward();
                    break;
                case 'KeyF':
                    this.controls.toggleFullscreen();
                    break;
            }
        });
    }

    setupTouchControls() {
        let touchStartX = 0;
        
        this.video.addEventListener('touchstart', e => {
            touchStartX = e.touches[0].clientX;
        });

        this.video.addEventListener('touchend', e => {
            const touchEndX = e.changedTouches[0].clientX;
            const diff = touchEndX - touchStartX;
            
            if (Math.abs(diff) > 50) { // Minimum swipe distance
                diff > 0 ? this.controls.rewind() : this.controls.forward();
            }
        });
    }

    setupCustomControls() {
        const overlay = document.createElement('div');
        overlay.className = 'video-controls-overlay';
        overlay.innerHTML = `
            <button class="control-button rewind" aria-label="Rewind 10 seconds">⏪</button>
            <button class="control-button play-pause" aria-label="Play/Pause">▶️</button>
            <button class="control-button forward" aria-label="Forward 10 seconds">⏩</button>
        `;

        // Add event listeners to custom controls
        const buttons = {
            rewind: overlay.querySelector('.rewind'),
            playPause: overlay.querySelector('.play-pause'),
            forward: overlay.querySelector('.forward')
        };

        buttons.rewind.addEventListener('click', this.controls.rewind);
        buttons.playPause.addEventListener('click', this.controls.playPause);
        buttons.forward.addEventListener('click', this.controls.forward);

        // Update play/pause button state
        this.video.addEventListener('play', () => {
            buttons.playPause.textContent = '⏸️';
        });
        this.video.addEventListener('pause', () => {
            buttons.playPause.textContent = '▶️';
        });

        this.video.parentElement.appendChild(overlay);
    }
}
