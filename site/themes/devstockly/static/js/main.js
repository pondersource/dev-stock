// Main application entry point
import { CompatibilityMatrix } from './components/CompatibilityMatrix.js';
import { BundleSizes } from './components/BundleSizes.js';
import { config } from './config.js';
import { ErrorHandler } from './utils/ErrorHandler.js';
import { StateManager } from './utils/StateManager.js';
import { EventManager, DOMManager } from './utils/Performance.js';
import { initPartnersTabSwitching } from './sections/partners.js';
import { initHeroSection } from './sections/hero.js';

class App {
    constructor() {
        // Core services
        this.state = new StateManager({
            initialized: false,
            loading: false,
            error: null
        });
        this.errorHandler = new ErrorHandler();
        this.eventManager = new EventManager();

        // Components
        this.heroSection = null;
        this.matrix = null;

        // Initialize error handling
        this.setupErrorHandling();
    }

    setupErrorHandling() {
        window.addEventListener('error', (event) => {
            const strategy = this.errorHandler.handleError(event.error, ErrorHandler.ERROR_TYPES.RUNTIME);
            this.handleErrorStrategy(strategy);
            event.preventDefault();
        });

        window.addEventListener('unhandledrejection', (event) => {
            const strategy = this.errorHandler.handleError(event.reason, ErrorHandler.ERROR_TYPES.RUNTIME);
            this.handleErrorStrategy(strategy);
            event.preventDefault();
        });
    }

    handleErrorStrategy(strategy) {
        switch (strategy.action) {
            case 'retry':
                this.retryInitialization();
                break;
            case 'reload':
                location.reload();
                break;
            case 'notify':
                this.showError(strategy.message);
                break;
        }
    }

    async retryInitialization() {
        const state = this.state.getState();
        if (!state.initialized && !state.loading) {
            await this.init();
        }
    }

    async initComponents() {
        // Initialize hero section
        this.heroSection = initHeroSection();
        this.heroSection.init();

        this.matrix = new CompatibilityMatrix();
        await this.matrix.init();

        // Initialize bundle sizes
        new BundleSizes();
    }

    async init() {
        try {
            const currentState = this.state.getState();
            if (currentState.initialized || currentState.loading) {
                return;
            }

            this.state.setState({ loading: true, error: null });

            // Verify manifest availability
            const response = await fetch(config.manifestUrl);
            if (!response.ok) {
                throw new Error(`Failed to load manifest: ${response.status}`);
            }

            const data = await response.json();
            if (!data.videos || !Array.isArray(data.videos)) {
                throw new Error('Invalid manifest format');
            }

            // Initialize components
            await this.initComponents();

            // Render matrix
            await this.matrix.render();

            this.state.setState({
                initialized: true,
                loading: false
            }, { persist: true });

            console.log('Application initialized successfully');

        } catch (error) {
            const strategy = this.errorHandler.handleError(error, ErrorHandler.ERROR_TYPES.INITIALIZATION);
            this.state.setState({
                error: error.message,
                loading: false
            });
            this.handleErrorStrategy(strategy);
        }
    }

    showError(message) {
        const container = DOMManager.getElement('gallery-container');
        if (!container) {
            console.error('Error container not found');
            return;
        }

        const errorTemplate = DOMManager.getElement('error-message-template');
        if (!errorTemplate) {
            console.error('Error template not found');
            return;
        }

        // Remove any existing error messages
        container.querySelectorAll('.error-message').forEach(error => error.remove());

        // Create new error message
        const errorElement = document.importNode(errorTemplate.content, true);
        const errorText = errorElement.querySelector('.error-text');
        if (errorText) {
            errorText.textContent = `Failed to initialize: ${message}`;
        }

        const retryButton = errorElement.querySelector('.retry-button');
        if (retryButton) {
            this.eventManager.addEvent(retryButton, 'click', () => this.retryInitialization());
        }

        container.appendChild(errorElement);
    }

    dispose() {
        // Cleanup
        this.eventManager.removeAll();
        DOMManager.clearCache();
        this.state.reset();

        if (this.heroSection) {
            this.heroSection.dispose();
            this.heroSection = null;
        }

        if (this.matrix) {
            this.matrix.dispose?.();
            this.matrix = null;
        }
    }
}

// Initialize app when DOM is ready
document.addEventListener('DOMContentLoaded', async () => {
    const app = new App();
    try {
        await app.init();
    } catch (error) {
        console.error('Failed to start application:', error);
    }
});

// Download menu functionality
document.addEventListener('DOMContentLoaded', () => {
    const downloadBtn = document.getElementById('downloadBtn');
    const downloadMenu = document.getElementById('downloadMenu');

    if (downloadBtn && downloadMenu) {
        // Toggle menu on button click
        downloadBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            downloadMenu.classList.toggle('active');
        });

        // Close menu when clicking outside
        document.addEventListener('click', (e) => {
            if (!downloadMenu.contains(e.target) && !downloadBtn.contains(e.target)) {
                downloadMenu.classList.remove('active');
            }
        });

        // Prevent menu from closing when clicking inside
        downloadMenu.addEventListener('click', (e) => {
            e.stopPropagation();
        });
    }
});

document.addEventListener('DOMContentLoaded', function () {
    // Initialize partners tab switching
    initPartnersTabSwitching();
});
