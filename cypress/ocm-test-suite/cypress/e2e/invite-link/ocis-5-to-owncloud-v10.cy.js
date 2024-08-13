import {
  openFilesAppV5,
  openScienceMeshAppV5,
  createLegacyInviteLinkV5,
  createTextFileV5,
  createShareV5,
} from '../utils/ocis-5'

import {
  selectAppFromLeftSide
} from '../utils/owncloud'

describe('Invite link federated sharing via ScienceMesh functionality for oCIS', () => {
  it('Send invitation from oCIS v5 to ownCloud v10', () => {

    cy.loginOcis('https://ocis1.docker', 'einstein', 'relativity')

    openScienceMeshAppV5()

    createLegacyInviteLinkV5('owncloud1.docker', 'ocis1.docker').then(
      (result) => {
        // save invite link to file.
        cy.writeFile('invite-link-ocis-oc.txt', result)
      }
    )
  })

  it('Accept invitation from oCIS v5 to ownCloud v10', () => {

    // load invite link from file.
    cy.readFile('invite-link-ocis-oc.txt').then((url) => {

      // accept invitation from ownCloud 1.
      cy.loginOwncloudCore(url, 'marie', 'radioactivity')

      cy.get('input[id="accept-button"]', { timeout: 10000 })
        .click()

      // validate 'Albert Einstein' is shown as a contact. 
      cy.visit('https://owncloud1.docker/index.php/apps/sciencemesh/contacts')

      cy.get('table[id="contact-table"]')
        .find('p[class="displayname"]')
        .should("have.text", "Albert Einstein");
    })
  })

  it('Send ScienceMesh share <file> from oCIS v5 to ownCloud v10', () => {
    // share from oCIS 1.
    cy.loginOcis('https://ocis1.docker', 'einstein', 'relativity')

    createTextFileV5('invite-link-ocis-oc.txt', 'Hello World!')

    openFilesAppV5()

    createShareV5('invite-link-ocis-oc.txt', 'marie')
  })

  it('Receive ScienceMesh share <file> from oCIS v5 to ownCloud v10', () => {
    // accept share from ownCloud 1.
    cy.loginOwncloud('https://owncloud1.docker', 'marie', 'radioactivity')

    cy.get('div[class="oc-dialog"]', { timeout: 10000 })
      .should('be.visible')
      .find('*[class^="oc-dialog-buttonrow"]')
      .find('button[class="primary"]')
      .click()

    selectAppFromLeftSide('sharingin')

    cy.get('[data-file="invite-link-ocis-oc.txt"]', { timeout: 10000 })
      .should('be.visible')
  })
})
