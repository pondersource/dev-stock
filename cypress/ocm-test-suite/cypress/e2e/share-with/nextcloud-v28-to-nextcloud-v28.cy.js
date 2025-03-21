/**
 * @fileoverview
 * Cypress test suite for testing native federated sharing functionality in Nextcloud v28.
 * This suite verifies the ability to send and receive federated file shares between two Nextcloud v28 instances.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  createShareV28,
  renameFileV28,
  ensureFileExistsV28,
  handleShareAcceptanceV28,
} from '../utils/nextcloud-v28';

describe('Native Federated Sharing Functionality for Nextcloud v28', () => {

  // Shared variables to avoid repetition and improve maintainability
  const senderUrl = Cypress.env('NEXTCLOUD1_URL') || 'https://nextcloud1.docker';
  const recipientUrl = Cypress.env('NEXTCLOUD2_URL') || 'https://nextcloud2.docker';
  const senderUsername = Cypress.env('NEXTCLOUD1_USERNAME') || 'einstein';
  const senderPassword = Cypress.env('NEXTCLOUD1_PASSWORD') || 'relativity';
  const recipientUsername = Cypress.env('NEXTCLOUD2_USERNAME') || 'michiel';
  const recipientPassword = Cypress.env('NEXTCLOUD2_PASSWORD') || 'dejong';
  const originalFileName = 'welcome.txt';
  const sharedFileName = 'share-with-nc1-to-nc2.txt';

  /**
   * Test Case: Sending a federated share from one Nextcloud instance to another.
   * Validates that a file can be successfully shared from Nextcloud Instance 1 to Nextcloud Instance 2.
   */
  it('Send a federated share of a file from Nextcloud v28 to Nextcloud v28', () => {
    // Step 1: Log in to the sender's Nextcloud instance
    cy.loginNextcloud(senderUrl, senderUsername, senderPassword);

    // Step 2: Ensure the original file exists before renaming
    ensureFileExistsV28(originalFileName);

    // Step 3: Rename the file to prepare it for sharing
    renameFileV28(originalFileName, sharedFileName);

    // Step 4: Verify the file has been renamed
    ensureFileExistsV28(sharedFileName);

    // Step 5: Create a federated share for the recipient
    createShareV28(sharedFileName, recipientUsername, recipientUrl.replace(/^https?:\/\/|\/$/g, ''));

    // TODO @MahdiBaghbani: Verify that the share was created successfully
  });

  /**
   * Test Case: Receiving and accepting a federated share on the recipient's Nextcloud instance.
   * Validates that the recipient can successfully accept the share and view the shared file.
   */
  it('Receive federated share of a file from Nextcloud v28 to Nextcloud v28', () => {
    // Step 1: Log in to the recipient's Nextcloud instance
    cy.loginNextcloud(recipientUrl, recipientUsername, recipientPassword);

    // Step 2: Handle any share acceptance pop-ups and verify the file exists
    handleShareAcceptanceV28(sharedFileName);

    // TODO @MahdiBaghbani: Download or open the file to verify content (if required)
  });
});
