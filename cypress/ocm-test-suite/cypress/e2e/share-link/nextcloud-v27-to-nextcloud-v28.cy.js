import { createShareLinkV27, renameFileV27 } from '../utils/nextcloud-v27'

describe('Share link federated sharing functionality for Nextcloud', () => {
  it('Send federated share <file> from Nextcloud v27 to Nextcloud v28', () => {
    // send share from Nextcloud 1.
    cy.loginNextcloud('https://nextcloud1.docker', 'einstein', 'relativity')

    renameFileV27('welcome.txt', 'nc1-to-nc2-share-link.txt')
    createShareLinkV27('nc1-to-nc2-share-link.txt').then(
      (result) => {
        cy.visit(result)

        cy.get('button[id="header-actions-toggle"]').click()
        cy.get('button[id="save-external-share"]').click()
        
        cy.get('form[class="save-form"]').within(() => {
          cy.get('input[id="remote_address"]').type('michiel@nextcloud2.docker')
          cy.get('input[id="save-button-confirm"]').click()
        })
      }
    )
  })

  it('Receive federated share <file> from Nextcloud v27 to Nextcloud v28', () => {
    // accept share from Nextcloud 2.
    cy.loginNextcloud('https://nextcloud2.docker', 'michiel', 'dejong')

    cy.get('div[class="oc-dialog"]', { timeout: 10000 })
      .should('be.visible')
      .find('*[class^="oc-dialog-buttonrow"]')
      .find('button[class="primary"]')
      .click()

      // force reload the page for share to apear.
      cy.reload(true)

    // 1. check for filename existence.
    cy.get('[data-cy-files-list-row-name="nc1-to-nc2-share-link.txt"]', { timeout: 10000 }).should('be.visible')
  })
})
