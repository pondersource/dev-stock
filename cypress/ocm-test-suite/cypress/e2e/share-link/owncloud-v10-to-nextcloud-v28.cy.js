/**
 * @fileoverview
 * Cypress test suite for testing federated share link functionality between ownCloud v10 and Nextcloud v28.
 * This suite verifies the ability to send and receive federated file shares via share links between
 * ownCloud v10 and Nextcloud v28 instances.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  createShareLink,
  renameFile,
  ensureFileExistsOcV10,
} from '../utils/owncloud-v10';

import {
  handleShareAcceptanceV28,
} from '../utils/nextcloud-v28';

import {
  constructFederatedShareUrl,
} from '../utils/general';

describe('Share Link Federated Sharing Functionality for ownCloud to Nextcloud', () => {
  // Shared variables to avoid repetition and improve maintainability
  const senderUrl = Cypress.env('OWNCLOUD1_URL') || 'https://owncloud1.docker';
  const recipientUrl = Cypress.env('NEXTCLOUD1_URL') || 'https://nextcloud1.docker';
  const senderUsername = Cypress.env('OWNCLOUD1_USERNAME') || 'marie';
  const senderPassword = Cypress.env('OWNCLOUD1_PASSWORD') || 'radioactivity';
  const recipientUsername = Cypress.env('NEXTCLOUD1_USERNAME') || 'einstein';
  const recipientPassword = Cypress.env('NEXTCLOUD1_PASSWORD') || 'relativity';
  const originalFileName = 'welcome.txt';
  const sharedFileName = 'share-link-oc1-to-nc1.txt';

  /**
   * Test Case: Sending a federated share link from ownCloud v10 to Nextcloud v28.
   * Validates that a file can be successfully shared via link from ownCloud v10 to Nextcloud v28.
   */
  it('Send federated share link of a file from ownCloud v10 to Nextcloud v28', () => {
    // Step 1: Log in to the sender's ownCloud instance
    cy.loginOwncloud(senderUrl, senderUsername, senderPassword);

    // Step 2: Ensure the original file exists before renaming
    ensureFileExistsOcV10(originalFileName);

    // Step 3: Rename the file to prepare it for sharing
    renameFile(originalFileName, sharedFileName);

    // Step 4: Verify the file has been renamed
    ensureFileExistsOcV10(sharedFileName);

    // Step 5: Create a share link for the file
    createShareLink(sharedFileName);
  });

  /**
   * Test Case: Receiving and accepting a federated share link on the recipient's Nextcloud instance.
   * Validates that the recipient can successfully accept the share link and view the shared file.
   */
  it('Receive federated share link of a file from ownCloud v10 to Nextcloud v28', () => {
    // Step 1: Log in to the recipient's Nextcloud instance
    cy.loginNextcloudCore(recipientUrl, recipientUsername, recipientPassword);

    // Step 2: Read the share URL from file
    cy.readFile('share-link-url.txt').then((shareUrl) => {
      // Step 3: Construct the federated share URL
      const federatedShareUrl = constructFederatedShareUrl({
        shareUrl,
        senderUrl,
        recipientUrl,
        senderUsername,
        fileName: sharedFileName,
        platform: 'nextcloud'
      });

      // Step 4: Visit the federated share URL
      cy.visit(federatedShareUrl);

      // Step 5: Handle share acceptance and verify the file exists
      handleShareAcceptanceV28(sharedFileName);
    });
  });
});
