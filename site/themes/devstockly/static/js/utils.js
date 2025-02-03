import { config } from './config.js';
import { STATUS_ICONS, WORKFLOW_CONCLUSIONS } from './constants.js';

export function generateWorkflowName(prefix, source, target) {
    if (!target) {
        return `${prefix}${config.platformMap[source] || source}`;
    }
    const sourceKey = config.platformMap[source] || source;
    const targetKey = config.platformMap[target] || target;
    return `${prefix}${sourceKey}-${targetKey}`;
}

export function getWorkflowStatus(workflowStatuses, workflowName) {
    const workflowFile = `${workflowName}.yml`;
    
    if (!workflowStatuses) {
        return STATUS_ICONS.UNKNOWN;
    }
    
    const status = workflowStatuses[workflowFile];
    if (!status) {
        return STATUS_ICONS.UNKNOWN;
    }
    
    if (status.status !== 'completed') {
        return STATUS_ICONS.IN_PROGRESS;
    }
    
    switch (status.conclusion) {
        case WORKFLOW_CONCLUSIONS.SUCCESS:
            return STATUS_ICONS.SUCCESS;
        case WORKFLOW_CONCLUSIONS.FAILURE:
        case WORKFLOW_CONCLUSIONS.TIMED_OUT:
            return STATUS_ICONS.FAILURE;
        case WORKFLOW_CONCLUSIONS.ACTION_REQUIRED:
            return STATUS_ICONS.ERROR;
        case WORKFLOW_CONCLUSIONS.CANCELLED:
            return STATUS_ICONS.CANCELLED;
        default:
            return STATUS_ICONS.UNKNOWN;
    }
}

export function createStatusIcon(iconName, color) {
    const icon = document.createElement('i');
    icon.className = `fas fa-${iconName}`;
    if (color) {
        icon.style.color = color;
    }
    return icon;
}

export function generateMediaUrls(workflowName) {
    return {
        video: `./artifacts/${workflowName}/recording.webm`,
        thumbnail: `./artifacts/${workflowName}/recording.${config.thumbnailExtension}`
    };
} 