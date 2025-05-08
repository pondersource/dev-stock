/**
 * @fileoverview
 * Cypress test suite for testing native federated sharing functionality in ownCloud and Nextcloud.
 * This suite verifies the ability to send and receive federated file shares between ownCloud and Nextcloud.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  getUtils
} from '../utils/index.js';

describe('OCM federated sharing functionality for ownCloud', () => {
  // Shared variables to avoid repetition and improve maintainability
  const senderVersion = Cypress.env('EFSS_PLATFORM_1_VERSION') ?? 'v10';
  const recipientVersion = Cypress.env('EFSS_PLATFORM_2_VERSION') ?? 'v27';
  const senderUrl = Cypress.env('OWNCLOUD1_URL') || 'https://owncloud1.docker';
  const recipientUrl = Cypress.env('NEXTCLOUD1_URL') || 'https://nextcloud1.docker';
  const senderUsername = Cypress.env('OWNCLOUD1_USERNAME') || 'marie';
  const senderPassword = Cypress.env('OWNCLOUD1_PASSWORD') || 'radioactivity';
  const recipientUsername = Cypress.env('NEXTCLOUD1_USERNAME') || 'einstein';
  const recipientPassword = Cypress.env('NEXTCLOUD1_PASSWORD') || 'relativity';
  const originalFileName = 'welcome.txt';
  const sharedFileName = 'share-with-oc1-to-nc1.txt';

  // Get the right helper set for each side
  const senderUtils = getUtils('owncloud', senderVersion);
  const recipientUtils = getUtils('nextcloud', recipientVersion);

  /**
   * Test Case: Sending a federated share from one ownCloud to Nextcloud.
   * Validates that a file can be successfully shared from ownCloud to Nextcloud.
   */
  it('Send a federated share of a file from ownCloud to Nextcloudn v27', () => {
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
   * Test Case: Receiving and accepting a federated share on the recipient's Nextcloud instance.
   * Validates that the recipient can successfully accept the share and view the shared file.
   */
  it('Receive federated share of a file from ownCloud to Nextcloud v27', () => {
    // Step 1: Log in to the recipient's Nextcloud instance
    cy.loginNextcloud(recipientUrl, recipientUsername, recipientPassword);

    // Step 2: Handle any share acceptance pop-ups and verify the file exists
    recipientUtils.handleShareAcceptance(sharedFileName);
  });
})
