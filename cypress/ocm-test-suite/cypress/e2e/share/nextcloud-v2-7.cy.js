import { createShareV2_7, renameFileV2_7 } from '../utils/nextcloud-v2-7'

before(() => {
  // makes custom commands available to all subsequent cy.origin('url')
  // calls in this spec. put it in your support file to make them available to
  // all specs
  cy.origin('https://nextcloud2.docker', () => {
    Cypress.require('../../support/commands')
  })
})

describe('Native federated sharing functionality for Nextcloud V2.7', () => {
  it('Accept federated share from Nextcloud to Nextcloud', () => {
    // share from Nextcloud 1.
    cy.loginNextcloud('https://nextcloud1.docker', 'einstein', 'relativity')

    renameFileV2_7('welcome.txt', 'nc1-to-nc2-share.txt')
    createShareV2_7('nc1-to-nc2-share.txt', 'michiel', 'nextcloud2.docker')

    // accept share from Nextcloud 2.
    cy.origin('https://nextcloud2.docker', () => {
      cy.loginNextcloud('/', 'michiel', 'dejong')

      cy.get('div[class="oc-dialog"]', { timeout: 10000 })
      .should('be.visible')
      .find('*[class^="oc-dialog-buttonrow"]')
      .find('button[class="primary"]')
      .click()

      // TODO: verify share received: 1. check for file name existence, 2. check if it can be downloaded, 3. compare checksum to the original file to make sure it is the same file.
      // 1. check for filename existence.
      cy.get('[data-file="nc1-to-nc2-share.txt"]', { timeout: 10000 }).should('be.visible')
    })
  })
})
