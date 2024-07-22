export function acceptShareV27() {
	cy.get('div[class="oc-dialog"]', { timeout: 10000 })
      .should('be.visible')
      .find('*[class^="oc-dialog-buttonrow"]')
      .find('button[class="primary"]')
      .click()
}

export function createShareV27(fileName, username, domain) {
	openSharingPanelV27(fileName)

	cy.get('#app-sidebar-vue').within(() => {
		cy.get('#sharing-search-input').clear()
		cy.intercept({ times: 1, method: 'GET', url: '**/apps/files_sharing/api/v1/sharees?*' }).as('userSearch')
		cy.get('#sharing-search-input').type(username + '@' + domain)
		cy.wait('@userSearch')
	})

	// ensure selecting remote [sharetype="6"] instead of email!
	cy.get(`[user="${username}"]`).click()
	cy.get('div[class="button-group"]').contains('Save share').click()
}

export function createShareLinkV27(fileName) {
	openSharingPanelV27(fileName)

	return cy.window().then(win => {
        cy.stub(win.navigator.clipboard, 'writeText').as('copy');

        cy.get('#app-sidebar-vue').within(() => {
			cy.get('*[class^="sharing-entry__actions"]').eq(0).click()
		})

        return cy.get('@copy').should('have.been.calledOnce').then((spy) => {
            return (spy).lastCall.args[0];
        });
    })
}

export function createInviteLinkV27(targetDomain) {

	cy.get('button[id="token-generator"]').click()

	return cy.get('input[class="generated-token-link"]')
		.invoke('val')
		.then(
			sometext => {
				// extract token from url.
				const token = sometext.replace('https://meshdir.docker/meshdir?','');

				// put target efss domain and token together.
				const inviteLink = `${targetDomain}/index.php/apps/sciencemesh/accept?${token}`
      
				return inviteLink
			}
		);
}

export function createScienceMeshShareV27(fileName, username) {
	openSharingPanelV27(fileName)

	cy.get('#app-sidebar-vue').within(() => {
		cy.get('#sharing-search-input').clear()
		cy.intercept({ times: 1, method: 'GET', url: '**/apps/files_sharing/api/v1/sharees?*' }).as('userSearch')
		cy.get('#sharing-search-input').type(username)
		cy.wait('@userSearch')
	})

	cy.get(`[user="${username}"]`).click()
	cy.get('div[class="button-group"]').contains('Save share').click()
}


export function renameFileV27(fileName, newFileName) {
	triggerActionInFileMenuV27(fileName, 'Rename')

	// intercept the move so we can wait for it.
	cy.intercept('MOVE', /\/remote.php\/dav\/files\//).as('moveFile')
    getRowForFileV27(fileName).find('form').find('input').clear()
	getRowForFileV27(fileName).find('form').find('input').type(`${newFileName}{enter}`)
	cy.wait('@moveFile')
}

export function openSharingPanelV27(fileName) {
	triggerActionForFileV27(fileName, 'Share')

	cy.get('#app-sidebar-vue')
		.get('[aria-controls="tab-sharing"]')
		.click()
}

export function triggerActionInFileMenuV27 (fileName, actionId) {
	triggerActionForFileV27(fileName,'menu')
	getRowForFileV27(fileName).find('*[class^="filename"]').find('*[class^="fileActionsMenu"]').find(`[data-action="${CSS.escape(actionId)}"]`).should('exist').click()
}

export const triggerActionForFileV27 = (filename, actionId) => getActionsForFileV27(filename).find(`[data-action="${CSS.escape(actionId)}"]`).should('exist').click()

export const getActionsForFileV27 = (filename) => getRowForFileV27(filename).find('*[class^="filename"]').find('*[class^="name"]').find('*[class^="fileactions"]')

export const getRowForFileV27 = (filename) => cy.get(`[data-file="${CSS.escape(filename)}"]`)
