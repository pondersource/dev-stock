import {
  createShareV27,
  renameFileV27,
} from '../utils/nextcloud-v27'

describe('Native federated sharing functionality for Nextcloud', () => {
  it('Send federated share <file> from Nextcloud v27 to Nextcloud v27', () => {
    // share from Nextcloud 1.
    cy.loginNextcloud('https://nextcloud1.docker', 'einstein', 'relativity')

    renameFileV27('welcome.txt', 'nc1-to-os1-share.txt')
    createShareV27('nc1-to-os1-share.txt', 'michiel', 'ocmstub1.docker')
  })

  it('Receive federated share <file> from Nextcloud v27 to OcmStub 1.0', () => {
    // accept share from OcmStub 1.
    cy.loginOcmStub('https://ocmstub1.docker/?')

    cy.contains('"shareWith": "michiel@https://ocmstub1.docker"').should('be.visible')
    cy.contains('"shareType": "user"').should('be.visible')
    cy.contains('"name": "nc1-to-os1-share.txt"').should('be.visible')
    cy.contains('"resourceType": "file"').should('be.visible')
    cy.contains('"owner": "einstein@https://nextcloud1.docker/"').should('be.visible')
    cy.contains('"sharedBy": "einstein@https://nextcloud1.docker/"').should('be.visible')
    cy.contains('"ownerDisplayName": "einstein"').should('be.visible')
    cy.contains('"description": ""').should('be.visible')
    cy.contains('"protocol": { "name": "webdav", "options": { "sharedSecret": "').should('be.visible')
    cy.contains('"permissions": "{http://open-cloud-mesh.org/ns}share-permissions"').should('be.visible')
  })
})
