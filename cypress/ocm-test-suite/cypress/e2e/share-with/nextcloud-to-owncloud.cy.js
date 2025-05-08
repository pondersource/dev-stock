/**
 * @fileoverview
 * Cypress test suite for testing native federated sharing functionality in Nextcloud and ownCloud.
 * This suite verifies the ability to send and receive federated file shares between Nextcloud and ownCloud.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  getUtils
} from '../utils/index.js';

describe('Native Federated Sharing Functionality for Nextcloud to ownCloud', () => {
  // Shared variables to avoid repetition and improve maintainability
  const senderVersion = Cypress.env('EFSS_PLATFORM_1_VERSION') ?? 'v27';
  const recipientVersion = Cypress.env('EFSS_PLATFORM_2_VERSION') ?? 'v10';
  const senderUrl = Cypress.env('NEXTCLOUD1_URL') || 'https://nextcloud1.docker';
  const recipientUrl = Cypress.env('OWNCLOUD1_URL') || 'https://owncloud1.docker';
  const senderUsername = Cypress.env('NEXTCLOUD1_USERNAME') || 'einstein';
  const senderPassword = Cypress.env('NEXTCLOUD1_PASSWORD') || 'relativity';
  const recipientUsername = Cypress.env('OWNCLOUD1_USERNAME') || 'marie';
  const recipientPassword = Cypress.env('OWNCLOUD1_PASSWORD') || 'radioactivity';
  const originalFileName = 'welcome.txt';
  const sharedFileName = 'share-with-nc1-to-oc1.txt';

  // Get the right helper set for each side
  const senderUtils = getUtils('nextcloud', senderVersion);
  const recipientUtils = getUtils('owncloud', recipientVersion);

  /**
   * Test Case: Sending a federated share from one Nextcloud instance to ownCloud.
   * Validates that a file can be successfully shared from Nextcloud to ownCloud.
   */
  it('Send a federated share of a file from Nextcloud to ownCloud', () => {
    senderUtils.shareViaNativeShareWith({
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
   * Test Case: Receiving and accepting a federated share on the recipient's ownCloud instance.
   * Validates that the recipient can successfully accept the share and view the shared file.
   */
  it('Receive federated share of a file from Nextcloud to ownCloud', () => {
    // Step 1: Log in to the recipient's ownCloud instance
    cy.loginOwncloud(recipientUrl, recipientUsername, recipientPassword);

    // Step 2: Handle any share acceptance pop-ups and verify the file exists
    recipientUtils.handleShareAcceptance(sharedFileName);
  });
})
