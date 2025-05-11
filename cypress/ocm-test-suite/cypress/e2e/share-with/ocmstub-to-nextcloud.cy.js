/**
 * @fileoverview
 * Cypress test suite for testing native federated sharing functionality in OcmStub and Nextcloud.
 * This suite verifies the ability to send and receive federated file shares between OcmStub and Nextcloud.
 *
 * @author Michiel B. de Jong <michiel@pondersource.com>
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  getUtils
} from '../utils/index.js';

describe('Federated sharing functionality from OcmStub to Nextcloud', () => {
  // Shared variables to avoid repetition and improve maintainability
  const senderVersion = Cypress.env('EFSS_PLATFORM_1_VERSION') ?? 'v1';
  const recipientVersion = Cypress.env('EFSS_PLATFORM_2_VERSION') ?? 'v27';
  const senderUrl = Cypress.env('OCMSTUB1_URL') || 'https://ocmstub1.docker';
  const recipientUrl = Cypress.env('NEXTCLOUD1_URL') || 'https://nextcloud1.docker';
  const recipientUsername = Cypress.env('NEXTCLOUD1_USERNAME') || 'einstein';
  const recipientPassword = Cypress.env('NEXTCLOUD1_PASSWORD') || 'relativity';
  const sharedFileName = 'from-stub.txt';

  // Get the right helper set for each side
  const senderUtils = getUtils('ocmstub', senderVersion);
  const recipientUtils = getUtils('nextcloud', recipientVersion);

  /**
   * Test Case: Sending a federated share from OcmStub to Nextcloud.
   * Validates that a file can be successfully shared from OcmStub to Nextcloud.
   */
  it('Send a federated share of a file from OcmStub to Nextcloud', () => {
    senderUtils.shareViaNativeShareWith({
      senderUrl,
      recipientUsername,
      recipientUrl,
    });
  });

  /**
   * Test Case: Receiving and accepting a federated share on the recipient's Nextcloud instance.
   * Validates that the recipient can successfully accept the share and view the shared file.
   */
  it('Receive federated share of a file from OcmStub to Nextcloud', () => {
    // Step 1: Log in to the recipient's Nextcloud instance
    recipientUtils.login(recipientUrl, recipientUsername, recipientPassword);

    // Step 2: Handle any share acceptance pop-ups and verify the file exists
    recipientUtils.handleShareAcceptance(sharedFileName);
  });
});
