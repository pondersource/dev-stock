export const config = {
    manifestUrl: '/artifacts/manifest.json',
    categories: {
        'auth-tests': {
            id: 'auth-tests',
            title: 'Authentication Tests 🔐',
            description: 'Tests for user authentication across different platforms'
        },
        'share-link-tests': {
            id: 'share-link-tests',
            title: 'Public Link Sharing Tests 🔗',
            description: 'Tests for public link sharing functionality'
        },
        'share-with-tests': {
            id: 'share-with-tests',
            title: 'Direct User Sharing Tests 🤝',
            description: 'Tests for direct user-to-user sharing capabilities'
        },
        'sciencemesh-tests': {
            id: 'sciencemesh-tests',
            title: 'ScienceMesh Federation Tests 🌐',
            description: 'Tests for ScienceMesh federation features'
        }
    },
    platforms: [
        { id: 'nc-v27', name: 'Nextcloud v27' },
        { id: 'nc-v28', name: 'Nextcloud v28' },
        { id: 'oc-v10', name: 'ownCloud v10' },
        { id: 'ocis-v5', name: 'oCIS v5' },
        { id: 'sf-v11', name: 'Seafile v11' }
    ],
    features: [
        { id: 'auth', name: 'Authentication' },
        { id: 'share-link', name: 'Public Link Sharing' },
        { id: 'share-with', name: 'Direct User Sharing' },
        { id: 'invite-link', name: 'ScienceMesh Federation' }
    ]
};