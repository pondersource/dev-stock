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
	cy.get(`[user="${username}"]`).should('be.visible').click()
	cy.get('div[class="button-group"]').contains('Save share').should('be.visible').click()
}

export function createShareLinkV27(fileName) {
	openSharingPanelV27(fileName)

	return cy.window().then(win => {
		cy.stub(win.navigator.clipboard, 'writeText').as('copy');

		cy.get('#app-sidebar-vue').within(() => {
			cy.get('button[title="Create a new share link"]')
				.should('be.visible')
				.click()
		})

		return cy.get('@copy').should('have.been.calledOnce').then((spy) => {
			return (spy).lastCall.args[0];
		});
	})
}

export function createInviteTokenV27(senderDomain) {

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

export function createInviteLinkV27(targetDomain) {

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

export function verifyFederatedContactV27(domain, displayName, contactDomain) {
	cy.visit(`https://${domain}/index.php/apps/sciencemesh/contacts`)

	cy.get('table[id="contact-table"]')
		.find('p[class="displayname"]')
		.should("have.text", displayName)

	cy.get('table[id="contact-table"]')
		.find('p[class="displayname"]')
		.contains(displayName)
		.parent()
		.parent()
		.find('p[class="username-provider"]')
		.invoke('text')
		.then(
			usernameWithDomain => {
				const extractedDomain = usernameWithDomain.substring(
					usernameWithDomain.lastIndexOf("@") + 1, usernameWithDomain.length
				)

				expect(extractedDomain).equal(contactDomain);
			}
		)
}

export function getScienceMeshContactIdFromDisplayNameV27(domain, displayName, contactDomain) {
	verifyFederatedContactV27(domain, displayName, contactDomain)

	return cy.get('table[id="contact-table"]')
		.find('p[class="displayname"]')
		.contains(displayName)
		.parent()
		.parent()
		.find('p[class="username-provider"]')
		.invoke('text')
		.then(
			usernameWithDomain => {
				// get the index of the last @
				var lastIndex = usernameWithDomain.lastIndexOf('@');
				var username = usernameWithDomain.substr(0, lastIndex)
				var domain = usernameWithDomain.substr(lastIndex + 1)

				// remove https:// or http:// from domain (reva likes to show username@https://domain sometimes)
				// I'm too afraid to explain the regex here let's just say its from here: https://stackoverflow.com/a/8206299/8549230
				domain = domain.replace(/^\/\/|^.*?:(\/\/)?/, '');

				return username + '@' + domain
			}
		)
}

export function createScienceMeshShareV27(domain, displayName, contactDomain, filename) {
	getScienceMeshContactIdFromDisplayNameV27(domain, displayName, contactDomain).then(
		(shareWith) => {
			cy.visit(`https://${domain}/index.php/apps/files`)

			openSharingPanelV27(filename)

			cy.get('#app-sidebar-vue').within(() => {
				cy.get('#sharing-search-input').clear()
				cy.intercept({ times: 1, method: 'GET', url: '**/apps/files_sharing/api/v1/sharees?*' }).as('userSearch')
				cy.get('#sharing-search-input').type(displayName)
				cy.wait('@userSearch')
			})

			cy.get(`[sharewith="${shareWith}"]`)
				.eq(0)
				.should('be.visible')
				.click()

			cy.get('div[class="button-group"]')
				.contains('Save share')
				.should('be.visible')
				.click()
		}
	)
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
		.should('be.visible')
		.click()
}

// actionId possible values are:
// 1. Open navigation
// 2. Close navigation
export function navigationSwitchLeftSideV27(actionId) {
	cy.get('div[id="app-navigation-vue"]')
		.find(`button[aria-label="${CSS.escape(actionId)}"]`)
        .should('be.visible')
		.click()
}

// appId possible values are:
// 1. files
// 2. recent
// 3. favorites
// 4. shareoverview
// 5. systemtagsfilter
// 6. trashbin
export function selectAppFromLeftSideV27(appId) {
	cy.get('div[id="app-navigation-vue"]')
		.find(`li[data-cy-files-navigation-item="${CSS.escape(appId)}"]`)
        .should('be.visible')
		.click()
}

export function triggerActionInFileMenuV27(fileName, actionId) {
	triggerActionForFileV27(fileName, 'menu')
	getRowForFileV27(fileName).find('*[class^="filename"]').find('*[class^="fileActionsMenu"]').find(`[data-action="${CSS.escape(actionId)}"]`).should('be.visible').click()
}

export const triggerActionForFileV27 = (filename, actionId) => getActionsForFileV27(filename).find(`[data-action="${CSS.escape(actionId)}"]`).should('be.visible').click()

export const getActionsForFileV27 = (filename) => getRowForFileV27(filename).find('*[class^="filename"]').find('*[class^="name"]').find('*[class^="fileactions"]')

export const getRowForFileV27 = (filename) => cy.get(`[data-file="${CSS.escape(filename)}"]`)
