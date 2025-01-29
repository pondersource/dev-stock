/**
 * @fileoverview
 * Cypress test suite for testing native federated sharing functionality in OcmStub v1 and ownCloud v10.
 * This suite verifies the ability to send and receive federated file shares between OcmStub and ownCloud.
 *
 * @author Michiel B. de Jong <michiel@pondersource.com>
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  acceptShare,
  ensureFileExists,
  selectAppFromLeftSide,
} from '../utils/owncloud-v10';

describe('Federated sharing functionality from OcmStub to ownCloud', () => {

  // Shared variables to avoid repetition and improve maintainability
  const senderUrl = Cypress.env('OCMSTUB1_URL') || 'https://ocmstub1.docker';
  const recipientUrl = Cypress.env('OWNCLOUD1_URL') || 'https://owncloud1.docker';
  const recipientUsername = Cypress.env('OWNCLOUD1_USERNAME') || 'einstein';
  const recipientPassword = Cypress.env('OWNCLOUD1_PASSWORD') || 'relativity';
  const expectedMessage = 'yes shareWith';
  const sharedFileName = 'from-stub.txt';

  /**
   * Test Case: Sending a federated share from OcmStub to ownCloud .
   * Validates that a file can be successfully shared from OcmStub to ownCloud.
   */
  it('Send a federated share of a file from OcmStub v1 to ownCloud v10', () => {
    // Step 1: Navigate to the federated share link on OcmStub 1.0
    // Remove trailing slash and leading https or http from recipientUrl
    cy.visit(`${senderUrl}/shareWith?${recipientUsername}@${recipientUrl.replace(/^https?:\/\/|\/$/g, '')}`);

    // Step 2: Verify the confirmation message is displayed
    cy.contains(expectedMessage, { timeout: 10000 })
      .should('be.visible')
  });

  /**
   * Test Case: Receiving and accepting a federated share on the recipient's ownCloud instance.
   * Validates that the recipient can successfully accept the share and view the shared file.
   */
  it('Receive federated share of a file from OcmStub v1 to ownCloud v10', () => {
    // Step 1: Log in to the recipient's ownCloud instance
    cy.loginOwncloud(recipientUrl, recipientUsername, recipientPassword);

    // Step 2: Wait for the share dialog to appear and accept the incoming federated share
    acceptShare();

    // Step 3: Navigate to the correct section
    selectAppFromLeftSide('files');

    // Step 4: Verify that the shared file is visible
    ensureFileExists(sharedFileName);

    // TODO @MahdiBaghbani: Download or open the file to verify content (if required)
  });
});
