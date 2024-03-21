import { createShare, renameFile } from '../utils/owncloud'

before(() => {
  // makes custom commands available to all subsequent cy.origin('url')
  // calls in this spec. put it in your support file to make them available to
  // all specs
  cy.origin('https://owncloud2.docker', () => {
    Cypress.require('../../support/commands')
  })
})

describe('Native federated sharing functionality for ownCloud', () => {
  it('Accept federated share from ownCloud to ownCloud', () => {
    // share from owncloud 1.
    cy.loginOwncloud('https://owncloud1.docker', 'marie', 'radioactivity')

    renameFile('welcome.txt', 'oc1-to-oc2-share.txt')
    createShare('oc1-to-oc2-share.txt', 'mahdi', 'owncloud2.docker')

    // accept share from ownCloud 2.
    cy.origin('https://owncloud2.docker', () => {
      cy.loginOwncloud('/', 'mahdi', 'baghbani')

      cy.get('div[class="oc-dialog"]', { timeout: 10000 })
      .should('be.visible')
      .find('*[class^="oc-dialog-buttonrow"]')
      .find('button[class="primary"]')
      .click()

      // TODO: verify share received: 1. check for file name existence, 2. check if it can be downloaded, 3. compare checksum to the original file to make sure it is the same file.
      // 1. check for filename existence.
      cy.get('[data-file="oc1-to-oc2-share.txt"]', { timeout: 10000 }).should('be.visible')
    })
  })
})
