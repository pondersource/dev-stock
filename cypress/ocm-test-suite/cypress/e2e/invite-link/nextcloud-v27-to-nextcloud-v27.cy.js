import {
  createInviteLinkV27, 
  verifyFederatedContactV27,
  createScienceMeshShareV27,
  renameFileV27,
  navigationSwitchLeftSideV27,
  selectAppFromLeftSideV27,
} from '../utils/nextcloud-v27'

describe('Invite link federated sharing via ScienceMesh functionality for Nextcloud', () => {
  it('Send invitation from Nextcloud v27 to Nextcloud v27', () => {

    cy.loginNextcloud('https://nextcloud1.docker', 'einstein', 'relativity')
    cy.visit('https://nextcloud1.docker/index.php/apps/sciencemesh/contacts')

    createInviteLinkV27('https://nextcloud2.docker').then(
      (result) => {
        // save invite link to file.
        cy.writeFile('invite-link-nc-nc.txt', result)
      }
    )
  })

  it('Accept invitation from Nextcloud v27 to Nextcloud v27', () => {

    // load invite link from file.
    cy.readFile('invite-link-nc-nc.txt').then((url) => {
      
      // accept invitation from Nextcloud 2.
      cy.loginNextcloudCore(url, 'michiel', 'dejong')

      cy.get('input[id="accept-button"]', { timeout: 10000 })
        .click()

      // validate 'eisntein' is shown as a contact.
      verifyFederatedContactV27('nextcloud2.docker', 'einstein', 'revanextcloud1.docker')
    })
  })

  it('Send ScienceMesh share <file> from Nextcloud v27 to Nextcloud v27', () => {
    // share from Nextcloud 1.
    cy.loginNextcloud('https://nextcloud1.docker', 'einstein', 'relativity')

    renameFileV27('welcome.txt', 'invite-link-nc-nc.txt')
    createScienceMeshShareV27('nextcloud1.docker', 'michiel', 'revanextcloud2.docker', 'invite-link-nc-nc.txt')
  })

  it('Receive ScienceMesh share <file> from Nextcloud v27 to Nextcloud v27', () => {
    // accept share from Nextcloud 2.
    cy.loginNextcloud('https://nextcloud2.docker', 'michiel', 'dejong')

    cy.get('div[class="oc-dialog"]', { timeout: 10000 })
      .should('be.visible')
      .find('*[class^="oc-dialog-buttonrow"]')
      .find('button[class="primary"]')
      .click()

    navigationSwitchLeftSideV27('Open navigation')
    selectAppFromLeftSideV27('shareoverview')
    navigationSwitchLeftSideV27('Close navigation')

    cy.get('[data-file="invite-link-nc-nc.txt"]', { timeout: 10000 }).should('be.visible')
  })
})
