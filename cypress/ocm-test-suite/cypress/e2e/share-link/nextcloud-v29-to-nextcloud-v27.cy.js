/**
 * @fileoverview
 * Cypress test suite for testing federated share link functionality between Nextcloud v29 and v27.
 * This suite verifies the ability to send and receive federated file shares via share links between
 * Nextcloud v29 and Nextcloud v27 instances.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  createAndSendShareLinkV29,
  renameFileV29,
  ensureFileExistsV29,
} from '../utils/nextcloud-v29';

import {
  handleShareAcceptanceV27,
} from '../utils/nextcloud-v27';

describe('Share Link Federated Sharing Functionality for Nextcloud', () => {
  // Shared variables to avoid repetition and improve maintainability
  const senderUrl = Cypress.env('NEXTCLOUD1_URL') || 'https://nextcloud1.docker';
  const recipientUrl = Cypress.env('NEXTCLOUD2_URL') || 'https://nextcloud2.docker';
  const senderUsername = Cypress.env('NEXTCLOUD1_USERNAME') || 'einstein';
  const senderPassword = Cypress.env('NEXTCLOUD1_PASSWORD') || 'relativity';
  const recipientUsername = Cypress.env('NEXTCLOUD2_USERNAME') || 'michiel';
  const recipientPassword = Cypress.env('NEXTCLOUD2_PASSWORD') || 'dejong';
  const originalFileName = 'welcome.txt';
  const sharedFileName = 'share-link-nc1-to-nc2.txt';

  /**
   * Test Case: Sending a federated share link from Nextcloud v29 to Nextcloud v27.
   * Validates that a file can be successfully shared via link from Nextcloud v29 to Nextcloud v27.
   */
  it('Send federated share link of a file from Nextcloud v29 to Nextcloud v27', () => {
    // Step 1: Log in to the sender's Nextcloud instance
    cy.loginNextcloud(senderUrl, senderUsername, senderPassword);

    // Step 2: Ensure the original file exists before renaming
    ensureFileExistsV29(originalFileName);

    // Step 3: Rename the file to prepare it for sharing
    renameFileV29(originalFileName, sharedFileName);

    // Step 4: Verify the file has been renamed
    ensureFileExistsV29(sharedFileName);

    // Step 5: Create and send the share link to the recipient
    createAndSendShareLinkV29(
      sharedFileName,
      recipientUsername,
      recipientUrl.replace(/^https?:\/\/|\/$/g, '')
    );
  });

  /**
   * Test Case: Receiving and accepting a federated share link on the recipient's Nextcloud instance.
   * Validates that the recipient can successfully accept the share link and view the shared file.
   */
  it('Receive federated share link of a file from Nextcloud v29 to Nextcloud v27', () => {
    // Step 1: Log in to the recipient's Nextcloud instance
    cy.loginNextcloud(recipientUrl, recipientUsername, recipientPassword);

    // Step 2: Handle any share acceptance pop-ups and verify the file exists
    handleShareAcceptanceV27(sharedFileName);

    // TODO @MahdiBaghbani: Download or open the file to verify content (if required)
  });
});
