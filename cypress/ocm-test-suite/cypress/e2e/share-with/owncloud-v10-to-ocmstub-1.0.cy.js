import {
  createShare,
  renameFile,
  selectAppFromLeftSide
} from '../utils/owncloud'

describe('Native federated sharing functionality for ownCloud', () => {
  it('Send federated share <file> from ownCloud v10 to ownCloud v10', () => {
    // share from ownCloud 1.
    cy.loginOwncloud('https://owncloud1.docker', 'marie', 'radioactivity')

    renameFile('welcome.txt', 'oc1-to-oc2-share.txt')
    createShare('oc1-to-oc2-share.txt', 'mahdi', 'owncloud2.docker')
  })

  it('Receive federated share <file> from ownCloud v10 to OcmStub 1.0', () => {
    // accept share from OcmStub 2.
    cy.loginOcmStub('https://ocmstub2.docker/?')

    cy.contains('"shareWith": "michiel@https://ocmstub2.docker"').should('be.visible')
    cy.contains('"shareType": "user"').should('be.visible')
    cy.contains('"name": "nc1-to-os2-share.txt"').should('be.visible')
    cy.contains('"resourceType": "file"').should('be.visible')
    cy.contains('"owner": "einstein@https://owncloud1.docker/"').should('be.visible')
    cy.contains('"sharedBy": "einstein@https://owncloud1.docker/"').should('be.visible')
    cy.contains('"ownerDisplayName": "einstein"').should('be.visible')
    cy.contains('"description": ""').should('be.visible')
    cy.contains('"shareWith": "michiel@https://ocmstub2.docker"').should('be.visible')
    cy.contains('"protocol": { "name": "webdav", "options": { "sharedSecret": "').should('be.visible')
    cy.contains('"permissions": "{http://open-cloud-mesh.org/ns}share-permissions"').should('be.visible')
  })
})
