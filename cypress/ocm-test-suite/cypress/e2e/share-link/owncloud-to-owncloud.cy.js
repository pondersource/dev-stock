/**
 * @fileoverview
 * Cypress test suite for testing federated share link functionality in ownCloud.
 * This suite verifies the ability to send and receive federated file shares via share links between two ownCloud instances.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  getUtils
} from '../utils/index.js';

import {
  constructFederatedShareUrl,
} from '../utils/general';

describe('Share Link Federated Sharing Functionality for ownCloud', () => {
  // Shared variables to avoid repetition and improve maintainability
  const senderVersion = Cypress.env('EFSS_PLATFORM_1_VERSION') ?? 'v10';
  const recipientVersion = Cypress.env('EFSS_PLATFORM_2_VERSION') ?? 'v10';
  const senderUrl = Cypress.env('OWNCLOUD1_URL') || 'https://owncloud1.docker';
  const recipientUrl = Cypress.env('OWNCLOUD2_URL') || 'https://owncloud2.docker';
  const senderUsername = Cypress.env('OWNCLOUD1_USERNAME') || 'marie';
  const senderPassword = Cypress.env('OWNCLOUD1_PASSWORD') || 'radioactivity';
  const recipientUsername = Cypress.env('OWNCLOUD2_USERNAME') || 'mahdi';
  const recipientPassword = Cypress.env('OWNCLOUD2_PASSWORD') || 'baghbani';
  const originalFileName = 'welcome.txt';
  const sharedFileName = 'share-link-oc1-to-oc2.txt';

  // Get the right helper set for each side
  const senderUtils = getUtils('owncloud', senderVersion);
  const recipientUtils = getUtils('owncloud', recipientVersion);

  /**
   * Test Case: Sending a federated share link from one ownCloud instance to another.
   * Validates that a file can be successfully shared via link from ownCloud Instance 1 to ownCloud Instance 2.
   */
  it('Send federated share link of a file from ownCloud to ownCloud', () => {
    senderUtils.shareViaFederatedLink({
      senderUrl,
      senderUsername,
      senderPassword,
      originalFileName,
      sharedFileName,
    });
  });

  /**
   * Test Case: Receiving and accepting a federated share link on the recipient's ownCloud instance.
   * Validates that the recipient can successfully accept the share link and view the shared file.
   */
  it('Receive federated share link of a file from ownCloud to ownCloud', () => {
    // Step 1: Log in to the recipient's ownCloud instance
    cy.loginOwncloud(recipientUrl, recipientUsername, recipientPassword);

    // Step 2: Read the share URL from file
    cy.readFile('share-link-url.txt').then((shareUrl) => {
      // Step 3: Construct the federated share URL
      const federatedShareUrl = constructFederatedShareUrl({
        shareUrl,
        senderUrl,
        recipientUrl,
        senderUsername,
        fileName: sharedFileName,
        platform: 'owncloud'
      });

      // Step 4: Visit the federated share URL
      cy.visit(federatedShareUrl);

      // Step 5: Accept the share dialog
      recipientUtils.handleShareAcceptance(sharedFileName);
    });
  });
});
