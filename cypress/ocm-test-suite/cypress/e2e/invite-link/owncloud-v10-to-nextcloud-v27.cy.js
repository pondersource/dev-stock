import {
  createInviteLink,
  createScienceMeshShare,
  renameFile
} from '../utils/owncloud'

import {
  navigationSwitchLeftSideV27,
  selectAppFromLeftSideV27,
} from '../utils/nextcloud-v27'

describe('Invite link federated sharing via ScienceMesh functionality for ownCloud to Nextcloud', () => {
  it('Send invitation from ownCloud v10 to Nextcloud v27', () => {

    cy.loginOwncloud('https://owncloud1.docker', 'marie', 'radioactivity')
    cy.visit('https://owncloud1.docker/index.php/apps/sciencemesh/')

    createInviteLink('https://nextcloud1.docker').then(
      (result) => {
        // save invite link to file.
        cy.writeFile('invite-link-oc-nc.txt', result)
      }
    )
  })

  it('Accept invitation from ownCloud v10 to Nextcloud v27', () => {

    // load invite link from file.
    cy.readFile('invite-link-oc-nc.txt').then((url) => {

      // accept invitation from Nextcloud 1.
      cy.loginNextcloudCore(url, 'einstein', 'relativity')

      cy.get('input[id="accept-button"]', { timeout: 10000 })
        .click()

      // validate 'einstein' is shown as a contact.
      cy.visit('https://nextcloud1.docker/index.php/apps/sciencemesh/contacts')

      cy.get('table[id="contact-table"]')
        .find('p[class="displayname"]')
        .should("have.text", "marie");
    })
  })

  it('Send ScienceMesh share <file> from ownCloud v10 to Nextcloud v27', () => {
    // share from ownCloud 1.
    cy.loginOwncloud('https://owncloud1.docker', 'marie', 'radioactivity')

    renameFile('welcome.txt', 'oc1-to-nc1-sciencemesh-share.txt')
    createScienceMeshShare('oc1-to-nc1-sciencemesh-share.txt', 'einstein', 'revanextcloud1.docker')
  })

  it('Receive ScienceMesh share <file> from ownCloud v10 to Nextcloud v27', () => {
    // accept share from Nextcloud 1.
    cy.loginNextcloud('https://nextcloud1.docker', 'einstein', 'relativity')

    cy.get('div[class="oc-dialog"]', { timeout: 10000 })
      .should('be.visible')
      .find('*[class^="oc-dialog-buttonrow"]')
      .find('button[class="primary"]')
      .click()

    navigationSwitchLeftSideV27('Open navigation')
    selectAppFromLeftSideV27('shareoverview')
    navigationSwitchLeftSideV27('Close navigation')

    cy.get('[data-file="oc1-to-nc1-sciencemesh-share.txt"]', { timeout: 10000 }).should('be.visible')
  })
})
