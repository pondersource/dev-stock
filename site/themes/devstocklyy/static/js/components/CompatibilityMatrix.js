import { config } from '/js/config.js';

export class CompatibilityMatrix {
    constructor() {
        this.matrixContainer = document.getElementById('compatibilityMatrix');
        this.workflowStatuses = null;
        this.testCategories = [
            {
                id: 'auth-tests',
                title: 'Authentication Tests',
                icon: 'fingerprint',
                platforms: [
                    'Nextcloud v27.1.11',
                    'Nextcloud v28.0.14',
                    'oCIS v5.0.9',
                    'OcmStub v1.0.0',
                    'ownCloud v10.15.0',
                    'Seafile v11.0.5'
                ],
                workflowPrefix: 'login-'
            },
            {
                id: 'link-tests',
                title: 'Public Link Sharing',
                icon: 'link',
                sources: ['Nextcloud v27.1.11', 'Nextcloud v28.0.14', 'ownCloud v10.15.0'],
                targets: ['Nextcloud v27.1.11', 'Nextcloud v28.0.14', 'ownCloud v10.0.0'],
                workflowPrefix: 'share-link-'
            },
            {
                id: 'user-tests',
                title: 'Direct User Sharing',
                icon: 'user-friends',
                sources: ['Nextcloud v27.1.11', 'Nextcloud v28.0.14', 'OcmStub v1.0.0', 'ownCloud v10.15.0', 'Seafile v11.0.5'],
                targets: ['Nextcloud v27.1.11', 'Nextcloud v28.0.14', 'OcmStub v1.0.0', 'ownCloud v10.15.0', 'Seafile v11.0.5'],
                workflowPrefix: 'share-with-'
            },
            {
                id: 'federation-tests',
                title: 'ScienceMesh Federation',
                icon: 'network-wired',
                sources: ['Nextcloud v27.1.11 (ScienceMesh)', 'oCIS v5.0.9', 'ownCloud v10.15.0 (ScienceMesh)'],
                targets: ['Nextcloud v27.1.11 (ScienceMesh)', 'oCIS v5.0.9', 'ownCloud v10.15.0 (ScienceMesh)'],
                workflowPrefix: 'invite-link-'
            }
        ];
    }

    async init() {
        try {
            const response = await fetch('/artifacts/workflow-status.json');
            if (!response.ok) {
                if (response.status === 404) {
                    console.error('Workflow status file not found');
                    this.workflowStatuses = null;
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
        await this.init();  // Load statuses first
        this.addStatusLegend();
        this.testCategories.forEach(category => {
            const section = this.createSectionElement(category);
            this.matrixContainer.appendChild(section);
        });
    }

    createSectionElement(category) {
        const section = document.createElement('div');
        section.className = 'matrix-section';
        section.id = category.id;
        
        section.innerHTML = `
            <h3 class="matrix-subtitle">
                <i class="fas fa-${category.icon}"></i> ${category.title}
            </h3>
            <div class="matrix-scroll"></div>
        `;

        const table = this.createTable(category);
        section.querySelector('.matrix-scroll').appendChild(table);
        return section;
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
            // Header row for Authentication Tests: one header for the label then one for each platform
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
                const workflowName = this.generateWorkflowName(category.workflowPrefix, platform);
                tr.appendChild(this.createStatusCell(workflowName));
            });
            
            tbody.appendChild(tr);
        } else {
            category.sources.forEach(source => {
                const tr = document.createElement('tr');
                tr.innerHTML = `<td>${source}</td>`;
                
                category.targets.forEach(target => {
                    const workflowName = this.generateWorkflowName(category.workflowPrefix, source, target);
                    tr.appendChild(this.createStatusCell(workflowName));
                });

                tbody.appendChild(tr);
            });
        }

        return tbody;
    }

    generateWorkflowName(prefix, source, target) {
        const platformMap = {
            'Nextcloud v27.1.11': 'nc-v27',
            'Nextcloud v28.0.14': 'nc-v28',
            'ownCloud v10.15.0': 'oc-v10',
            'OcmStub v1.0.0': 'os-v1',
            'Seafile v11.0.5': 'sf-v11',
            'Nextcloud v27.1.11 (ScienceMesh)': 'nc-sm-v27',
            'ownCloud v10.15.0 (ScienceMesh)': 'oc-sm-v10',
            'oCIS v5.0.9': 'ocis-v5'
        };

        if (!target) {
            return `${prefix}${platformMap[source] || source}`;
        }

        const sourceKey = platformMap[source] || source;
        const targetKey = platformMap[target] || target;
        return `${prefix}${sourceKey}-${targetKey}`;
    }

    createStatusCell(workflowName) {
        const td = document.createElement('td');
        const link = document.createElement('a');
        link.href = `https://github.com/pondersource/dev-stock/actions/workflows/${workflowName}.yml`;
        link.target = '_blank';
        
        // Placeholder spinner icon (no hover transform)
        const iconEl = document.createElement('i');
        iconEl.className = 'fas fa-spinner fa-spin';
        link.appendChild(iconEl);
        td.appendChild(link);
        
        // Fetch the workflow status and update the icon with color
        const iconName = this.getWorkflowStatus(workflowName);
        const statusColors = {
            'check-circle': '#2ea44f',             // success (green)
            'times-circle': '#cb2431',             // failure (red)
            'sync-alt': '#dbab09',                 // in progress (yellow)
            'file-excel': '#d73a49',               // workflow errored (red)
            'ban': '#6a737d',                      // workflow cancelled (gray)
            'question-circle': '#6a737d'            // unknown (gray)
        };
        iconEl.className = `fas fa-${iconName}`;
        iconEl.style.color = statusColors[iconName] || '#6a737d';
        iconEl.setAttribute('title', `Workflow ${workflowName}`);
        
        return td;
    }

    getWorkflowStatus(workflowName) {
        const workflow = `${workflowName}.yml`;
        
        // Check if we have status data at all
        if (!this.workflowStatuses) {
            return 'question-circle';  // Status file not found or error loading
        }

        const status = this.workflowStatuses[workflow];
        
        if (!status) {
            return 'question-circle';
        }
        
        if (status.status !== 'completed') {
            return 'sync-alt';
        }
        
        switch (status.conclusion) {
            case 'success': return 'check-circle';
            case 'failure':
            case 'timed_out': return 'times-circle';
            case 'action_required':
            case 'failure': return 'file-excel';
            case 'cancelled': return 'ban';
            default: return 'question-circle';
        }
    }

    addStatusLegend() {
        const legend = document.createElement('div');
        legend.className = 'status-legend';
        
        legend.innerHTML = `
            <div class="legend-item">
                <i class="fas fa-check-circle" style="color: #2ea44f;"></i> Tests passing
            </div>
            <div class="legend-item">
                <i class="fas fa-times-circle" style="color: #cb2431;"></i> Tests failing
            </div>
            <div class="legend-item">
                <i class="fas fa-sync-alt" style="color: #dbab09;"></i> Tests in progress
            </div>
            <div class="legend-item">
                <i class="fas fa-file-excel" style="color: #d73a49;"></i> Workflow errored
            </div>
            <div class="legend-item">
                <i class="fas fa-ban" style="color: #6a737d;"></i> Workflow cancelled
            </div>
            <div class="legend-item">
                <i class="fas fa-question-circle" style="color: #6a737d;"></i> Status unknown
            </div>
        `;

        // Insert the legend at the top of the matrix container
        this.matrixContainer.insertBefore(legend, this.matrixContainer.firstChild);
    }
}
