import { config } from '/js/config.js';

export class CompatibilityMatrix {
    constructor(videos) {
        this.videos = videos;
        this.authMatrix = document.querySelector('.auth-matrix tbody');
        this.publicLinkMatrix = document.querySelector('.public-link-matrix tbody');
        this.directShareMatrix = document.querySelector('.direct-share-matrix tbody');
        this.scienceMeshMatrix = document.querySelector('.sciencemesh-matrix tbody');
    }

    async render() {
        await Promise.all([
            this.renderAuthenticationTests(),
            this.renderPublicLinkTests(),
            this.renderDirectUserTests(),
            this.renderScienceMeshTests()
        ]);
    }

    createCell(workflowName, label, isUnsupported = false) {
        const cell = document.createElement('td');
        
        if (isUnsupported) {
            const badge = document.createElement('img');
            badge.src = 'https://img.shields.io/badge/Unsupported-red?style=flat-square';
            badge.alt = 'Unsupported';
            cell.appendChild(badge);
            return cell;
        }
        
        const link = document.createElement('a');
        link.href = `https://github.com/pondersource/dev-stock/actions/workflows/${workflowName}.yml`;
        link.target = '_blank';
        
        const badge = document.createElement('img');
        badge.src = `https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/${workflowName}.yml?branch=main&style=flat-square&label=${label}`;
        badge.alt = label;
        
        link.appendChild(badge);
        cell.appendChild(link);
        return cell;
    }

    renderAuthenticationTests() {
        const row = document.createElement('tr');
        row.innerHTML = '<td><strong>Status</strong></td>';
        
        const platforms = [
            { id: 'nc-v27', workflow: 'login-nextcloud-v27' },
            { id: 'nc-v28', workflow: 'login-nextcloud-v28' },
            { id: 'ocis-v5', workflow: 'login-ocis-v5' },
            { id: 'os-v1', workflow: 'login-ocmstub-v1' },
            { id: 'oc-v10', workflow: 'login-owncloud-v10' },
            { id: 'sf-v11', workflow: 'login-seafile-v11' }
        ];
        
        for (const platform of platforms) {
            row.appendChild(this.createCell(platform.workflow, 'Auth'));
        }
        
        this.authMatrix.appendChild(row);
    }

    renderPublicLinkTests() {
        const sourcePlatforms = ['nc-v27', 'nc-v28', 'oc-v10'];
        
        for (const source of sourcePlatforms) {
            const row = document.createElement('tr');
            row.innerHTML = `<td><strong>${this.getPlatformLabel(source)}</strong></td>`;
            
            for (const target of sourcePlatforms) {
                const workflowName = `share-link-${source}-${target}`;
                row.appendChild(this.createCell(workflowName, 'Link'));
            }
            
            this.publicLinkMatrix.appendChild(row);
        }
    }

    renderDirectUserTests() {
        const sourcePlatforms = ['nc-v27', 'nc-v28', 'os-v1', 'oc-v10', 'sf-v11'];
        const targetPlatforms = ['nc-v27', 'nc-v28', 'os-v1', 'oc-v10', 'sf-v11'];
        
        for (const source of sourcePlatforms) {
            const row = document.createElement('tr');
            row.innerHTML = `<td><strong>${this.getPlatformLabel(source)}</strong></td>`;
            
            for (const target of targetPlatforms) {
                if (this.isUnsupportedCombination(source, target)) {
                    row.appendChild(this.createCell('', '', true));
                } else {
                    const workflowName = `share-with-${source}-${target}`;
                    row.appendChild(this.createCell(workflowName, 'Share'));
                }
            }
            
            this.directShareMatrix.appendChild(row);
        }
    }

    renderScienceMeshTests() {
        const platforms = ['nc-sm-v27', 'ocis-v5', 'oc-sm-v10'];
        
        for (const source of platforms) {
            const row = document.createElement('tr');
            row.innerHTML = `<td><strong>${this.getPlatformLabel(source)}</strong></td>`;
            
            for (const target of platforms) {
                const workflowName = `invite-link-${source}-${target}`;
                row.appendChild(this.createCell(workflowName, 'ScienceMesh'));
            }
            
            this.scienceMeshMatrix.appendChild(row);
        }
    }

    getPlatformLabel(platform) {
        const labels = {
            'nc-v27': 'Nextcloud v27.1.11',
            'nc-v28': 'Nextcloud v28.0.14',
            'os-v1': 'OcmStub v1.0.0',
            'oc-v10': 'ownCloud v10.15.0',
            'sf-v11': 'Seafile v11.0.5',
            'nc-sm-v27': 'Nextcloud v27.1.11 with ScienceMesh',
            'ocis-v5': 'oCIS v5.0.9',
            'oc-sm-v10': 'ownCloud v10.15.0 with ScienceMesh'
        };
        return labels[platform] || platform;
    }

    isUnsupportedCombination(source, target) {
        if (source === 'sf-v11' && target !== 'sf-v11') return true;
        if (target === 'sf-v11' && source !== 'sf-v11') return true;
        return false;
    }
}
