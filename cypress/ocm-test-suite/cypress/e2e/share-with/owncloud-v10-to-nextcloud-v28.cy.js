/**
 * @fileoverview
 * Cypress test suite for testing native federated sharing functionality in ownCloud v10 and Nextcloud v28.
 * This suite verifies the ability to send and receive federated file shares between ownCloud and Nextcloud.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  handleShareAcceptanceV28,
} from '../utils/nextcloud-v28';

import {
  createShare,
  renameFile,
  ensureFileExists,
} from '../utils/owncloud-v10';

describe('OCM federated sharing functionality for ownCloud', () => {

  // Shared variables to avoid repetition and improve maintainability
  const senderUrl = Cypress.env('OWNCLOUD1_URL') || 'https://owncloud1.docker';
  const recipientUrl = Cypress.env('NEXTCLOUD1_URL') || 'https://nextcloud1.docker';
  const senderUsername = Cypress.env('OWNCLOUD1_USERNAME') || 'marie';
  const senderPassword = Cypress.env('OWNCLOUD1_PASSWORD') || 'radioactivity';
  const recipientUsername = Cypress.env('NEXTCLOUD1_USERNAME') || 'einstein';
  const recipientPassword = Cypress.env('NEXTCLOUD1_PASSWORD') || 'relativity';
  const originalFileName = 'welcome.txt';
  const sharedFileName = 'share-with-oc1-to-nc1.txt';

  /**
   * Test Case: Sending a federated share from one ownCloud to Nextcloud.
   * Validates that a file can be successfully shared from ownCloud to Nextcloud.
   */
  it('Send a federated share of a file from ownCloud v10 to Nextcloudn v28', () => {
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
   * Test Case: Receiving and accepting a federated share on the recipient's Nextcloud instance.
   * Validates that the recipient can successfully accept the share and view the shared file.
   */
  it('Receive federated share of a file from ownCloud v10 to Nextcloud v28', () => {
    // Step 1: Log in to the recipient's Nextcloud instance
    cy.loginNextcloud(recipientUrl, recipientUsername, recipientPassword);

    // Step 2: Handle any share acceptance pop-ups and verify the file exists
    handleShareAcceptanceV28(sharedFileName);

    // TODO @MahdiBaghbani: Download or open the file to verify content (if required)
  });
})
