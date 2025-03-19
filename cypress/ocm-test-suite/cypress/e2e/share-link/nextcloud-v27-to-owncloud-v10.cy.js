/**
 * @fileoverview
 * Cypress test suite for testing federated share link functionality between Nextcloud v27 and ownCloud v10.
 * This suite verifies the ability to send and receive federated file shares via share links between
 * Nextcloud v27 and ownCloud v10 instances.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  createAndSendShareLinkV27,
  renameFileV27,
  ensureFileExistsV27,
} from '../utils/nextcloud-v27';

import {
  handleShareAcceptanceOcV10,
} from '../utils/owncloud-v10';

describe('Share Link Federated Sharing Functionality for Nextcloud to ownCloud', () => {
  // Shared variables to avoid repetition and improve maintainability
  const senderUrl = Cypress.env('NEXTCLOUD1_URL') || 'https://nextcloud1.docker';
  const recipientUrl = Cypress.env('OWNCLOUD1_URL') || 'https://owncloud1.docker';
  const senderUsername = Cypress.env('NEXTCLOUD1_USERNAME') || 'einstein';
  const senderPassword = Cypress.env('NEXTCLOUD1_PASSWORD') || 'relativity';
  const recipientUsername = Cypress.env('OWNCLOUD1_USERNAME') || 'marie';
  const recipientPassword = Cypress.env('OWNCLOUD1_PASSWORD') || 'radioactivity';
  const originalFileName = 'welcome.txt';
  const sharedFileName = 'share-link-nc1-to-oc1.txt';

  /**
   * Test Case: Sending a federated share link from Nextcloud v27 to ownCloud v10.
   * Validates that a file can be successfully shared via link from Nextcloud v27 to ownCloud v10.
   */
  it('Send federated share link of a file from Nextcloud v27 to ownCloud v10', () => {
    // Step 1: Log in to the sender's Nextcloud instance
    cy.loginNextcloud(senderUrl, senderUsername, senderPassword);

    // Step 2: Ensure the original file exists before renaming
    ensureFileExistsV27(originalFileName);

    // Step 3: Rename the file to prepare it for sharing
    renameFileV27(originalFileName, sharedFileName);

    // Step 4: Verify the file has been renamed
    ensureFileExistsV27(sharedFileName);

    // Step 5: Create and send the share link to the recipient
    createAndSendShareLinkV27(
      sharedFileName,
      recipientUsername,
      recipientUrl.replace(/^https?:\/\/|\/$/g, '')
    );
  });

  /**
   * Test Case: Receiving and accepting a federated share link on the recipient's ownCloud instance.
   * Validates that the recipient can successfully accept the share link and view the shared file.
   */
  it('Receive federated share link of a file from Nextcloud v27 to ownCloud v10', () => {
    // Step 1: Log in to the recipient's ownCloud instance
    cy.loginOwncloud(recipientUrl, recipientUsername, recipientPassword);

    // Step 2: Accept the share dialog
    handleShareAcceptanceOcV10(sharedFileName);
  });
});
