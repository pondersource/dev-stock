import {
  openFilesAppV5,
  openScienceMeshAppV5,
  createLegacyInviteLinkV5,
  createTextFileV5,
  createShareV5,
} from '../utils/ocis-5'

import {
  navigationSwitchLeftSideV27,
  selectAppFromLeftSideV27,
} from '../utils/nextcloud-v27'

describe('Invite link federated sharing via ScienceMesh functionality for oCIS', () => {
  it('Send invitation from oCIS v5 to Nextcloud v27', () => {

    cy.loginOcis('https://ocis1.docker', 'einstein', 'relativity')

    openScienceMeshAppV5()

    createLegacyInviteLinkV5('nextcloud1.docker', 'ocis1.docker').then(
      (result) => {
        // save invite link to file.
        cy.writeFile('invite-link-ocis-nc.txt', result)
      }
    )
  })

  it('Accept invitation from oCIS v5 to Nextcloud v27', () => {

    // load invite link from file.
    cy.readFile('invite-link-ocis-nc.txt').then((url) => {

      // accept invitation from Nextcloud 1.
      cy.loginNextcloudCore(url, 'marie', 'radioactivity')

      cy.get('input[id="accept-button"]', { timeout: 10000 })
        .click()

      // validate 'Albert Einstein' is shown as a contact. 
      cy.visit('https://nextcloud1.docker/index.php/apps/sciencemesh/contacts')

      cy.get('table[id="contact-table"]')
        .find('p[class="displayname"]')
        .should("have.text", "Albert Einstein");
    })
  })

  it('Send ScienceMesh share <file> from oCIS v5 to Nextcloud v27', () => {
    // share from oCIS 1.
    cy.loginOcis('https://ocis1.docker', 'einstein', 'relativity')

    createTextFileV5('invite-link-ocis-nc.txt', 'Hello World!')

    openFilesAppV5()

    createShareV5('invite-link-ocis-nc.txt', 'marie')

    cy.wait(2000)
  })

  it('Receive ScienceMesh share <file> from oCIS v5 to Nextcloud v27', () => {
    // accept share from Nextcloud 1.
    cy.loginNextcloud('https://nextcloud1.docker', 'marie', 'radioactivity')

    cy.get('div[class="oc-dialog"]', { timeout: 10000 })
      .should('be.visible')
      .find('*[class^="oc-dialog-buttonrow"]')
      .find('button[class="primary"]')
      .click()

    navigationSwitchLeftSideV27('Open navigation')
    selectAppFromLeftSideV27('shareoverview')
    navigationSwitchLeftSideV27('Close navigation')

    cy.get('[data-file="invite-link-ocis-nc.txt"]', { timeout: 10000 }).should('be.visible')
  })
})
