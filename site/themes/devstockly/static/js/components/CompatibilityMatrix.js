import { config } from '../config.js';
import { TestOverlay } from './TestOverlay.js';
import { STATUS_TEXT, STATUS_COLORS } from '../constants.js';
import { generateWorkflowName, getWorkflowStatus, generateMediaUrls } from '../utils.js';
import { createStatusLegend, createStatusButton, createMatrixSection, createMatrixTable } from './UIComponents.js';

export class CompatibilityMatrix {
    constructor() {
        console.log('CompatibilityMatrix: Initializing...');
        this.matrixContainer = document.getElementById('compatibilityMatrix');
        if (!this.matrixContainer) {
            console.error('CompatibilityMatrix: Could not find matrix container element');
            return;
        }
        this.workflowStatuses = null;
        this.overlay = new TestOverlay();
        this.testCategories = config.categories;
        console.log('CompatibilityMatrix: Constructor completed');
    }

    async init() {
        console.log('CompatibilityMatrix: Starting initialization...');
        try {
            console.log('CompatibilityMatrix: Fetching workflow status from:', config.workflowStatusUrl);
            const response = await fetch(config.workflowStatusUrl);
            if (!response.ok) {
                if (response.status === 404) {
                    console.error('CompatibilityMatrix: Workflow status file not found');
                    this.showError('Status data not available');
                    return;
                }
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            this.workflowStatuses = await response.json();
            console.log('CompatibilityMatrix: Successfully loaded workflow statuses');
            this.render();
        } catch (error) {
            console.error('CompatibilityMatrix: Failed to load workflow statuses:', error);
            this.showError('Failed to load test results');
        }
    }

    showError(message) {
        console.log('CompatibilityMatrix: Showing error:', message);
        const matrixContent = this.matrixContainer.querySelector('.matrix-content');
        if (!matrixContent) {
            console.error('CompatibilityMatrix: Could not find matrix-content element for error display');
            return;
        }

        const errorDiv = document.createElement('div');
        errorDiv.className = 'matrix-error';
        errorDiv.innerHTML = `
            <div class="error-content">
                <i class="fas fa-exclamation-circle"></i>
                <p>${message}</p>
                <button class="retry-btn" onclick="window.location.reload()">
                    <i class="fas fa-sync-alt"></i>
                    Retry
                </button>
            </div>
        `;
        matrixContent.appendChild(errorDiv);
    }

    render() {
        console.log('CompatibilityMatrix: Starting render...');

        // Add status legend to toolbar
        const statusLegend = this.matrixContainer.querySelector('.status-legend');
        if (statusLegend) {
            statusLegend.innerHTML = ''; // Clear existing content
            statusLegend.appendChild(createStatusLegend());
            console.log('CompatibilityMatrix: Added status legend');
        } else {
            console.warn('CompatibilityMatrix: Could not find status-legend element');
        }

        // Create matrix content
        const matrixContent = this.matrixContainer.querySelector('.matrix-content');
        if (!matrixContent) {
            console.error('CompatibilityMatrix: Could not find matrix-content element');
            return;
        }

        // Clear existing content
        matrixContent.innerHTML = '';

        console.log('CompatibilityMatrix: Creating matrix sections for categories:', this.testCategories);
        this.testCategories.forEach(category => {
            console.log('CompatibilityMatrix: Processing category:', category.id);
            const matrixData = this.prepareMatrixData(category);
            const table = createMatrixTable(matrixData, {
                cornerText: category.cornerText || 'Source ➜ Target',
                onCellClick: (result) => this.handleCellClick(result)
            });

            const section = createMatrixSection(category, table);
            matrixContent.appendChild(section);
            console.log('CompatibilityMatrix: Added section for category:', category.id);
        });

        console.log('CompatibilityMatrix: Render completed');
    }

    prepareMatrixData(category) {
        const data = {
            platforms: category.platforms || category.targets,
            tests: []
        };

        if (category.platforms) {
            // Single row matrix
            const results = category.platforms.map(platform => {
                const workflowName = generateWorkflowName(category.workflowPrefix, platform);
                return {
                    status: getWorkflowStatus(this.workflowStatuses, workflowName),
                    platform,
                    workflowName
                };
            });

            data.tests.push({
                source: 'Status',
                results
            });
        } else {
            // Full matrix
            category.sources.forEach(source => {
                const results = category.targets.map(target => {
                    const workflowName = generateWorkflowName(category.workflowPrefix, source, target);
                    return {
                        status: getWorkflowStatus(this.workflowStatuses, workflowName),
                        source,
                        target,
                        workflowName
                    };
                });

                data.tests.push({
                    source,
                    results
                });
            });
        }

        return data;
    }

    async handleCellClick(result) {
        const { video: videoUrl, thumbnail: thumbnailUrl } = generateMediaUrls(result.workflowName);
        const status = {
            icon: result.status,
            color: STATUS_COLORS[result.status],
            text: STATUS_TEXT[result.status]
        };

        this.overlay.show(result.workflowName, status, videoUrl, thumbnailUrl);
    }
}
