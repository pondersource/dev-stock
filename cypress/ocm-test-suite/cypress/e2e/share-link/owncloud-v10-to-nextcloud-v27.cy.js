import {
  createShareLink,
  renameFile
} from '../utils/owncloud-v10'

import {
  navigationSwitchLeftSideV27,
  selectAppFromLeftSideV27,
} from '../utils/nextcloud-v27'

describe('Share link federated sharing functionality for ownCloud', () => {
  it('Send federated share <file> from ownCloud v10 to Nextcloud v27', () => {
    // share from ownCloud 1.
    cy.loginOwncloud('https://owncloud1.docker', 'marie', 'radioactivity')

    renameFile('welcome.txt', 'oc1-to-nc1-share-link.txt')
    createShareLink('oc1-to-nc1-share-link.txt')
  })

  it('Receive federated share <file> from ownCloud v10 to Nextcloud v27', () => {

    // load share url from file.
    cy.readFile('share-link-url.txt').then((result) => {

      // extract token from url.
      const token = result.replace('https://owncloud1.docker/s/','');

      // put token into the link.
      const url = `https://nextcloud1.docker/index.php/login?redirect_url=%252Findex.php%252Fapps%252Ffiles#remote=https%3A%2F%2Fowncloud1.docker&token=${token}&owner=marie&ownerDisplayName=marie&name=oc1-to-oc2-share-link.txt&protected=0`

      // accept share from Nextcloud 1.
      cy.loginNextcloudCore('https://nextcloud1.docker', 'einstein', 'relativity')

      cy.visit(url)

      cy.get('div[class="oc-dialog"]', { timeout: 10000 })
        .should('be.visible')
        .find('*[class^="oc-dialog-buttonrow"]')
        .find('button[class="primary"]')
        .click()

      navigationSwitchLeftSideV27('Open navigation')
      selectAppFromLeftSideV27('shareoverview')
      navigationSwitchLeftSideV27('Close navigation')

      cy.get('[data-file="oc1-to-nc1-share-link.txt"]', { timeout: 10000 }).should('be.visible')
    })
  })
})
