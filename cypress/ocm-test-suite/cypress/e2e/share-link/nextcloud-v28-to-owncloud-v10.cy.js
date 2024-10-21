import {
  createShareLinkV28,
  renameFileV28
} from '../utils/nextcloud-v28'

import {
  selectAppFromLeftSide
} from '../utils/owncloud'

describe('Share link federated sharing functionality for Nextcloud', () => {
  it('Send federated share <file> from Nextcloud v28 to ownCloud v10', () => {
    // send share from Nextcloud 1.
    cy.loginNextcloud('https://nextcloud1.docker', 'einstein', 'relativity')

    renameFileV28('welcome.txt', 'nc1-to-oc1-share-link.txt')
    createShareLinkV28('nc1-to-oc1-share-link.txt').then(
      (result) => {
        cy.visit(result)

        cy.get('button[id="header-actions-toggle"]').click()
        cy.get('button[id="save-external-share"]').click()

        cy.get('form[class="save-form"]').within(() => {
          cy.get('input[id="remote_address"]').type('marie@owncloud1.docker')
          cy.get('input[id="save-button-confirm"]').click()
        })
      }
    )
  })

  it('Receive federated share <file> from Nextcloud v28 to ownCloud v10', () => {
    // accept share from Nextcloud 1.
    cy.loginOwncloud('https://owncloud1.docker', 'marie', 'radioactivity')

    cy.get('div[class="oc-dialog"]', { timeout: 10000 })
      .should('be.visible')
      .find('*[class^="oc-dialog-buttonrow"]')
      .find('button[class="primary"]')
      .click()

    selectAppFromLeftSide('sharingin')

    cy.get('[data-file="nc1-to-oc1-share-link.txt"]', { timeout: 10000 }).should('be.visible')
  })
})
