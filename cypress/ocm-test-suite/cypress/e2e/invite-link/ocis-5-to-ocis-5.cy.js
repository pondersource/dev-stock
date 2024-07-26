import { openFilesAppV5, openScienceMeshAppV5, createInviteLinkV5, createShareV5 } from '../utils/ocis-5'

describe('Invite link federated sharing via ScienceMesh functionality for oCIS', () => {
  it('Send invitation from oCIS v5 to oCIS v5', () => {

    cy.loginOcis('https://ocis1.docker', 'einstein', 'relativity')

    openScienceMeshAppV5()

    createInviteLinkV5().then(
      (result) => {
        // save invite link to file.
        cy.writeFile('invite-link-ocis-ocis.txt', result)
      }
    )
  })

  it('Accept invitation from oCIS v5 to oCIS v5', () => {

    // load invite token from file.
    cy.readFile('invite-link-ocis-ocis.txt').then((token) => {
      
      cy.loginOcis('https://ocis2.docker', 'marie', 'radioactivity')

      openScienceMeshAppV5()

      cy.get('div[id="sciencemesh-accept-invites"]')
        .find('label')
        .contains('Enter invite token')
        .parent()
        .scrollIntoView()
        .should('be.visible')
        .within(() => {
          cy.get('input[type="text"]')
          .type(token)
        })

      cy.get('div[id="sciencemesh-accept-invites"]')
        .find('label')
        .contains('Select institution of inviter')
        .parent()
        .scrollIntoView()
        .should('be.visible')
        .find('div[class="vs__actions"')
        .click()

      cy.get('div[id="sciencemesh-accept-invites"]')
        .find('label')
        .contains('Select institution of inviter')
        .parent()
        .find('ul[role="listbox"]')
        .find('li')
        .first()
        .click()

      cy.get('div[id="sciencemesh-accept-invites"]')
        .find('span')
        .contains('Accept invitation')
        .parent()
        .scrollIntoView()
        .should('be.visible')
        .click()
      
      // check if federation connection is added.
      cy.get('div[id="sciencemesh-connections"]')
        .get('table')
        .find('tbody>tr')
        .eq(0)
        .find('td')
        .eq(0)
        .should("have.text", "Albert Einstein")

      cy.get('div[id="sciencemesh-connections"]')
        .get('table')
        .find('tbody>tr')
        .eq(0)
        .find('td')
        .eq(2)
        .should("have.text", "ocis1.docker")
    })
  })

  it('Send ScienceMesh share <file> from oCIS v5 to oCIS v5', () => {
    // share from oCIS 1.
    cy.loginOcis('https://ocis1.docker', 'einstein', 'relativity')

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
        cy.get('input[id="oc-textinput-10"]').type('invite-link-ocis-ocis.txt')

        cy.get('button')
          .contains('Create')
          .scrollIntoView()
          .should('be.visible')
          .click()
      })
    
    cy.get('textarea[id="text-editor-input"]')
      .scrollIntoView()
      .should('be.visible')
      .type('Hello World!')

    cy.get('button[id="app-save-action"]')
      .scrollIntoView()
      .should('be.visible')
      .click()

    openFilesAppV5()

    createShareV5('invite-link-ocis-ocis.txt', 'marie')

  })

  it('Receive ScienceMesh share <file> from oCIS v5 to oCIS v5', () => {
    // accept share from oCIS 2.
    cy.loginOcis('https://ocis2.docker', 'marie', 'radioactivity')

    cy.get('div[id="web-nav-sidebar"]')
      .should('be.visible')
      .find('span')
      .contains('Shares')
      .click()

    cy.get('span[data-test-resource-name="invite-link-ocis-ocis.txt"]')
      .scrollIntoView()
      .should('be.visible')
  })
})
