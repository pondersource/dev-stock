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

        // Initialize search functionality
        this.initializeSearch();

        console.log('CompatibilityMatrix: Constructor completed');
    }

    initializeSearch() {
        const searchInput = this.matrixContainer.querySelector('.matrix-filter');
        const clearButton = this.matrixContainer.querySelector('.search-clear');

        if (!searchInput) {
            console.warn('CompatibilityMatrix: Search input not found');
            return;
        }

        // Handle input changes
        searchInput.addEventListener('input', (e) => {
            this.handleSearch(e.target.value);
            this.toggleClearButton(e.target.value);
        });

        // Handle clear button
        if (clearButton) {
            clearButton.addEventListener('click', () => {
                searchInput.value = '';
                this.handleSearch('');
                this.toggleClearButton('');
                searchInput.focus();
            });
        }

        console.log('CompatibilityMatrix: Search initialized');
    }

    toggleClearButton(value) {
        const clearButton = this.matrixContainer.querySelector('.search-clear');
        if (clearButton) {
            clearButton.classList.toggle('visible', value.length > 0);
        }
    }

    handleSearch(query) {
        const searchTerm = query.toLowerCase().trim();
        console.log('CompatibilityMatrix: Searching for:', searchTerm);

        const sections = this.matrixContainer.querySelectorAll('.matrix-section');
        sections.forEach(section => {
            let hasVisibleContent = false;
            const isAuthSection = section.id === 'auth-tests';

            if (isAuthSection) {
                // For auth-tests section, search in column headers
                const headers = Array.from(section.querySelectorAll('th'));
                headers.forEach((header, index) => {
                    if (index === 0) return; // Skip corner header
                    const headerText = header.querySelector('.platform-header-content span')?.textContent.toLowerCase() || '';
                    const headerMatches = headerText.includes(searchTerm);

                    // Show/hide column header and corresponding cells
                    header.style.display = headerMatches || !searchTerm ? '' : 'none';
                    const cells = section.querySelectorAll(`tbody tr td:nth-child(${index + 1})`);
                    cells.forEach(cell => {
                        cell.style.display = headerMatches || !searchTerm ? '' : 'none';
                    });

                    if (headerMatches) hasVisibleContent = true;
                });
            } else {
                // For other sections, search in row headers
                const rows = Array.from(section.querySelectorAll('tbody tr'));
                rows.forEach(row => {
                    const rowHeader = row.querySelector('td:first-child .platform-header-content span');
                    const rowHeaderText = rowHeader?.textContent.toLowerCase() || '';
                    const rowMatches = rowHeaderText.includes(searchTerm);

                    // Show/hide row based on match
                    row.style.display = rowMatches || !searchTerm ? '' : 'none';
                    if (rowMatches) hasVisibleContent = true;
                });
            }

            // Show/hide entire section based on matches
            section.style.display = hasVisibleContent || !searchTerm ? '' : 'none';
        });
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
