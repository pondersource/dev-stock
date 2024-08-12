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
		.should('be.visible')
		.click()
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
		.should('be.visible')
		.click()
}

export function createShareLink(fileName) {
	openSharingPanel(fileName)

	cy.get('#app-sidebar').get('li').contains('Public Links').click();
	cy.get('#app-sidebar').get('button').contains('Create public link').click();

	cy.get('div[class="oc-dialog"]', { timeout: 10000 })
		.should('be.visible')
		.find('*[class^="oc-dialog-buttonrow"]')
		.find('button[class="primary"]')
		.should('be.visible')
		.click()

	return cy.get('*[data-original-title^="Copy to clipboard"]')
		.parent()
		.find('*[class^="minify"]')
		.find('input')
		.invoke('val')
		.then(
			sometext => {
				return sometext
			}
		);
}

export function createInviteToken(senderDomain) {

	cy.get('button[id="token-generator"]').should('be.visible').click()

	return cy.get('input[class="generated-token-link"]')
		.invoke('val')
		.then(
			sometext => {
				// extract token from url.
				const token = sometext.replace('https://meshdir.docker/meshdir?token=', '');
      
				return token.replace(`&providerDomain=${senderDomain}`, '')
			}
		);
}

export function createInviteLink(targetDomain) {

	cy.get('button[id="token-generator"]').should('be.visible').click()

	return cy.get('input[class="generated-token-link"]')
		.invoke('val')
		.then(
			sometext => {
				// extract token from url.
				const token = sometext.replace('https://meshdir.docker/meshdir?', '');

				// put target efss domain and token together.
				const inviteLink = `${targetDomain}/index.php/apps/sciencemesh/accept?${token}`
      
				return inviteLink
			}
		);
}

export function createScienceMeshShare(fileName, username, domain) {
	openSharingPanel(fileName)

	cy.get('#app-sidebar').within(() => {
		cy.get('*[id^="shareWith-"]').clear()
		cy.intercept({ times: 1, method: 'GET', url: '**/apps/files_sharing/api/v1/sharees?*' }).as('userSearch')
		cy.get('*[id^="shareWith-"]').type(username + '@' + domain)
		cy.wait('@userSearch')
	})

	// ensure selecting ScienceMesh.
	cy.get('*[class^=ui-autocomplete]')
		.contains('span[class="autocomplete-item-typeInfo"]', 'Federated')
		.should('be.visible', { timeout: 10000 })
		.click()
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
		.should('be.visible')
		.click()
}

export function triggerActionInFileMenu (fileName, actionId) {
	triggerActionForFile(fileName,'menu')
	getRowForFile(fileName).find('*[class^="filename"]').find('*[class^="fileActionsMenu"]').find(`[data-action="${CSS.escape(actionId)}"]`).should('be.visible').click()
}

export const triggerActionForFile = (filename, actionId) => getActionsForFile(filename).find(`[data-action="${CSS.escape(actionId)}"]`).should('be.visible').as('action-btn').click()

export const getActionsForFile = (filename) => getRowForFile(filename).find('*[class^="filename"]').find('*[class^="name"]').find('*[class^="fileactions"]').should('be.visible')

export const getRowForFile = (filename) => cy.get(`[data-file="${CSS.escape(filename)}"]`)
