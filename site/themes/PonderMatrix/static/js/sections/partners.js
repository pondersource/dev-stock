export function initPartnersTabSwitching() {
    const tabs = document.querySelectorAll('.partners-tabs .tab');
    const collaboratorsGrid = document.getElementById('collaboratorsGrid');
    const sponsorsGrid = document.getElementById('sponsorsGrid');

    if (!tabs.length || !collaboratorsGrid || !sponsorsGrid) return;

    tabs.forEach(tab => {
        tab.addEventListener('click', function () {
            // Remove active class from all tabs
            tabs.forEach(t => t.classList.remove('active'));
            // Add active class to clicked tab
            this.classList.add('active');

            // Add switching class for fade effect
            collaboratorsGrid.classList.add('switching');
            sponsorsGrid.classList.add('switching');

            // Switch grids after fade out
            setTimeout(() => {
                if (this.dataset.tab === 'collaborators') {
                    collaboratorsGrid.classList.remove('hidden');
                    sponsorsGrid.classList.add('hidden');
                } else {
                    collaboratorsGrid.classList.add('hidden');
                    sponsorsGrid.classList.remove('hidden');
                }

                // Remove switching class for fade in
                setTimeout(() => {
                    collaboratorsGrid.classList.remove('switching');
                    sponsorsGrid.classList.remove('switching');
                }, 50);
            }, 300);
        });
    });
}
