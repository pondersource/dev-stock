import {
  createShareLink,
  renameFile,
  selectAppFromLeftSide
} from '../utils/owncloud'

describe('Share link federated sharing functionality for ownCloud', () => {
  it('Send federated share <file> from ownCloud v10 to ownCloud v10', () => {
    // share from ownCloud 1.
    cy.loginOwncloud('https://owncloud1.docker', 'marie', 'radioactivity')

    renameFile('welcome.txt', 'oc1-to-oc2-share-link.txt')
    createShareLink('oc1-to-oc2-share-link.txt')
  })

  it('Receive federated share <file> from ownCloud v10 to ownCloud v10', () => {

    // load share url from file.
    cy.readFile('share-link-url.txt').then((result) => {

      // extract token from url.
      const token = result.replace('https://owncloud1.docker/s/','');

      // put token into the link.
      const url = `https://owncloud2.docker/index.php/apps/files#remote=https%3A%2F%2Fowncloud1.docker&token=${token}&owner=marie&ownerDisplayName=marie&name=oc1-to-oc2-share-link.txt&protected=0`

      // accept share from ownCloud 2.
      cy.loginOwncloudCore(url, 'mahdi', 'baghbani')

      cy.get('div[class="oc-dialog"]', { timeout: 10000 })
        .should('be.visible')
        .find('*[class^="oc-dialog-buttonrow"]')
        .find('button[class="primary"]')
        .click()

      selectAppFromLeftSide('sharingin')

      cy.get('[data-file="oc1-to-oc2-share-link.txt"]', { timeout: 10000 }).should('be.visible')
    })
  })
})
