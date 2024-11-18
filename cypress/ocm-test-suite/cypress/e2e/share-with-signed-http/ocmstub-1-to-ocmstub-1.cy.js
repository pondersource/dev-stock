describe('Native federated sharing functionality for OcmStub', () => {
  it('Send federated share <file> from OcmStub 1.0 to OcmStub 1.0', () => {
    cy.visit('https://ocmstub1.docker/shareWith?marie@ocmstub2.docker')
    cy.contains('yes shareWith').should('be.visible')
  })

  it('Receive federated share <file> from OcmStub 1.0 to OcmStub 1.0', () => {
    // accept share from OcmStub 2.
    cy.loginOcmStub('https://ocmstub2.docker/?')

    cy.contains('"shareWith": "marie@ocmstub2.docker"').should('be.visible')
    cy.contains('"shareType": "user"').should('be.visible')
    cy.contains('"name": "Test share from stub"').should('be.visible')
    cy.contains('"resourceType": "file"').should('be.visible')
    cy.contains('"owner": "einstein@ocmstub1.docker"').should('be.visible')
    cy.contains('"sender": "einstein@ocmstub1.docker"').should('be.visible')
    cy.contains('"ownerDisplayName": "einstein"').should('be.visible')
    cy.contains('"protocol": { "name": "webdav", "options": { "sharedSecret": "').should('be.visible')
  })
})
