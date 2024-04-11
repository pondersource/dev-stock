export function acceptShare() {
	cy.get('div[class="oc-dialog"]', { timeout: 10000 })
      .should('be.visible')
      .find('*[class^="oc-dialog-buttonrow"]')
      .find('button[class="primary"]')
      .click()
}

export function createShare(fileName, username, domain) {
	openSharingPanel(fileName)

	cy.get('#app-sidebar').within(() => {
		cy.get('*[id^="shareWith-"]').clear()
		cy.intercept({ times: 1, method: 'GET', url: '**/apps/files_sharing/api/v1/sharees?*' }).as('userSearch')
		cy.get('*[id^="shareWith-"]').type(username + '@' + domain)
		cy.wait('@userSearch')
	})

	// ensure selecting remote, instead of email or group.
	cy.get('*[class^=ui-autocomplete]')
		.contains('span[class="autocomplete-item-typeInfo"]', 'Federated')
		.click()

	// TODO: check if it has been shared before with same user or not! (or reset share on both ends on each run for better developer experience, right now I have to manually clean and restart)
}

export function createShareGroup(fileName, group) {
	openSharingPanel(fileName)

	cy.get('#app-sidebar').within(() => {
		cy.get('*[id^="shareWith-"]').clear()
		cy.intercept({ times: 1, method: 'GET', url: '**/apps/files_sharing/api/v1/sharees?*' }).as('userSearch')
		cy.get('*[id^="shareWith-"]').type(group)
		cy.wait('@userSearch')
	})

	// ensure selecting remote, instead of email or group.
	cy.get('*[class^=ui-autocomplete]')
		.contains('span[class="autocomplete-item-typeInfo"]', 'Group')
		.click()

	// TODO: check if it has been shared before with same user or not! (or reset share on both ends on each run for better developer experience, right now I have to manually clean and restart)
}

export function renameFile(fileName, newFileName) {
	triggerActionInFileMenu(fileName, 'Rename')

	// intercept the move so we can wait for it.
	cy.intercept('MOVE', /\/remote.php\/dav\/files\//).as('moveFile')
    getRowForFile(fileName).find('form').find('input').clear()
	getRowForFile(fileName).find('form').find('input').type(`${newFileName}{enter}`)
	cy.wait('@moveFile')
}

export function openSharingPanel(fileName) {
	triggerActionForFile(fileName, 'Share')

	cy.get('#app-sidebar')
		.get('[data-tabid="shareTabView"]')
		.click()
}

export function triggerActionInFileMenu (fileName, actionId) {
	triggerActionForFile(fileName,'menu')
	getRowForFile(fileName).find('*[class^="filename"]').find('*[class^="fileActionsMenu"]').find(`[data-action="${CSS.escape(actionId)}"]`).should('exist').click()
}

export const triggerActionForFile = (filename, actionId) => getActionsForFile(filename).find(`[data-action="${CSS.escape(actionId)}"]`).should('exist').click()

export const getActionsForFile = (filename) => getRowForFile(filename).find('*[class^="filename"]').find('*[class^="name"]').find('*[class^="fileactions"]')

export const getRowForFile = (filename) => cy.get(`[data-file="${CSS.escape(filename)}"]`)
