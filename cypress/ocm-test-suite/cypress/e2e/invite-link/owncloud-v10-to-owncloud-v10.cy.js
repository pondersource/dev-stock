import { 
  createInviteLink, 
  createScienceMeshShare, 
  renameFile,
  selectAppFromLeftSide,
} from '../utils/owncloud'

describe('Invite link federated sharing via ScienceMesh functionality for ownCloud', () => {
  it('Send invitation from ownCloud v10 to ownCloud v10', () => {

    cy.loginOwncloud('https://owncloud1.docker', 'marie', 'radioactivity')
    cy.visit('https://owncloud1.docker/index.php/apps/sciencemesh/')

    createInviteLink('https://owncloud2.docker').then(
      (result) => {
        // save invite link to file.
        cy.writeFile('invite-link-oc-oc.txt', result)
      }
    )
  })

  it('Accept invitation from ownCloud v10 to ownCloud v10', () => {

    // load invite link from file.
    cy.readFile('invite-link-oc-oc.txt').then((url) => {
      
      // accept invitation from ownCloud 2.
      cy.loginOwncloudCore(url, 'mahdi', 'baghbani')

      cy.get('input[id="accept-button"]', { timeout: 10000 })
        .click()
      
      // validate 'marie' is shown as a contact. 
      cy.visit('https://owncloud2.docker/index.php/apps/sciencemesh/contacts')

      cy.get('table[id="contact-table"]')
        .find('p[class="displayname"]')
        .should("have.text", "marie");
    })
  })

  it('Send ScienceMesh share <file> from ownCloud v10 to ownCloud v10', () => {
    // share from ownCloud 1.
    cy.loginOwncloud('https://owncloud1.docker', 'marie', 'radioactivity')

    renameFile('welcome.txt', 'oc1-to-oc2-sciencemesh-share.txt')
    createScienceMeshShare('oc1-to-oc2-sciencemesh-share.txt', 'mahdi', 'revaowncloud2.docker')
  })

  it('Receive ScienceMesh share <file> from ownCloud v10 to ownCloud v10', () => {
    // accept share from ownCloud 2.
    cy.loginOwncloud('https://owncloud2.docker', 'mahdi', 'baghbani')

    cy.get('div[class="oc-dialog"]', { timeout: 10000 })
      .should('be.visible')
      .find('*[class^="oc-dialog-buttonrow"]')
      .find('button[class="primary"]')
      .click()
    
    selectAppFromLeftSide('sharingin')

    cy.get('[data-file="oc1-to-oc2-sciencemesh-share.txt"]', { timeout: 10000 }).should('be.visible')
  })
})
