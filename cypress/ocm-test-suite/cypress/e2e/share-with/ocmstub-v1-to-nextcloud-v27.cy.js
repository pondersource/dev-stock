/**
 * @fileoverview
 * Cypress test suite for testing native federated sharing functionality in OcmStub v1 and Nextcloud v27.
 * This suite verifies the ability to send and receive federated file shares between OcmStub and Nextcloud.
 *
 * @author Michiel B. de Jong <michiel@pondersource.com>
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  acceptShareV27,
  ensureFileExistsV27,
} from '../utils/nextcloud-v27';

describe('Federated sharing functionality from OcmStub to Nextcloud', () => {

  // Shared variables to avoid repetition and improve maintainability
  const senderUrl = Cypress.env('OCMSTUB1_URL') || 'https://ocmstub1.docker';
  const recipientUrl = Cypress.env('NEXTCLOUD1_URL') || 'https://nextcloud1.docker';
  const recipientUsername = Cypress.env('NEXTCLOUD1_USERNAME') || 'einstein';
  const recipientPassword = Cypress.env('NEXTCLOUD1_PASSWORD') || 'relativity';
  const expectedMessage = 'yes shareWith';
  const sharedFileName = 'from-stub.txt';

  /**
   * Test Case: Sending a federated share from OcmStub 1.0 to OcmStub 1.0.
   */
  it('should successfully send a federated share of a file from OcmStub v1 to Nextcloud v27', () => {
    // Step 1: Navigate to the federated share link on OcmStub 1.0
    // Remove trailing slash and leading https or http from recipientUrl
    cy.visit(`${senderUrl}/shareWith?${recipientUsername}@${recipientUrl.replace(/^https?:\/\/|\/$/g, '')}`);

    // Step 2: Verify the confirmation message is displayed
    cy.contains(expectedMessage, { timeout: 10000 })
      .should('be.visible')
  });

  /**
   * Test Case: Receiving and accepting a federated share on the recipient's Nextcloud instance.
   * Validates that the recipient can successfully accept the share and view the shared file.
   */
  it('Receive federated share of a file from OcmStub v1 to Nextcloud v27', () => {
    // Step 1: Log in to the recipient's Nextcloud instance
    cy.loginNextcloud(recipientUrl, recipientUsername, recipientPassword);

    // Step 2: Wait for the share dialog to appear and accept the incoming federated share
    acceptShareV27();

    // Step 3: Reload the page to ensure the shared file appears in the file list
    cy.reload(true);

    // Step 4: Verify the shared file is visible
    ensureFileExistsV27(sharedFileName);

    // TODO @MahdiBaghbani: Download or open the file to verify content (if required)
  });
});
