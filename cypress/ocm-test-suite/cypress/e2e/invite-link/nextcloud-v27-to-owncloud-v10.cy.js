import {
  createInviteLinkV27,
  createScienceMeshShareV27,
  renameFileV27
} from '../utils/nextcloud-v27'

import {
  selectAppFromLeftSide
} from '../utils/owncloud'

describe('Invite link federated sharing via ScienceMesh functionality for Nextcloud to ownCloud', () => {
  it('Send invitation from Nextcloud v27 to ownCloud v10', () => {

    cy.loginNextcloud('https://nextcloud1.docker', 'einstein', 'relativity')
    cy.visit('https://nextcloud1.docker/index.php/apps/sciencemesh/contacts')

    createInviteLinkV27('https://owncloud1.docker').then(
      (result) => {
        // save invite link to file.
        cy.writeFile('invite-link-nc-oc.txt', result)
      }
    )
  })

  it('Accept invitation from Nextcloud v27 to ownCloud v10', () => {

    // load invite link from file.
    cy.readFile('invite-link-nc-oc.txt').then((url) => {

      // accept invitation from Nextcloud 1.
      cy.loginOwncloudCore(url, 'marie', 'radioactivity')

      cy.get('input[id="accept-button"]', { timeout: 10000 })
        .click()

      // validate 'einstein' is shown as a contact.
      cy.visit('https://owncloud1.docker/index.php/apps/sciencemesh/contacts')

      cy.get('table[id="contact-table"]')
        .find('p[class="displayname"]')
        .should("have.text", "einstein");
    })
  })

  it('Send ScienceMesh share <file> from Nextcloud v27 to ownCloud v10', () => {
    // share from Nextcloud 1.
    cy.loginNextcloud('https://nextcloud1.docker', 'einstein', 'relativity')

    renameFileV27('welcome.txt', 'invite-link-nc-oc.txt')
    createScienceMeshShareV27('nextcloud1.docker', 'marie', 'revaowncloud1.docker', 'invite-link-nc-oc.txt')
  })

  it('Receive ScienceMesh share <file> from Nextcloud v27 to ownCloud v10', () => {
    // accept share Nextcloud 1.
    cy.loginOwncloud('https://owncloud1.docker', 'marie', 'radioactivity')

    cy.get('div[class="oc-dialog"]', { timeout: 10000 })
      .should('be.visible')
      .find('*[class^="oc-dialog-buttonrow"]')
      .find('button[class="primary"]')
      .click()

    selectAppFromLeftSide('sharingin')

    cy.get('[data-file="invite-link-nc-oc.txt"]', { timeout: 10000 }).should('be.visible')
  })
})
