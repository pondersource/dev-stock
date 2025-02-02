import { STATUS_COLORS } from '../constants.js';
import { createStatusIcon } from '../utils.js';

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
    const icon = createStatusIcon(iconName, STATUS_COLORS[iconName]);
    button.appendChild(icon);
    if (onClick) {
        button.addEventListener('click', onClick);
    }
    return button;
}

export function createMatrixSection(category, tableContent) {
    const section = document.createElement('div');
    section.className = 'matrix-section';
    section.id = category.id;
    
    section.innerHTML = `
        <h3 class="matrix-subtitle">
            <i class="fas fa-${category.icon}"></i> ${category.title}
        </h3>
        <div class="matrix-scroll"></div>
    `;
    
    section.querySelector('.matrix-scroll').appendChild(tableContent);
    return section;
} 