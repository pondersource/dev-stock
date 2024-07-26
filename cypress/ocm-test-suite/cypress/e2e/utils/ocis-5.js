export function openScienceMeshAppV5() {
    getApplicationSwitcherV5()
    getApplicationV5('ocm')
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

export const getApplicationV5 = (appName) => getApplicationMenuV5()
                                                .find(`a[data-test-id="${CSS.escape(appName)}"]`)
                                                .should('be.visible')
                                                .click()
 
export const getApplicationSwitcherV5 = () => getApplicationMenuV5()
                                                .find('button[id="_appSwitcherButton"]')
                                                .should('be.visible')
                                                .click()

export const getApplicationMenuV5 = () => cy.get('nav[id="applications-menu"]').should('be.visible')
