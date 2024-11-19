import {
  createShare,
  renameFile,
} from '../utils/owncloud'

describe('Native federated sharing functionality for ownCloud', () => {
  it('Send federated share <file> from OcmStub v1.0.0 to ownCloud v10', () => {
    // share from ownCloud 1.
    cy.loginOwncloud('https://owncloud1.docker', 'marie', 'radioactivity')

    renameFile('welcome.txt', 'oc1-to-os1-share.txt')
    createShare('oc1-to-os1-share.txt', 'michiel', 'ocmstub1.docker')
  })

  it('Receive federated share <file> from ownCloud v10 to OcmStub v1.0.0', () => {
    // accept share from OcmStub 1.
    cy.loginOcmStub('https://ocmstub1.docker/?')

    cy.contains('"shareWith": "michiel@ocmstub1.docker"').should('be.visible')
    cy.contains('"shareType": "user"').should('be.visible')
    cy.contains('"name": "oc1-to-os1-share.txt"').should('be.visible')
    cy.contains('"resourceType": "file"').should('be.visible')
    cy.contains('"owner": "marie@https://owncloud1.docker"').should('be.visible')
    cy.contains('"sender": "marie@https://owncloud1.docker"').should('be.visible')
    cy.contains('"ownerDisplayName": "marie"').should('be.visible')
    cy.contains('"protocol": { "name": "webdav", "options": { "sharedSecret": "').should('be.visible')
  })
})
