export function createShareV5(filename, username) {
    triggerActionForFileV5(filename, 'share')

	cy.get('div[id="oc-files-sharing-sidebar"]').within(() => {
		cy.get('input[id="files-share-invite-input"]').clear()
        cy.intercept({ times: 1, method: 'GET', url: '**/apps/files_sharing/api/v1/sharees?*' }).as('userSearch')
		cy.get('input[id="files-share-invite-input"]').type(username)
		cy.wait('@userSearch')
	})

    cy.get('div[id="oc-files-sharing-sidebar"]').within(() => {
		cy.get('ul[role="listbox"]')
            .find('span')
            .contains('(Federated)')
            .scrollIntoView()
            .should('be.visible')
            .click()
	})

    cy.get('div[id="oc-files-sharing-sidebar"]').within(() => {
		cy.get('button[id="new-collaborators-form-create-button"]')
            .scrollIntoView()
            .should('be.visible')
            .click()
	})
}

export function createInviteLinkV5() {
    cy.get('div[id="sciencemesh-invite"]')
      .get('span')
      .contains('Generate invitation')
      .parent()
      .scrollIntoView()
      .should('be.visible')
      .click()

      cy.get('div[id="sciencemesh-invite"]')
      .get('div[role="dialog"]').within(() => {
          cy.get('button')
          .contains('Generate')
          .scrollIntoView()
          .should('be.visible')
          .click()
      })

    // we want to make sure that code is created and is displayed on the table.
    return cy.get('div[id="sciencemesh-invite"]')
        .get('table')
        .find('tbody>tr')
        .eq(0)
        .scrollIntoView()
        .should('be.visible')
        .invoke('attr', 'data-item-id')
        .then(
            sometext => {
            return sometext
            }
        )
}

export function openFilesAppV5() {
    getApplicationSwitcherV5()
    getApplicationV5('files')
}

export function openScienceMeshAppV5() {
    getApplicationSwitcherV5()
    getApplicationV5('ocm')
}

export const getApplicationV5 = (appName) => getApplicationMenuV5()
                                                .find(`a[data-test-id="${CSS.escape(appName)}"]`)
                                                .should('be.visible')
                                                .click()
 
export const getApplicationSwitcherV5 = () => getApplicationMenuV5()
                                                .find('button[id="_appSwitcherButton"]')
                                                .should('be.visible')
                                                .click()

export const getApplicationMenuV5 = () => cy.get('nav[id="applications-menu"]').should('be.visible')

// possible actionIds are:
// - share
// - copyLink
// - contextMenu
export function triggerActionForFileV5(filename, actionId) {
    const actionIdList = new Map([
        ['share', 'Share'],
        ['copyLink', 'Copy link'],
        ['contextMenu', 'Show context menu'],
    ]);

    const actionAriaLabel = actionIdList.get(actionId) ?? 'Share';

    getActionsForFileV5(filename)
        .find(`button[aria-label="${CSS.escape(actionAriaLabel)}"]`)
        .should('exist')
        .scrollIntoView()
        .should('be.visible')
        .click()
}

export const getActionsForFileV5 = (filename) => getRowForFileV5(filename)
                                                    .find('*[class^="resource-table-actions"]')

export const getRowForFileV5 = (filename) => cy.get(`[data-test-resource-name="${CSS.escape(filename)}"]`)
                                                .parent()
                                                .parent()
                                                .parent()
                                                .parent()
                                                .parent()
                                                .parent()
