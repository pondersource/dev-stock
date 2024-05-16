import { createShare, renameFile } from '../utils/owncloud'

describe('Native federated sharing functionality for ownCloud', () => {
  it('Send federated share <file> from ownCloud v10 to ownCloud v10', () => {
    // share from ownCloud 1.
    cy.loginOwncloud('https://owncloud1.docker', 'marie', 'radioactivity')

    renameFile('welcome.txt', 'oc1-to-oc2-share.txt')
    createShare('oc1-to-oc2-share.txt', 'mahdi', 'owncloud2.docker')
  })

  it('Receive federated share <file> from ownCloud v10 to ownCloud v10', () => {
    // accept share from Nextcloud 2.
    cy.loginNextcloud('https://owncloud2.docker', 'mahdi', 'baghbani')

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
