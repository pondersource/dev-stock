// BundleSizes.js - Handles bundle size information for download cards

class BundleSizes {
    constructor() {
        this.sizes = null;
        this.loadSizes();
    }

    async loadSizes() {
        try {
            const response = await fetch('./artifacts/bundle-sizes.json');
            if (!response.ok) {
                console.error('Failed to load bundle sizes:', response.status);
                return;
            }
            this.sizes = await response.json();
            this.updateDownloadSizes();
        } catch (error) {
            console.error('Error loading bundle sizes:', error);
        }
    }

    updateDownloadSizes() {
        const downloadCards = document.querySelectorAll('.platform-card[download]');
        downloadCards.forEach(card => {
            const href = card.getAttribute('href');
            if (!href) return;

            const bundleName = href.split('/').pop();
            const sizeSpan = card.querySelector('.download-size');
            if (!sizeSpan) return;

            const bundleInfo = this.sizes?.[bundleName];
            if (bundleInfo) {
                // Set the main text to the human-readable size
                sizeSpan.textContent = bundleInfo.size;
                
                // Add hover title with more detailed information
                const bytes = parseInt(bundleInfo.bytes);
                const details = [
                    bundleInfo.size,
                    `${bytes.toLocaleString()} bytes`
                ].join(' • ');
                
                sizeSpan.title = details;
                
                // Add the raw byte size as a data attribute for potential use
                sizeSpan.dataset.bytes = bundleInfo.bytes;
                
                // Add a class to indicate size is available
                sizeSpan.classList.add('has-size');
            } else {
                sizeSpan.textContent = 'Download Bundle';
                sizeSpan.classList.remove('has-size');
            }
        });
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.bundleSizes = new BundleSizes();
});

export { BundleSizes }; 