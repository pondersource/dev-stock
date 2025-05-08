/**
 * @fileoverview
 * Cypress test suite for testing federated share link functionality between Nextclouds.
 * This suite verifies the ability to send and receive federated file shares via share links between
 * Nextcloud instances.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  getUtils
} from '../utils/index.js';

describe('Share Link Federated Sharing Functionality for Nextcloud', () => {
  // Shared variables to avoid repetition and improve maintainability
  const senderVersion = Cypress.env('EFSS_PLATFORM_1_VERSION') ?? 'v27';
  const recipientVersion = Cypress.env('EFSS_PLATFORM_2_VERSION') ?? 'v27';
  const senderUrl = Cypress.env('NEXTCLOUD1_URL') || 'https://nextcloud1.docker';
  const recipientUrl = Cypress.env('NEXTCLOUD2_URL') || 'https://nextcloud2.docker';
  const senderUsername = Cypress.env('NEXTCLOUD1_USERNAME') || 'einstein';
  const senderPassword = Cypress.env('NEXTCLOUD1_PASSWORD') || 'relativity';
  const recipientUsername = Cypress.env('NEXTCLOUD2_USERNAME') || 'michiel';
  const recipientPassword = Cypress.env('NEXTCLOUD2_PASSWORD') || 'dejong';
  const originalFileName = 'welcome.txt';
  const sharedFileName = 'share-link-nc1-to-nc2.txt';

  // Get the right helper set for each side
  const senderUtils = getUtils('nextcloud', senderVersion);
  const recipientUtils = getUtils('nextcloud', recipientVersion);

  /**
   * Test Case: Sending a federated share link from Nextcloud to Nextcloud.
   * Validates that a file can be successfully shared via link from Nextcloud to Nextcloud.
   */
  it('Send federated share link of a file from Nextcloud to Nextcloud', () => {
    senderUtils.shareViaFederatedLink({
      senderUrl,
      senderUsername,
      senderPassword,
      originalFileName,
      sharedFileName,
      recipientUsername,
      recipientUrl,
    });
  });

  /**
   * Test Case: Receiving and accepting a federated share link on the recipient's Nextcloud instance.
   * Validates that the recipient can successfully accept the share link and view the shared file.
   */
  it('Receive federated share link of a file from Nextcloudto Nextcloud', () => {
    // Step 1: Log in to the recipient's Nextcloud instance
    cy.loginNextcloud(recipientUrl, recipientUsername, recipientPassword);

    // Step 2: Handle any share acceptance pop-ups and verify the file exists
    recipientUtils.handleShareAcceptance(sharedFileName);

    // TODO @MahdiBaghbani: Download or open the file to verify content (if required)
  });
});
