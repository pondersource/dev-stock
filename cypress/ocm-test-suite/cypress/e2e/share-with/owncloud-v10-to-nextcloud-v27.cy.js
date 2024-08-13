import { 
  createShare, 
  renameFile 
} from '../utils/owncloud'

import {
  navigationSwitchLeftSideV27,
  selectAppFromLeftSideV27,
} from '../utils/nextcloud-v27'

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

    navigationSwitchLeftSideV27('Open navigation')
    selectAppFromLeftSideV27('shareoverview')
    navigationSwitchLeftSideV27('Close navigation')

    cy.get('[data-file="oc1-to-nc1-share.txt"]', { timeout: 10000 }).should('be.visible')
  })
})
