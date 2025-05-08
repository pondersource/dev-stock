/**
 * @fileoverview
 * Cypress test suite for testing native federated sharing functionality in ownCloud.
 * This suite verifies the ability to send and receive federated file shares between two ownCloud instances.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  getUtils
} from '../utils/index.js';

describe('Native federated sharing functionality for ownCloud', () => {
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
  const sharedFileName = 'share-with-oc1-to-oc2.txt';

  // Get the right helper set for each side
  const senderUtils = getUtils('owncloud', senderVersion);
  const recipientUtils = getUtils('owncloud', recipientVersion);

  /**
   * Test Case: Sending a federated share from one ownCloud instance to another.
   * Validates that a file can be successfully shared from ownCloud Instance 1 to ownCloud Instance 2.
   */
  it('Send a federated share of a file from ownCloud to ownCloud', () => {
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
  it('Receive federated share of a file from ownCloud to ownCloud', () => {
    // Step 1: Log in to the recipient's ownCloud instance
    cy.loginOwncloud(recipientUrl, recipientUsername, recipientPassword);

    // Step 2: Accept the share dialog
    recipientUtils.handleShareAcceptance(sharedFileName);
  });
})
