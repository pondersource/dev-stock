export const platform = 'ocis';
export const version  = 'v5';


export function openFilesApp() {
    getApplicationSwitcher()
    getApplication('files')
}

export function openScienceMeshApp() {
    getApplicationSwitcher()
    getApplication('ocm')
}

export function createInviteToken() {
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

export function createLegacyInviteLink(domain, providerDomain) {
    return createInviteToken().then(
        (token) => {
          return `https://${domain}/index.php/apps/sciencemesh/accept?token=${token}&providerDomain=${providerDomain}`
        }
      )
}

export function acceptInviteLink(token) {
    openScienceMeshApp()

    // Log the token for debugging
    cy.log('Attempting to use token:', token)

    getScienceMeshAcceptInvitePart('label', 'token').within(() => {
        cy.get('input[type="text"]')
            .clear()  // Clear any existing value
            .type(token, { delay: 100 })  // Type slower to ensure input
            .should('have.value', token)  // Verify the value is actually set
    })

    // Wait a bit after token verification
    cy.wait(1000)

    getScienceMeshAcceptInvitePart('label', 'institution').within(() => {
        cy.get('div[class="vs__actions"').should('be.visible').click()

        cy.get('ul[role="listbox"]').find('li').first().should('be.visible').click()
    })

    // Wait for button to be enabled after valid input
    getScienceMeshAcceptInvitePart('span', 'accept')
        .should('not.be.disabled')
        .click()
}

export function verifyFederatedContact(name, domain) {
    openScienceMeshApp()

    getFederatedContactRow(0).eq(0)
        .should('have.text', name)

    getFederatedContactRow(0).eq(2)
        .should('contain', domain)
}

export function createTextFile(filename, data) {
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

export function createShare(filename, username) {
    triggerActionForFile(filename, 'share')

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

export function acceptShare(filename) {
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

export function verifyShare(filename, owner, receiver) {
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

export const getApplication = (appName) => getApplicationMenu()
    .find(`a[data-test-id="${CSS.escape(appName)}"]`)
    .should('be.visible')
    .click()

export const getApplicationSwitcher = () => getApplicationMenu()
    .find('button[id="_appSwitcherButton"]')
    .should('be.visible')
    .click()

export const getApplicationMenu = () => cy.get('nav[id="applications-menu"]').should('be.visible')

// possible partIds are:
// - token
// - institution
// - accept

export function getScienceMeshAcceptInvitePart(element, partId) {
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
export function triggerActionForFile(filename, actionId) {
    const actionIdList = new Map([
        ['share', 'Share'],
        ['copyLink', 'Copy link'],
        ['contextMenu', 'Show context menu'],
    ]);

    const actionAriaLabel = actionIdList.get(actionId) ?? actionIdList.get('share');

    getActionsForFile(filename)
        .find(`button[aria-label="${CSS.escape(actionAriaLabel)}"]`)
        .should('exist')
        .scrollIntoView()
        .should('be.visible')
        .click()
}

export const getActionsForFile = (filename) => getRowForFile(filename)
    .find('*[class^="resource-table-actions"]')

// @MahdiBaghbani: Yes, I know this is horrible! :)
export const getRowForFile = (filename) => cy.get(`[data-test-resource-name="${CSS.escape(filename)}"]`)
    .parent()
    .parent()
    .parent()
    .parent()
    .parent()
    .parent() 