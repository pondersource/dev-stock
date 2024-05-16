import { createShare, renameFile } from '../utils/owncloud'

describe('OCM federated sharing functionality for ownCloud', () => {
  it('Send federated share <file> from ownCloud v10 to Nextcloudn v27', () => {
    // share from ownCloud 1.
    cy.loginOwncloud('https://owncloud1.docker', 'marie', 'radioactivity')

    renameFile('welcome.txt', 'oc1-to-nc1-share.txt')
    createShare('oc1-to-nc1-share.txt', 'einstein', 'nextcloud1.docker')
  })

  it('Receive federated share <file> from ownCloud v10 to Nextcloudn v27', () => {
    // accept share from Nextcloud 2.
    cy.loginNextcloud('https://nextcloud1.docker', 'einstein', 'relativity')

    cy.get('div[class="oc-dialog"]', { timeout: 10000 })
      .should('be.visible')
      .find('*[class^="oc-dialog-buttonrow"]')
      .find('button[class="primary"]')
      .click()

    // TODO: verify share received: 1. check for file name existence, 2. check if it can be downloaded, 3. compare checksum to the original file to make sure it is the same file.
    // 1. check for filename existence.
    cy.get('[data-file="noc1-to-nc1-share.txt"]', { timeout: 10000 }).should('be.visible')
  })
})
