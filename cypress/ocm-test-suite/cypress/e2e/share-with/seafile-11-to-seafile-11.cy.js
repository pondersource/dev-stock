describe('Native federated sharing functionality for Seafile', () => {
  it('Send federated share from Seafile to Seafile', () => {
    // share from Seafile 1.
    cy.loginSeafile('http://seafile1.docker', 'jonathan@seafile.com', 'xu')

    // cy.get('*[role^="dialog"]')
    //   .find('*[class^="modal-dialog"]')
    //   .find('*[class^="modal-content"]')
    //   .find('*[class^="modal-body"]')
    //   .find('button')
    //   .click()

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

  it('Receive federated share from Seafile to Seafile', () => {
    cy.loginSeafile('http://seafile2.docker', 'giuseppe@cern.ch', 'lopresti')

    // cy.get('*[role^="dialog"]')
    //   .find('*[class^="modal-dialog"]')
    //   .find('*[class^="modal-content"]')
    //   .find('*[class^="modal-body"]')
    //   .find('button')
    //   .click()

    cy.get('*[id^="wrapper"]')
      .find('*[class^="side-panel"]')
      .find('*[class^="side-panel-center"]')
      .find('*[class^="side-nav"]')
      .find('*[class^="side-nav-con"]')
      .find('ul>li')
      .eq(5)
      .click()

    // TODO: verify share received: 1. check for file name existence, 2. check if it can be downloaded, 3. compare checksum to the original file to make sure it is the same file.
  })
})
