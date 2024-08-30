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

    cy.contains('"shareWith": "michiel@https://ocmstub2.docker"').should('be.visible')
    cy.contains('"shareType": "user"').should('be.visible')
    cy.contains('"name": "nc1-to-os2-share.txt"').should('be.visible')
    cy.contains('"resourceType": "file"').should('be.visible')
    cy.contains('"owner": "einstein@https://nextcloud1.docker/"').should('be.visible')
    cy.contains('"sharedBy": "einstein@https://nextcloud1.docker/"').should('be.visible')
    cy.contains('"ownerDisplayName": "einstein"').should('be.visible')
    cy.contains('"description": ""').should('be.visible')
    cy.contains('"shareWith": "michiel@https://ocmstub2.docker"').should('be.visible')
    cy.contains('"protocol": { "name": "webdav", "options": { "sharedSecret": "').should('be.visible')
    cy.contains('"permissions": "{http://open-cloud-mesh.org/ns}share-permissions"').should('be.visible')
  })
})
