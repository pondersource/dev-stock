// Main application entry point
import { VideoGallery } from '/js/components/VideoGallery.js';
import { CompatibilityMatrix } from '/js/components/CompatibilityMatrix.js';
import { config } from '/js/config.js';

class App {
    constructor() {
        this.gallery = null;
        this.matrix = null;
    }

    async init() {
        try {
            // Load manifest data
            const response = await fetch(config.manifestUrl);
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
            
            const data = await response.json();
            if (!data.videos || !Array.isArray(data.videos)) {
                throw new Error('Invalid manifest format');
            }

            // Initialize components
            this.gallery = new VideoGallery(data.videos);
            this.matrix = new CompatibilityMatrix(data.videos);

            // Render components
            await this.gallery.render();
            this.matrix.render();

        } catch (error) {
            console.error('Application initialization failed:', error);
            this.showError(error.message);
        }
    }

    showError(message) {
        const container = document.querySelector('.gallery-container');
        const errorTemplate = document.getElementById('error-message-template');
        const errorElement = document.importNode(errorTemplate.content, true);
        
        errorElement.querySelector('p').textContent = `Failed to initialize: ${message}`;
        errorElement.querySelector('.retry-button').addEventListener('click', () => {
            location.reload();
        });
        
        container.appendChild(errorElement);
    }
}

// Initialize app when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    const app = new App();
    app.init();
});
