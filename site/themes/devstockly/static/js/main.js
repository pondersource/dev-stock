// Main application entry point
import { CompatibilityMatrix } from './components/CompatibilityMatrix.js';
import { config } from './config.js';
import { ErrorHandler } from './utils/ErrorHandler.js';
import { StateManager } from './utils/StateManager.js';
import { EventManager, DOMManager, throttle } from './utils/Performance.js';

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
        this.matrix = new CompatibilityMatrix();
        await this.matrix.init();
    }

    setupEventListeners() {
        // Explore button scroll handler
        const exploreBtn = DOMManager.getElement('exploreBtn');
        if (exploreBtn) {
            this.eventManager.addEvent(exploreBtn, 'click', () => {
                const mainContent = DOMManager.getElement('mainContent');
                mainContent?.scrollIntoView({ behavior: 'smooth' });
            });
        }

        // Scroll down button handler
        const scrollDown = DOMManager.getElement('scrollDown');
        if (scrollDown) {
            this.eventManager.addEvent(scrollDown, 'click', () => {
                window.scrollTo({
                    top: document.documentElement.scrollHeight,
                    behavior: 'smooth'
                });
            });
        }

        // Parallax effect
        this.setupParallax();
    }

    setupParallax() {
        const handleParallax = throttle(() => {
            const scrolled = window.pageYOffset;
            const parallaxElements = document.querySelectorAll('[data-parallax]');
            
            DOMManager.batchUpdate(
                Array.from(parallaxElements).map(element => ({
                    id: element.id,
                    updates: {
                        style: {
                            transform: `translateY(${scrolled * parseFloat(element.dataset.parallax)}px)`
                        }
                    }
                }))
            );
        }, 16); // ~60fps

        this.eventManager.addEvent(window, 'scroll', handleParallax, { passive: true });
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

            // Setup event listeners
            this.setupEventListeners();

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
