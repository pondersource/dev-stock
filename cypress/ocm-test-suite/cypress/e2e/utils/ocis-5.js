export function openFilesAppV5() {
    getApplicationSwitcherV5()
    getApplicationV5('files')
}

export function openScienceMeshAppV5() {
    getApplicationSwitcherV5()
    getApplicationV5('ocm')
}

export function createInviteTokenV5() {
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

export function createLagacyInviteLinkV5(domain, providerDomain) {
    return createInviteTokenV5().then(
        (token) => {
          return `https://${domain}/index.php/apps/sciencemesh/accept?token=${token}&providerDomain=${providerDomain}`
        }
      )
}

export function acceptInviteLinkV5(token) {
    openScienceMeshAppV5()

    getScienceMeshAcceptInvitePartV5('label', 'token').within(() => {
        cy.get('input[type="text"]')
            .type(token)
    })

    getScienceMeshAcceptInvitePartV5('label', 'institution').within(() => {
        cy.get('div[class="vs__actions"').click()

        cy.get('ul[role="listbox"]').find('li').first().click()
    })

    getScienceMeshAcceptInvitePartV5('span', 'accept').click()
}

export function verifyFederatedContactV5(name, domain) {
    openScienceMeshAppV5()

    getFederatedContactRow(0).eq(0)
        .should('have.text', name)

    getFederatedContactRow(0).eq(2)
        .should('contain', domain)
}

export function createTextFileV5(filename, data) {
    cy.get('button[id="new-file-menu-btn"]')
        .scrollIntoView()
        .should('be.visible')
        .click()

    cy.get('div[id="new-file-menu-drop"]')
        .scrollIntoView()
        .should('be.visible')
        .find('ul[id="create-list"]')
        .find('span')
        .contains('txt')
        .parent()
        .click()

    cy.get('div[class="oc-modal-background"]')
        .scrollIntoView()
        .should('be.visible')
        .within(() => {
            cy.get('input[id="oc-textinput-10"]').clear()

            cy.get('input[id="oc-textinput-10"]').type(filename)

            cy.get('button')
                .contains('Create')
                .scrollIntoView()
                .should('be.visible')
                .click()
        })

    cy.get('textarea[id="text-editor-input"]')
        .scrollIntoView()
        .should('be.visible')
        .type(data)

    cy.get('button[id="app-save-action"]')
        .scrollIntoView()
        .should('be.visible')
        .click()
}

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

export function acceptShareV5(filename) {
    cy.get('div[id="web-nav-sidebar"]')
        .should('be.visible')
        .find('span')
        .contains('Shares')
        .click()

    cy.get(`span[data-test-resource-name="${CSS.escape(filename)}"]`)
        .scrollIntoView()
        .should('be.visible')

    cy.get(`span[data-test-resource-name="${CSS.escape(filename)}"]`)
        .parent()
        .parent()
        .parent()
        .parent()
        .parent()
        .parent().within(() => {
            cy.get('button[aria-label="Show context menu"]')
                .scrollIntoView()
                .should('be.visible')
                .click()

            cy.get('span')
                .contains('Enable sync')
                .scrollIntoView()
                .should('be.visible')
                .click()
        })
}

export function verifyShareV5(filename, owner, receiver) {
    cy.get('div[id="web-nav-sidebar"]')
        .should('be.visible')
        .find('span')
        .contains('Shares')
        .click()

    cy.get(`span[data-test-resource-name="${CSS.escape(filename)}"]`)
        .scrollIntoView()
        .should('be.visible')

    cy.get(`span[data-test-resource-name="${CSS.escape(filename)}"]`)
        .parent()
        .parent()
        .parent()
        .parent()
        .parent()
        .parent().within(() => {
            cy.get(`span[data-test-user-name="${CSS.escape(owner)}"]`).should('exist')
            cy.get(`div[data-test-item-name="${CSS.escape(receiver)}"]`).should('exist')
        })
}

export const getFederatedContactRow = (row) => cy.get('div[id="sciencemesh-connections"]')
    .get('table')
    .find('tbody>tr')
    .eq(row)
    .find('td')

export const getApplicationV5 = (appName) => getApplicationMenuV5()
    .find(`a[data-test-id="${CSS.escape(appName)}"]`)
    .should('be.visible')
    .click()

export const getApplicationSwitcherV5 = () => getApplicationMenuV5()
    .find('button[id="_appSwitcherButton"]')
    .should('be.visible')
    .click()

export const getApplicationMenuV5 = () => cy.get('nav[id="applications-menu"]').should('be.visible')

// possible partIds are:
// - token
// - institution
// - accept

export function getScienceMeshAcceptInvitePartV5(element, partId) {
    const partIdList = new Map([
        ['token', 'Enter invite token'],
        ['institution', 'Select institution of inviter'],
        ['accept', 'Accept invitation']
    ]);

    const partLabel = partIdList.get(partId) ?? partIdList.get('token');


    return cy.get('div[id="sciencemesh-accept-invites"]')
        .find(element)
        .contains(partLabel)
        .parent()
        .scrollIntoView()
        .should('be.visible')
}

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

    const actionAriaLabel = actionIdList.get(actionId) ?? actionIdList.get('share');

    getActionsForFileV5(filename)
        .find(`button[aria-label="${CSS.escape(actionAriaLabel)}"]`)
        .should('exist')
        .scrollIntoView()
        .should('be.visible')
        .click()
}

export const getActionsForFileV5 = (filename) => getRowForFileV5(filename)
    .find('*[class^="resource-table-actions"]')

// @MahdiBaghbani: Yes, I know this is horrible! :)
export const getRowForFileV5 = (filename) => cy.get(`[data-test-resource-name="${CSS.escape(filename)}"]`)
    .parent()
    .parent()
    .parent()
    .parent()
    .parent()
    .parent()
