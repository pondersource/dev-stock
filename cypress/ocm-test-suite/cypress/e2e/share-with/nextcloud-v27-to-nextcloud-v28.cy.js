import { createShareV27, renameFileV27 } from '../utils/nextcloud-v27'

describe('Native federated sharing functionality for Nextcloud', () => {
  it('Send federated share <file> from Nextcloud v27 to Nextcloud v28', () => {
    // share from Nextcloud 1.
    cy.loginNextcloud('https://nextcloud1.docker', 'einstein', 'relativity')

    renameFileV27('welcome.txt', 'nc1-to-nc2-share.txt')
    createShareV27('nc1-to-nc2-share.txt', 'michiel', 'nextcloud2.docker')
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

    // TODO: verify share received: 1. check for file name existence, 2. check if it can be downloaded, 3. compare checksum to the original file to make sure it is the same file.
    // 1. check for filename existence.
    cy.get('[data-file="nc1-to-nc2-share.txt"]', { timeout: 10000 }).should('be.visible')
  })
})
