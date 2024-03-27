import { createShareV28, renameFileV28 } from '../utils/nextcloud-v28'

before(() => {
  // makes custom commands available to all subsequent cy.origin('url')
  // calls in this spec. put it in your support file to make them available to
  // all specs
  cy.origin('https://nextcloud4.docker', () => {
    Cypress.require('../../support/commands')
  })
})

describe('Native federated sharing functionality for Nextcloud v2.8', () => {
  it('Accept federated share from Nextcloud to Nextcloud', () => {
    // share from Nextcloud 3.
    cy.loginNextcloud('https://nextcloud3.docker', 'yashar', 'pmh')

    renameFileV28('welcome.txt', 'nc3-to-nc4-share.txt')
    createShareV28('nc3-to-nc4-share.txt', 'madeline', 'nextcloud4.docker')

    // accept share from Nextcloud 2.
    cy.origin('https://nextcloud4.docker', () => {
      cy.loginNextcloud('/', 'madeline', 'oleary')

      cy.get('div[class="oc-dialog"]', { timeout: 10000 })
      .should('be.visible')
      .find('*[class^="oc-dialog-buttonrow"]')
      .find('button[class="primary"]')
      .click()

      // TODO: verify share received: 1. check for file name existence, 2. check if it can be downloaded, 3. compare checksum to the original file to make sure it is the same file.
      // 1. check for filename existence.
      cy.get('[data-file="nc3-to-nc4-share.txt"]', { timeout: 10000 }).should('be.visible')
    })
  })
})
