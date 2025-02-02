import { config } from '/js/config.js';
import { VideoPlayer } from '/js/components/VideoPlayer.js';

export class VideoGallery {
    constructor(videos) {
        this.videos = videos;
        this.categories = new Map();
        this.loadingSpinner = null;
    }

    async render() {
        this.showLoading();
        await this.initializeCategories();
        await this.loadVideos();
        this.hideLoading();
    }

    showLoading() {
        const template = document.getElementById('loading-spinner-template');
        const spinnerContent = document.importNode(template.content, true);
        this.loadingSpinner = spinnerContent.querySelector('.loading-spinner');
        document.querySelector('.gallery-container').appendChild(this.loadingSpinner);
    }

    hideLoading() {
        if (this.loadingSpinner && this.loadingSpinner.parentNode) {
            this.loadingSpinner.parentNode.removeChild(this.loadingSpinner);
            this.loadingSpinner = null;
        }
    }

    async initializeCategories() {
        // Initialize category containers with loading skeletons
        Object.values(config.categories).forEach(category => {
            const container = document.querySelector(`#${category.id} .test-grid`);
            if (container) {
                this.categories.set(category.id, container);
                this.createSkeletons(container, 3);
            }
        });
    }

    async loadVideos() {
        // Remove skeletons
        this.categories.forEach(container => {
            this.removeSkeletons(container);
        });

        // Load videos with staggered animation
        const delay = ms => new Promise(resolve => setTimeout(resolve, ms));

        for (const video of this.videos) {
            const category = this.getCategoryFromWorkflow(video.workflow);
            const container = this.categories.get(category);

            if (container) {
                const card = await this.createVideoCard(video);
                container.appendChild(card);

                // Show category if it's the first card
                const categoryElement = container.closest('.category');
                if (categoryElement.classList.contains('hidden')) {
                    categoryElement.classList.remove('hidden');
                }

                // Stagger animation
                await delay(50);
                card.classList.remove('hidden');
            }
        }
    }

    getCategoryFromWorkflow(workflowName) {
        const lowerWorkflow = workflowName.toLowerCase();
        if (lowerWorkflow.startsWith('login')) return 'auth-tests';
        if (lowerWorkflow.startsWith('share-link')) return 'share-link-tests';
        if (lowerWorkflow.startsWith('share-with')) return 'share-with-tests';
        if (lowerWorkflow.startsWith('invite-link')) return 'sciencemesh-tests';
        return null;
    }

    async createVideoCard(videoData) {
        const template = document.getElementById('test-card-template');
        const card = document.importNode(template.content, true);
        const cardElement = card.querySelector('.test-card');
        cardElement.classList.add('hidden');

        // Set up video
        const video = cardElement.querySelector('video');
        const source = video.querySelector('source');
        const videoPath = videoData.video.replace(/^site\/static\//, '');
        const thumbnailPath = videoData.thumbnail.replace(/^site\/static\//, '');

        source.src = videoPath;
        video.poster = thumbnailPath;

        // Set up title and status
        const title = cardElement.querySelector('.test-name');
        title.textContent = this.formatWorkflowName(videoData.workflow);

        const status = cardElement.querySelector('.test-status');
        status.innerHTML = `<img src="https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/${videoData.workflow}.yml?branch=main&style=flat-square" alt="Test Status">`;

        // Initialize video player
        const player = new VideoPlayer(video);
        player.init();

        return cardElement;
    }

    formatWorkflowName(name) {
        return name.split('-')
            .map(word => word.charAt(0).toUpperCase() + word.slice(1))
            .join(' ');
    }

    createSkeletons(container, count) {
        const template = document.getElementById('skeleton-template');
        for (let i = 0; i < count; i++) {
            const skeleton = document.importNode(template.content, true);
            container.appendChild(skeleton);
        }
    }

    removeSkeletons(container) {
        container.querySelectorAll('.test-card-skeleton').forEach(skeleton => {
            skeleton.remove();
        });
    }
}
