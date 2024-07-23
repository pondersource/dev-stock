import { createInviteLinkV27, createScienceMeshShareV27, renameFileV27 } from '../utils/nextcloud-v27'

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
      
      // validate 'einstein' is shown as a contact. 
      cy.visit('https://nextcloud2.docker/index.php/apps/sciencemesh/contacts')

      cy.get('table[id="contact-table"]')
        .find('p[class="displayname"]')
        .should("have.text", "einstein");
    })
  })

  it('Send ScienceMesh share <file> from Nextcloud v27 to Nextcloud v27', () => {
    // share from Nextcloud 1.
    cy.loginNextcloud('https://nextcloud1.docker', 'einstein', 'relativity')

    renameFileV27('welcome.txt', 'nc1-to-nc2-sciencemesh-share.txt')
    createScienceMeshShareV27('nc1-to-nc2-sciencemesh-share.txt', 'michiel')
  })

  it('Receive ScienceMesh share <file> from Nextcloud v27 to Nextcloud v27', () => {
    // accept share from Nextcloud 2.
    cy.loginNextcloud('https://nextcloud2.docker', 'michiel', 'dejong')

    cy.get('div[class="oc-dialog"]', { timeout: 10000 })
      .should('be.visible')
      .find('*[class^="oc-dialog-buttonrow"]')
      .find('button[class="primary"]')
      .click()

    cy.get('[data-file="nc1-to-nc2-sciencemesh-share.txt"]', { timeout: 10000 }).should('be.visible')
  })
})
