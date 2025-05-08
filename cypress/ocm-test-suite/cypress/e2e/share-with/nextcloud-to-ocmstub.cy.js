/**
 * @fileoverview
 * Cypress test suite for testing native federated sharing functionality in Nextcloud and OcmStub.
 *
 * @author Michiel B. de Jong <michiel@pondersource.com>
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  getUtils
} from '../utils/index.js';

describe('Native Federated Sharing Functionality for Nextcloud to OcmStub', () => {
  // Shared variables to avoid repetition and improve maintainability
  const senderVersion = Cypress.env('EFSS_PLATFORM_1_VERSION') ?? 'v27';
  const recipientVersion = Cypress.env('EFSS_PLATFORM_2_VERSION') ?? 'v1';
  const senderUrl = Cypress.env('NEXTCLOUD1_URL') || 'https://nextcloud1.docker';
  const recipientUrl = Cypress.env('OCMSTUB1_URL') || 'https://ocmstub1.docker';
  const senderUsername = Cypress.env('NEXTCLOUD1_USERNAME') || 'einstein';
  const senderPassword = Cypress.env('NEXTCLOUD1_PASSWORD') || 'relativity';
  const recipientUsername = Cypress.env('OCMSTUB1_USERNAME') || 'michiel';
  const originalFileName = 'welcome.txt';
  const sharedFileName = 'nc1-to-os1-share.txt';

  // Get the right helper set for each side
  const senderUtils = getUtils('nextcloud', senderVersion);
  const recipientUtils = getUtils('ocmstub', recipientVersion);

  /**
   * Test Case: Sending a federated share from one Nextcloud instance to OcmStub.
   * Validates that a file can be successfully shared from Nextcloud to OcmStub.
   */
  it('Send a federated share of a file from Nextcloud to OcmStub', () => {
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
   * Test Case: Receiving a federated share on OcmStub from Nextcloud.
   */
  it('Receive federated share of a file from from Nextcloud to OcmStub', () => {
    // Step 1: Log in to the recipient's OcmStub instance
    cy.loginOcmStub(recipientUrl);

    // Expected details of the federated share
    const expectedShareDetails = senderUtils.buildFederatedShareDetails(
      recipientUsername,
      recipientUrl,
      sharedFileName,
      senderUsername,
      senderUrl
    );

    // Step 2: Generate assertions for share metadata verification
    const shareAssertions = recipientUtils.generateShareAssertions(expectedShareDetails, true);

    // Step 3: Verify all share metadata is correctly displayed
    shareAssertions.forEach((assertion) => {
      cy.contains(assertion, { timeout: 10000 })
        .should('be.visible');
    });
  });
});
