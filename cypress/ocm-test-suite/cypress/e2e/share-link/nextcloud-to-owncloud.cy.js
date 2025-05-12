/**
 * @fileoverview
 * Cypress test suite for testing federated share link functionality between Nextcloud and ownCloud.
 * This suite verifies the ability to send and receive federated file shares via share links between
 * Nextcloud and ownCloud instances.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  getUtils
} from '../utils/index.js';

describe('Share Link Federated Sharing Functionality for Nextcloud to ownCloud', () => {
  // Shared variables to avoid repetition and improve maintainability
  const senderPlatform = Cypress.env('EFSS_PLATFORM_1') ?? 'nextcloud';
  const recipientPlatform = Cypress.env('EFSS_PLATFORM_2') ?? 'owncloud';
  const senderVersion = Cypress.env('EFSS_PLATFORM_1_VERSION') ?? 'v27';
  const recipientVersion = Cypress.env('EFSS_PLATFORM_2_VERSION') ?? 'v10';
  const senderUrl = Cypress.env('NEXTCLOUD1_URL') || 'https://nextcloud1.docker';
  const recipientUrl = Cypress.env('OWNCLOUD1_URL') || 'https://owncloud1.docker';
  const senderUsername = Cypress.env('NEXTCLOUD1_USERNAME') || 'einstein';
  const senderPassword = Cypress.env('NEXTCLOUD1_PASSWORD') || 'relativity';
  const recipientUsername = Cypress.env('OWNCLOUD1_USERNAME') || 'marie';
  const recipientPassword = Cypress.env('OWNCLOUD1_PASSWORD') || 'radioactivity';
  const originalFileName = 'welcome.txt';
  const sharedFileName = 'share-link-nc1-to-oc1.txt';

  // Get the right helper set for each side
  const senderUtils = getUtils('nextcloud', senderVersion);
  const recipientUtils = getUtils('owncloud', recipientVersion);

  /**
   * Test Case: Sending a federated share link from Nextcloud to ownCloud.
   * Validates that a file can be successfully shared via link from Nextcloud to ownCloud.
   */
  it('Send federated share link of a file from Nextcloud to ownCloud', () => {
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
   * Test Case: Receiving and accepting a federated share link on the recipient's ownCloud instance.
   * Validates that the recipient can successfully accept the share link and view the shared file.
   */
  it('Receive federated share link of a file from Nextcloud to ownCloud', () => {
    // Step 1: Log in to the recipient's ownCloud instance
    cy.loginOwncloud(recipientUrl, recipientUsername, recipientPassword);

    // Step 2: Accept the share dialog
    recipientUtils.handleShareAcceptance(sharedFileName);
  });
});
