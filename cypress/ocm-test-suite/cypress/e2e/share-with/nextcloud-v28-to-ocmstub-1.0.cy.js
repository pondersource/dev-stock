import { createShareV28, renameFileV28 } from '../utils/nextcloud-v28'

describe('Native federated sharing functionality for Nextcloud v28', () => {
  it('Send federated share <file> from Nextcloud to Nextcloud', () => {
    // share from Nextcloud 1.
    cy.loginNextcloud('https://nextcloud1.docker', 'einstein', 'relativity')

    renameFileV28('welcome.txt', 'nc1-to-os2-share.txt')
    createShareV28('nc1-to-os2-share.txt', 'michiel', 'ocmstub2.docker')
  })

  it('Receive federated share <file> from Nextcloud v28 to OcmStub 1.0', () => {
    // accept share from OcmStub 2.
    cy.loginOcmStub('https://ocmstub2.docker/?')

    cy.get('div[class="oc-dialog"]', { timeout: 10000 })
      .should('be.visible')
      .find('*[class^="oc-dialog-buttonrow"]')
      .find('button[class="primary"]')
      .click()

    // force reload the page for share to apear.
    cy.reload(true)

    cy.get('[data-cy-files-list-row-name="nc1-to-os2-share.txt"]', { timeout: 10000 }).should('be.visible')
  })
})
