/**
 * @fileoverview
 * Cypress test suite for testing native federated sharing functionality in Seafile.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  dismissModalIfPresentV11,
} from '../utils/seafile-v11';

describe('Native federated sharing functionality for Seafile', () => {

  // Shared variables to avoid repetition and improve maintainability
  const senderUrl = Cypress.env('SEAFILE1_URL') || 'http://seafile1.docker';
  const recipientUrl = Cypress.env('SEAFILE2_URL') || 'http://seafile2.docker';
  const senderUsername = Cypress.env('SEAFILE1_USERNAME') || 'jonathan@seafile.com';
  const senderPassword = Cypress.env('SEAFILE1_PASSWORD') || 'xu';
  const recipientUsername = Cypress.env('SEAFILE2_USERNAME') || 'giuseppe@cern.ch';
  const recipientPassword = Cypress.env('SEAFILE2_PASSWORD') || 'lopresti';
  const originalFileName = 'welcome.txt';
  const sharedFileName = 'share-with-nc1-to-nc2.txt';

  /**
   * Test Case: Sending a federated share from Seafile 1 to Seafile 2.
   */
  it('should successfully send a federated share of a file from Seafile 1 to Seafile 2', () => {
    // Step 1: Log in to Seafile 1
    cy.loginSeafile(senderUrl, senderUsername, senderPassword);

    // Step 2: Dismiss any modals if present (e.g., welcome or info dialogs)
    dismissModalIfPresentV11();

    // Step 3: Locate the file to share and open the share menu.
    // Adjust selectors as per actual DOM structure:
    // - eq(0) targets the first file row.
    // - eq(3) selects the 4th column cell in that row (where "Share" button is assumed).
    cy.get('#wrapper .main-panel .reach-router .main-panel-center .cur-view-container .cur-view-content')
      .find('table tbody')
      .eq(0) // First file
      .find('tr td')
      .eq(3) // Column containing the Share button
      .trigger('mouseover') // Hover to reveal the share button if hidden
      .find('[title="Share"]') // Locate the share button by title attribute
      .should('be.visible')
      .click();

    // Step 4: Select the federated sharing option
    // eq(4) is the 5th item in the share dialog side menu, assumed to be "Federated Sharing"
    cy.get('.share-dialog-side ul li')
      .eq(4)
      .should('be.visible')
      .click();

    // Step 5: Select the Seafile server from a dropdown
    // Interact with the server selection dropdown
    cy.get('#share-to-other-server-panel table tbody')
      .eq(0)
      // The dropdown trigger is assumed to be an SVG icon
      .find('tr td svg')
      .eq(0)
      .should('be.visible')
      .click();

    // Select a server from the resulting dialog
    // Using a regex to match a server name that starts with 'seafile' followed by word characters
    cy.get('[role="dialog"]')
      .contains(/^seafile\w+/)
      .should('be.visible')
      .click();

    // Step 6: Enter the recipient's email and submit the share
    // Within the panel, type the recipient email and click "Submit"
    cy.get('#share-to-other-server-panel table tbody')
      .eq(0)
      .within(() => {
        cy.get('input.form-control')
          .should('be.visible')
          .type(recipientUsername);

        cy.contains('Submit')
          .should('be.visible')
          .click();
      });

    // Optional: Add assertions to verify a success message or notification, if available.
  });

  /**
   * Test Case: Receiving a federated share on Seafile 2.
   */
  it('should successfully receive and display a federated share of a file on Seafile 2', () => {
    // Step 1: Log in to Seafile 2
    cy.loginSeafile(recipientUrl, recipientUsername, recipientPassword);

    // Step 2: Dismiss any modals if present (e.g., welcome or info dialogs)
    dismissModalIfPresentV11();

    // Step 3: Navigate to the "Received Shares" section
    // eq(5) selects the 6th menu item in the sidebar assumed to be "Received Shares"
    cy.get('#wrapper .side-panel .side-panel-center .side-nav .side-nav-con ul li')
      .eq(5)
      .should('be.visible')
      .click();

    // Step 4: Validate that the shared file is visible
    // Check that the received shares table is visible and that it has at least one row
    cy.get('.received-shares-table')
      .should('be.visible')
      .find('tr')
      .should('have.length.greaterThan', 0);

    // Optional: Further assertions could be made to verify that the expected file name appears.
  });
});
