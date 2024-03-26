export function acceptShareV28() {
	cy.get('div[class="oc-dialog"]', { timeout: 10000 })
      .should('be.visible')
      .find('*[class^="oc-dialog-buttonrow"]')
      .find('button[class="primary"]')
      .click()
}

export function createShareV28(fileName, username, domain) {
	openSharingPanelV28(fileName)

	cy.get('#app-sidebar-vue').within(() => {
		cy.get('#sharing-search-input').clear()
		cy.intercept({ times: 1, method: 'GET', url: '**/apps/files_sharing/api/v1/sharees?*' }).as('userSearch')
		cy.get('#sharing-search-input').type(username + '@' + domain)
		cy.wait('@userSearch')
	})

	// ensure selecting remote [sharetype="6"] instead of email!
	cy.get(`[user="${username}"]`).click()

	// cy.get('[data-cy-files-sharing-share-editor-action="save"]').click({ scrollBehavior: 'nearest' })
	cy.get('*[class^="sharingTabDetailsView"]').find('*[class^="sharingTabDetailsView__footer"]').find('*[class^="button-group"]').find('*[class^="button-vue button-vue--text-only button-vue--vue-primary"]').click()

	// HACK: Save the share and then update it, as permissions changes are currently not saved for new share.
	// updateShareV28(fileName, 0) // @MahdiBaghbani: not sure about this yet.
}

export function updateShareV28(fileName, index) {
	openSharingPanelV28(fileName)

	cy.get('#app-sidebar-vue').within(() => {
		cy.get('[data-cy-files-sharing-share-actions]').eq(index).click()
		cy.get('[data-cy-files-sharing-share-permissions-bundle="custom"]').click()

		cy.get('[data-cy-files-sharing-share-permissions-checkbox="download"]').find('input').as('downloadCheckbox')
		// Force:true because the checkbox is hidden by the pretty UI.
		cy.get('@downloadCheckbox').check({ force: true, scrollBehavior: 'nearest' })

		cy.get('[data-cy-files-sharing-share-permissions-checkbox="read"]').find('input').as('readCheckbox')
		// Force:true because the checkbox is hidden by the pretty UI.
		cy.get('@readCheckbox').check({ force: true, scrollBehavior: 'nearest' })

		cy.get('[data-cy-files-sharing-share-permissions-checkbox="update"]').find('input').as('updateCheckbox')
		// Force:true because the checkbox is hidden by the pretty UI.
		cy.get('@updateCheckbox').check({ force: true, scrollBehavior: 'nearest' })

		cy.get('[data-cy-files-sharing-share-permissions-checkbox="delete"]').find('input').as('deleteCheckbox')
		// Force:true because the checkbox is hidden by the pretty UI.
		cy.get('@deleteCheckbox').check({ force: true, scrollBehavior: 'nearest' })

		cy.get('[data-cy-files-sharing-share-editor-action="save"]').click({ scrollBehavior: 'nearest' })
	})
}

export const renameFileV28 = (fileName, newFileName) => {
	getRowForFileV28(fileName)
	triggerActionForFileV28(fileName, 'rename')

	// intercept the move so we can wait for it.
	cy.intercept('MOVE', /\/remote.php\/dav\/files\//).as('moveFile')
	getRowForFileV28(fileName).find('[data-cy-files-list-row-name] input').clear()
	getRowForFileV28(fileName).find('[data-cy-files-list-row-name] input').type(`${newFileName}{enter}`)
	cy.wait('@moveFile')
}

export function openSharingPanelV28(fileName) {
	triggerActionForFileV28(fileName, 'details')

	cy.get('#app-sidebar-vue')
		.get('[aria-controls="tab-sharing"]')
		.click()
}

export const triggerActionForFileV28 = (filename, actionId) => {
	getActionButtonForFileV28(filename).click()
	cy.get(`[data-cy-files-list-row-action="${CSS.escape(actionId)}"] > button`).should('exist').click()
}

export const getActionButtonForFileV28 = (filename) => getActionsForFileV28(filename).find('button[aria-label="Actions"]')

export const getActionsForFileV28 = (filename) => getRowForFileV28(filename).find('[data-cy-files-list-row-actions]')

export const getRowForFileV28 = (filename) => cy.get(`[data-cy-files-list-row-name="${CSS.escape(filename)}"]`)
