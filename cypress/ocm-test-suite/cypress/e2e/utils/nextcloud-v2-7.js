export function acceptShareV2_7() {
	cy.get('div[class="oc-dialog"]', { timeout: 10000 })
      .should('be.visible')
      .find('*[id^="oc-dialog-buttonrow"]')
      .find('button[class="primary"]')
      .click()
}

export function createShareV2_7(fileName, username, domain) {
	openSharingPanel(fileName)

	cy.get('#app-sidebar-vue').within(() => {
		cy.get('#sharing-search-input').clear()
		cy.intercept({ times: 1, method: 'GET', url: '**/apps/files_sharing/api/v1/sharees?*' }).as('userSearch')
		cy.get('#sharing-search-input').type(username + '@' + domain)
		cy.wait('@userSearch')
	})

	// ensure selecting remote [sharetype="6"] instead of email!
	cy.get(`[user="${username}"]`).click()
	cy.get('div[class="button-group"]').contains('Save share').click()

	// TODO: check if it has been shared before with same user or not! (or reset share on both ends on each run for better developer experience, right now I have to manually clean and restart)
}

export function openSharingPanel(fileName) {
	triggerActionForFile(fileName, 'Share')

	cy.get('#app-sidebar-vue')
		.get('[aria-controls="tab-sharing"]')
		.click()
}


export const triggerActionForFile = (filename, actionId) => getActionsForFile(filename).find(`[data-action="${CSS.escape(actionId)}"]`).should('exist').click()

export const getActionsForFile = (filename) => getRowForFile(filename).find('*[class^="filename"]').find('*[class^="name"]').find('*[class^="fileactions"]')

export const getRowForFile = (filename) => cy.get(`[data-file="${CSS.escape(filename)}"]`)
