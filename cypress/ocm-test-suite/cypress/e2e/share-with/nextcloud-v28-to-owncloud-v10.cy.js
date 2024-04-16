import { createShareV28, renameFileV28 } from '../utils/nextcloud-v28'

before(() => {
  // makes custom commands available to all subsequent cy.origin('url')
  // calls in this spec. put it in your support file to make them available to
  // all specs
  cy.origin('https://owncloud1.docker', () => {
    Cypress.require('../../support/commands')
  })
})

describe('OCM federated sharing functionality for Nextcloud', () => {
  it('Accept federated share <file> from Nextcloud v28 to ownCloud v10', () => {
    // share from Nextcloud 1.
    cy.loginNextcloud('https://nextcloud1.docker', 'einstein', 'relativity')

    renameFileV28('welcome.txt', 'nc1-to-oc1-share.txt')
    createShareV28('nc1-to-oc1-share.txt', 'mahdi', 'owncloud2.docker')

    // accept share from ownCloud 1.
    cy.origin('https://owncloud1.docker', () => {
      cy.loginOwncloud('/', 'marie', 'radioactivity')

      cy.get('div[class="oc-dialog"]', { timeout: 10000 })
      .should('be.visible')
      .find('*[class^="oc-dialog-buttonrow"]')
      .find('button[class="primary"]')
      .click()

      // TODO: verify share received: 1. check for file name existence, 2. check if it can be downloaded, 3. compare checksum to the original file to make sure it is the same file.
      // 1. check for filename existence.
      cy.get('[data-file="nc1-to-oc1-share.txt"]', { timeout: 10000 }).should('be.visible')
    })
  })
})
