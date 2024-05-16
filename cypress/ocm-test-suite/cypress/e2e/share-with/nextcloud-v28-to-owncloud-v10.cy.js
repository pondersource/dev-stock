import { createShareV28, renameFileV28 } from '../utils/nextcloud-v28'

describe('OCM federated sharing functionality for Nextcloud', () => {
  it('Send federated share <file> from Nextcloud v28 to ownCloud v10', () => {
    // share from Nextcloud 1.
    cy.loginNextcloud('https://nextcloud1.docker', 'einstein', 'relativity')

    renameFileV28('welcome.txt', 'nc1-to-oc1-share.txt')
    createShareV28('nc1-to-oc1-share.txt', 'marie', 'owncloud1.docker')
  })

  it('Receive federated share <file> from Nextcloud v28 to ownCloud v10', () => {
    // accept share from Nextcloud 2.
    cy.loginOwncloud('https://owncloud1.docker', 'marie', 'radioactivity')

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
