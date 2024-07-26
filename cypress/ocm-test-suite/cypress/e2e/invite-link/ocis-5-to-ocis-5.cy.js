import { openScienceMeshAppV5, createInviteLinkV5 } from '../utils/ocis-5'

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
    })
  })

  // it('Send ScienceMesh share <file> from oCIS v5 to oCIS v5', () => {
  //   // share from oCIS 1.
  //   cy.loginOcis('https://ocis1.docker', 'marie', 'radioactivity')

  //   renameFile('welcome.txt', 'oc1-to-oc2-sciencemesh-share.txt')
  //   createScienceMeshShare('oc1-to-oc2-sciencemesh-share.txt', 'mahdi', 'revaocis2.docker')
  // })

  // it('Receive ScienceMesh share <file> from oCIS v5 to oCIS v5', () => {
  //   // accept share from oCIS 2.
  //   cy.loginOcis('https://ocis2.docker', 'mahdi', 'baghbani')

  //   cy.get('div[class="oc-dialog"]', { timeout: 10000 })
  //     .should('be.visible')
  //     .find('*[class^="oc-dialog-buttonrow"]')
  //     .find('button[class="primary"]')
  //     .click()

  //   cy.get('[data-file="oc1-to-oc2-sciencemesh-share.txt"]', { timeout: 10000 }).should('be.visible')
  // })
})
