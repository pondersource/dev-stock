import { config } from '../config.js';
import { TestOverlay } from './TestOverlay.js';
import { STATUS_TEXT, STATUS_COLORS } from '../constants.js';
import { generateWorkflowName, getWorkflowStatus, generateMediaUrls } from '../utils.js';
import { createStatusLegend, createStatusButton, createMatrixSection } from './UIComponents.js';

export class CompatibilityMatrix {
    constructor() {
        this.matrixContainer = document.getElementById('compatibilityMatrix');
        this.workflowStatuses = null;
        this.overlay = new TestOverlay();
        this.testCategories = config.categories;
    }

    async init() {
        try {
            const response = await fetch(config.workflowStatusUrl);
            if (!response.ok) {
                if (response.status === 404) {
                    console.error('Workflow status file not found');
                    return;
                }
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            this.workflowStatuses = await response.json();
        } catch (error) {
            console.error('Failed to load workflow statuses:', error);
            this.workflowStatuses = null;
        }
    }

    async render() {
        await this.init();
        this.matrixContainer.insertBefore(
            createStatusLegend(),
            this.matrixContainer.firstChild
        );
        
        this.testCategories.forEach(category => {
            const table = this.createTable(category);
            const section = createMatrixSection(category, table);
            this.matrixContainer.appendChild(section);
        });
    }

    createTable(category) {
        const table = document.createElement('table');
        table.className = 'compatibility-table';
        table.appendChild(this.createTableHead(category));
        table.appendChild(this.createTableBody(category));
        return table;
    }

    createTableHead(category) {
        const thead = document.createElement('thead');
        const tr = document.createElement('tr');
        
        if (category.platforms) {
            tr.innerHTML = '<th>Platform</th>';
            category.platforms.forEach(platform => {
                tr.innerHTML += `<th>${platform}</th>`;
            });
        } else {
            tr.innerHTML = '<th>Source ➜ Target</th>';
            category.targets.forEach(target => {
                tr.innerHTML += `<th>${target}</th>`;
            });
        }
        
        thead.appendChild(tr);
        return thead;
    }

    createTableBody(category) {
        const tbody = document.createElement('tbody');
        
        if (category.platforms) {
            const tr = document.createElement('tr');
            tr.innerHTML = '<td>Status</td>';
            category.platforms.forEach(platform => {
                const workflowName = generateWorkflowName(category.workflowPrefix, platform);
                tr.appendChild(this.createStatusCell(workflowName));
            });
            tbody.appendChild(tr);
        } else {
            category.sources.forEach(source => {
                const tr = document.createElement('tr');
                tr.innerHTML = `<td>${source}</td>`;
                category.targets.forEach(target => {
                    const workflowName = generateWorkflowName(category.workflowPrefix, source, target);
                    tr.appendChild(this.createStatusCell(workflowName));
                });
                tbody.appendChild(tr);
            });
        }
        
        return tbody;
    }

    createStatusCell(workflowName) {
        const td = document.createElement('td');
        const iconName = getWorkflowStatus(this.workflowStatuses, workflowName);
        
        const onClick = () => {
            const status = {
                icon: iconName,
                color: STATUS_COLORS[iconName],
                text: STATUS_TEXT[iconName]
            };
            const { video: videoUrl, thumbnail: thumbnailUrl } = generateMediaUrls(workflowName);
            this.overlay.show(workflowName, status, videoUrl, thumbnailUrl);
        };
        
        td.appendChild(createStatusButton(iconName, onClick));
        return td;
    }
}
