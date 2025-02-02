export const STATUS_COLORS = {
    'check-circle': '#2ea44f',  // success (green)
    'times-circle': '#cb2431',  // failure (red)
    'sync-alt': '#dbab09',      // in progress (yellow)
    'file-excel': '#d73a49',    // workflow errored (red)
    'ban': '#6a737d',           // workflow cancelled (gray)
    'question-circle': '#6a737d' // unknown (gray)
};

export const STATUS_TEXT = {
    'check-circle': 'Tests Passing',
    'times-circle': 'Tests Failing',
    'sync-alt': 'Tests in Progress',
    'file-excel': 'Workflow Errored',
    'ban': 'Workflow Cancelled',
    'question-circle': 'Status Unknown'
};

export const WORKFLOW_CONCLUSIONS = {
    SUCCESS: 'success',
    FAILURE: 'failure',
    TIMED_OUT: 'timed_out',
    ACTION_REQUIRED: 'action_required',
    CANCELLED: 'cancelled'
};

export const STATUS_ICONS = {
    SUCCESS: 'check-circle',
    FAILURE: 'times-circle',
    IN_PROGRESS: 'sync-alt',
    ERROR: 'file-excel',
    CANCELLED: 'ban',
    UNKNOWN: 'question-circle'
}; 