import { createShareGroup, renameFile } from '../utils/owncloud'

before(() => {
  // makes custom commands available to all subsequent cy.origin('url')
  // calls in this spec. put it in your support file to make them available to
  // all specs
  cy.origin('https://owncloud4.docker', () => {
    Cypress.require('../../support/commands')
  })
})

describe('Share to group functionality for ownCloud', () => {
  it('Accept federated share to group from ownCloud to ownCloud', () => {
    // share to group from ownCloud 3.
    cy.loginOwncloud('https://owncloud3.docker', 'einstein', 'relativity')

    renameFile('welcome.txt', 'oc3-to-oc4-share-to-group.txt')
    createShareGroup('oc3-to-oc4-share-to-group.txt', 'TestGroup')

    // accept share from ownCloud 4.
    cy.origin('https://owncloud4.docker', () => {
      cy.loginOwncloud('/', 'marie', 'radioactivity')

      cy.get('div[class="oc-dialog"]', { timeout: 10000 })
      .should('be.visible')
      .find('*[class^="oc-dialog-buttonrow"]')
      .find('button[class="primary"]')
      .click()

      // TODO: verify share received: 1. check for file name existence, 2. check if it can be downloaded, 3. compare checksum to the original file to make sure it is the same file.
      // 1. check for filename existence.
      cy.get('[data-file="oc3-to-oc4-share-to-group.txt"]', { timeout: 10000 }).should('be.visible')
    })
  })
})
