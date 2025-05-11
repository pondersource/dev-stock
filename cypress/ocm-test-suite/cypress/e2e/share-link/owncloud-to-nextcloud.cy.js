/**
 * @fileoverview
 * Cypress test suite for testing federated share link functionality between ownCloud and Nextcloud.
 * This suite verifies the ability to send and receive federated file shares via share links between
 * ownCloud and Nextcloud instances.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  getUtils
} from '../utils/index.js';

import {
  constructFederatedShareUrl,
} from '../utils/general';

describe('Share Link Federated Sharing Functionality for ownCloud to Nextcloud', () => {
  // Shared variables to avoid repetition and improve maintainability
  const senderPlatform = Cypress.env('EFSS_PLATFORM_1') ?? 'owncloud';
  const recipientPlatform = Cypress.env('EFSS_PLATFORM_2') ?? 'nextcloud';
  const senderVersion = Cypress.env('EFSS_PLATFORM_1_VERSION') ?? 'v10';
  const recipientVersion = Cypress.env('EFSS_PLATFORM_2_VERSION') ?? 'v27';
  const senderUrl = Cypress.env('OWNCLOUD1_URL') || 'https://owncloud1.docker';
  const recipientUrl = Cypress.env('NEXTCLOUD1_URL') || 'https://nextcloud1.docker';
  const senderUsername = Cypress.env('OWNCLOUD1_USERNAME') || 'marie';
  const senderPassword = Cypress.env('OWNCLOUD1_PASSWORD') || 'radioactivity';
  const recipientUsername = Cypress.env('NEXTCLOUD1_USERNAME') || 'einstein';
  const recipientPassword = Cypress.env('NEXTCLOUD1_PASSWORD') || 'relativity';
  const originalFileName = 'welcome.txt';
  const sharedFileName = 'share-link-oc1-to-nc1.txt';

  // Get the right helper set for each side
  const senderUtils = getUtils(senderPlatform, senderVersion);
  const recipientUtils = getUtils(recipientPlatform, recipientVersion);

  /**
   * Test Case: Sending a federated share link from ownCloud to Nextcloud.
   * Validates that a file can be successfully shared via link from ownCloud to Nextcloud.
   */
  it('Send federated share link of a file from ownCloud to Nextcloud', () => {
    senderUtils.shareViaFederatedLink({
      senderUrl,
      senderUsername,
      senderPassword,
      originalFileName,
      sharedFileName,
    });
  });

  /**
   * Test Case: Receiving and accepting a federated share link on the recipient's Nextcloud instance.
   * Validates that the recipient can successfully accept the share link and view the shared file.
   */
  it('Receive federated share link of a file from ownCloud to Nextcloud', () => {
    // Step 1: Log in to the recipient's Nextcloud instance
    recipientUtils.login(recipientUrl, recipientUsername, recipientPassword);

    // Step 2: Read the share URL from file
    cy.readFile('share-link-url.txt').then((shareUrl) => {
      // Step 3: Construct the federated share URL
      const federatedShareUrl = constructFederatedShareUrl({
        shareUrl,
        senderUrl,
        recipientUrl,
        senderUsername,
        fileName: sharedFileName,
        platform: recipientPlatform
      });

      recipientUtils.acceptFederatedLinkShare({
        recipientUrl: federatedShareUrl,
        recipientUsername,
        recipientPassword,
        sharedFileName,
      });
    });
  });
});
