/**
 * @fileoverview
 * Cypress test suite for testing native federated sharing functionality in ownCloud v10.
 * This suite verifies the ability to send and receive federated file shares between two ownCloud instances.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  acceptShare,
  createShare,
  renameFile,
  ensureFileExists,
  selectAppFromLeftSide,
} from '../utils/owncloud';

describe('Native federated sharing functionality for ownCloud', () => {

  // Shared variables to avoid repetition and improve maintainability
  const senderUrl = Cypress.env('OWNCLOUD1_URL') || 'https://owncloud1.docker';
  const recipientUrl = Cypress.env('OWNCLOUD2_URL') || 'https://owncloud2.docker';
  const senderUsername = Cypress.env('OWNCLOUD1_USERNAME') || 'marie';
  const senderPassword = Cypress.env('OWNCLOUD1_PASSWORD') || 'radioactivity';
  const recipientUsername = Cypress.env('OWNCLOUD2_USERNAME') || 'mahdi';
  const recipientPassword = Cypress.env('OWNCLOUD2_PASSWORD') || 'baghbani';
  const originalFileName = 'welcome.txt';
  const sharedFileName = 'share-with-oc1-to-oc2.txt';

  /**
   * Test Case: Sending a federated share from one ownCloud instance to another.
   * Validates that a file can be successfully shared from ownCloud Instance 1 to ownCloud Instance 2.
   */
  it('Send a federated share of a file from ownCloud v10 to ownCloud v10', () => {
    // Step 1: Log in to the sender's ownCloud instance
    cy.loginOwncloud(senderUrl, senderUsername, senderPassword);

    // Step 2: Ensure the original file exists
    ensureFileExists(originalFileName);

    // Step 3: Rename the file
    renameFile(originalFileName, sharedFileName);

    // Step 4: Verify the file has been renamed
    ensureFileExists(sharedFileName);

    // Step 5: Create a federated share for the recipient
    createShare(sharedFileName, recipientUsername, recipientUrl.replace(/^https?:\/\/|\/$/g, ''));

    // TODO @MahdiBaghbani: Verify that the share was created successfully
  });

  /**
   * Test Case: Receiving and accepting a federated share on the recipient's ownCloud instance.
   * Validates that the recipient can successfully accept the share and view the shared file.
   */
  it('Receive federated share of a file from ownCloud v10 to ownCloud v10', () => {
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
})
