describe('Native federated sharing functionality for Seafile', () => {
  it('Send federated share <file> from Seafile 11 to Seafile 11', () => {
    // share from Seafile 1.
    cy.loginSeafile('http://seafile1.docker', 'jonathan@seafile.com', 'xu')

    cy.get('*[role^="dialog"]')
      .find('*[class^="modal-dialog"]')
      .find('*[class^="modal-content"]')
      .find('*[class^="modal-body"]')
      .find('button')
      .click()

    cy.get('*[id^="wrapper"]')
      .find('*[class^="main-panel"]')
      .find('*[class^="reach-router"]')
      .find('*[class^="main-panel-center"]')
      .find('*[class^="cur-view-container"]')
      .find('*[class^="cur-view-content"]')
      .find('table>tbody')
      .eq(0)
      .find('tr>td')
      .eq(3).trigger('mouseover')

    cy.get('*[id^="wrapper"]')
      .find('*[class^="main-panel"]')
      .find('*[class^="reach-router"]')
      .find('*[class^="main-panel-center"]')
      .find('*[class^="cur-view-container"]')
      .find('*[class^="cur-view-content"]')
      .find('table>tbody')
      .eq(0)
      .find('tr>td')
      .eq(3)
      .find('*[title^="Share"]')
      .click()

    cy.get('*[class^="share-dialog-side"]')
      .find('ul>li')
      .eq(4)
      .click()

    cy.get('*[id^="share-to-other-server-panel"]')
      .find('table>tbody')
      .eq(0)
      .find('tr>td')
      .eq(0)
      .find('svg')
      .click()

    cy.get('*[role^="dialog"]')
      .contains(/^seafile\w+/)
      .click()

    cy.get('*[id^="share-to-other-server-panel"]')
      .find('table>tbody')
      .eq(0)
      .find('tr>td')
      .eq(1)
      .within(() => {
          cy.get('input[class="form-control"]').type('giuseppe@cern.ch')
      })

    cy.get('*[id^="share-to-other-server-panel"]')
      .find('table>tbody')
      .eq(0)
      .find('tr>td')
      .eq(3)
      .contains('Submit')
      .click()

  })

  it('Receive federated share <file> from ownCloud v10 to OcmStub 1.0', () => {
    // accept share from OcmStub 2.
    cy.loginOcmStub('https://ocmstub2.docker/?')

    cy.contains('"shareWith": "michiel@https://ocmstub2.docker"').should('be.visible')
    cy.contains('"shareType": "user"').should('be.visible')
    cy.contains('"name": "nc1-to-os2-share.txt"').should('be.visible')
    cy.contains('"resourceType": "file"').should('be.visible')
    cy.contains('"owner": "einstein@https://seafile1.docker/"').should('be.visible')
    cy.contains('"sharedBy": "einstein@https://seafile1.docker/"').should('be.visible')
    cy.contains('"ownerDisplayName": "einstein"').should('be.visible')
    cy.contains('"description": ""').should('be.visible')
    cy.contains('"shareWith": "michiel@https://ocmstub2.docker"').should('be.visible')
    cy.contains('"protocol": { "name": "webdav", "options": { "sharedSecret": "').should('be.visible')
    cy.contains('"permissions": "{http://open-cloud-mesh.org/ns}share-permissions"').should('be.visible')
  })
})
