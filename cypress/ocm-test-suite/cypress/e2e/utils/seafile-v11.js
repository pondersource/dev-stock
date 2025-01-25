/**
 * @fileoverview
 * Utility functions for Cypress tests interacting with Seafile version 11.
 * These functions provide abstractions for common actions such as accepting shares,
 * creating federated shares, renaming files, and interacting with the file menu.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

/**
 * Dismiss any modal dialogs that might be present (e.g., welcome or info dialogs).
 */
export function dismissModalIfPresentV11() {
  // Add any modal dismissal logic specific to v11 here
  cy.get('body').then($body => {
    if ($body.find('.modal-dialog').length > 0) {
      cy.get('.modal-dialog .close').click();
    }
  });
}

/**
 * Open the share dialog for the first file in the list.
 */
export function openShareDialog() {
  cy.get('#wrapper .main-panel .reach-router .main-panel-center .cur-view-container .cur-view-content')
    .find('table tbody')
    .eq(0) // First file
    .find('tr td')
    .eq(3) // Column containing the Share button
    .trigger('mouseover') // Hover to reveal the share button if hidden
    .find('[title="Share"]') // Locate the share button by title attribute
    .should('be.visible')
    .click();
}

/**
 * Open the federated sharing tab in the share dialog.
 */
export function openFederatedSharingTab() {
  cy.get('.share-dialog-side ul li')
    .eq(4) // 5th item in the share dialog side menu is "Federated Sharing"
    .should('be.visible')
    .click();
}

/**
 * Select a remote server from the dropdown.
 * @param {string} serverName - The name of the remote server to select
 */
export function selectRemoteServer(serverName) {
  cy.get('#share-to-other-server-panel table tbody')
    .eq(0)
    .find('tr td svg') // The dropdown trigger
    .eq(0)
    .should('be.visible')
    .click();

  cy.get('[role="dialog"]')
    .contains(new RegExp(`^${serverName}\\w*`))
    .should('be.visible')
    .click();
}

/**
 * Share a file with a remote user.
 * @param {string} remoteUsername - The username of the remote user to share with
 */
export function shareWithRemoteUser(remoteUsername) {
  cy.get('#share-to-other-server-panel table tbody')
    .eq(0)
    .within(() => {
      cy.get('input.form-control')
        .should('be.visible')
        .type(remoteUsername);

      cy.contains('Submit')
        .should('be.visible')
        .click();
    });
}

/**
 * Navigate to the received shares section.
 */
export function navigateToReceivedShares() {
  cy.get('#wrapper .side-panel .side-panel-center .side-nav .side-nav-con ul li')
    .eq(5) // 6th menu item is "Received Shares"
    .should('be.visible')
    .click();
}

/**
 * Verify that a received share is visible in the list.
 */
export function verifyReceivedShare(remoteUsername) {
  cy.get('#wrapper .main-panel .reach-router .main-panel-center .cur-view-container .cur-view-content')
    .find('table tbody')
    .eq(0) // First file
    .find('tr td')
    .eq(3) // Column containing the Share sender
    .should('be.visible')
    .should('contain', remoteUsername);
}
