import { STATUS_COLORS } from '../constants.js';
import { createStatusIcon } from '../utils.js';

// Helper function to get pure platform name
function getPurePlatformName(platform) {
    // Remove version and any parenthetical content
    const name = platform
        .split(' v')[0]               // Remove version
        .split(' (')[0]               // Remove anything in parentheses
        .trim();                      // Clean up whitespace

    // Special case for oCIS to preserve casing
    if (name.toLowerCase() === 'ocis') {
        return 'oCIS';
    }

    return name;
}

// Helper function to get platform image name
function getPlatformImageName(platform) {
    const pureName = getPurePlatformName(platform).toLowerCase();

    switch (pureName) {
        case 'ocis':
            return 'ocis.png';
        case 'ocmstub':
            return 'ocmstub.jpeg';
        default:
            return `${pureName}.svg`;
    }
}

export function createStatusLegend() {
    const legend = document.createElement('div');
    legend.className = 'status-legend';

    const items = [
        { icon: 'check-circle', text: 'Tests passing' },
        { icon: 'times-circle', text: 'Tests failing' },
        { icon: 'sync-alt', text: 'Tests in progress' },
        { icon: 'file-excel', text: 'Workflow errored' },
        { icon: 'ban', text: 'Workflow cancelled' },
        { icon: 'question-circle', text: 'Status unknown' }
    ];

    legend.innerHTML = items.map(item => `
        <div class="legend-item">
            <i class="fas fa-${item.icon}" style="color: ${STATUS_COLORS[item.icon]};"></i>
            ${item.text}
        </div>
    `).join('');

    return legend;
}

export function createStatusButton(iconName, onClick) {
    const button = document.createElement('button');
    button.className = 'status-button';
    button.setAttribute('title', 'Click to view details');
    const icon = createStatusIcon(iconName, STATUS_COLORS[iconName]);
    button.appendChild(icon);

    if (onClick) {
        button.addEventListener('click', onClick);

        // Add hover effect
        button.addEventListener('mouseenter', () => {
            button.style.transform = 'scale(1.1)';
            icon.style.transition = 'all 0.2s ease';
        });

        button.addEventListener('mouseleave', () => {
            button.style.transform = 'scale(1)';
        });
    }

    return button;
}

export function createMatrixSection(category, tableContent) {
    const section = document.createElement('div');
    section.className = 'matrix-section';
    section.id = category.id;

    const header = document.createElement('div');
    header.className = 'matrix-section-header';
    header.innerHTML = `
        <h3 class="matrix-subtitle">
            <i class="fas fa-${category.icon}"></i>
            ${category.title}
        </h3>
    `;

    const tableWrapper = document.createElement('div');
    tableWrapper.className = 'matrix-scroll';
    tableWrapper.appendChild(tableContent);

    section.appendChild(header);
    section.appendChild(tableWrapper);

    return section;
}

export function createMatrixTable(data, options = {}) {
    const table = document.createElement('table');
    table.className = 'compatibility-table';

    // Add table header
    const thead = document.createElement('thead');
    const headerRow = document.createElement('tr');

    // Add corner header cell
    const cornerHeader = document.createElement('th');
    cornerHeader.className = 'corner-header';
    cornerHeader.textContent = options.cornerText || 'Source ➜ Target';
    headerRow.appendChild(cornerHeader);

    // Add platform headers
    data.platforms.forEach(platform => {
        const th = document.createElement('th');
        th.className = 'platform-header';
        const pureName = getPurePlatformName(platform);
        const imageName = getPlatformImageName(platform);

        th.innerHTML = `
            <div class="platform-header-content">
                <img src="./images/platforms/${imageName}" alt="${pureName} Logo">
                <span>${platform}</span>
            </div>
        `;
        headerRow.appendChild(th);
    });

    thead.appendChild(headerRow);
    table.appendChild(thead);

    // Add table body
    const tbody = document.createElement('tbody');
    data.tests.forEach(row => {
        const tr = document.createElement('tr');

        // Add row header
        const rowHeader = document.createElement('td');
        rowHeader.className = 'row-header';
        const pureName = getPurePlatformName(row.source);
        const imageName = getPlatformImageName(row.source);

        rowHeader.innerHTML = `
            <div class="platform-header-content">
                <img src="./images/platforms/${imageName}" alt="${pureName} Logo">
                <span>${row.source}</span>
            </div>
        `;
        tr.appendChild(rowHeader);

        // Add status cells
        row.results.forEach(result => {
            const td = document.createElement('td');
            td.className = 'status-cell';
            td.appendChild(createStatusButton(result.status, () => {
                if (options.onCellClick) {
                    options.onCellClick(result);
                }
            }));
            tr.appendChild(td);
        });

        tbody.appendChild(tr);
    });

    table.appendChild(tbody);
    return table;
}
