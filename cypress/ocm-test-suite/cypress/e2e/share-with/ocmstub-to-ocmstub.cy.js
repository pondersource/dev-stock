/**
 * @fileoverview
 * Cypress test suite for testing native federated sharing functionality in OcmStub.
 *
 * @author Michiel B. de Jong <michiel@pondersource.com>
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  getUtils
} from '../utils/index.js';

describe('Native federated sharing functionality for OcmStub', () => {
  // Shared variables to avoid repetition and improve maintainability
  const senderVersion = Cypress.env('EFSS_PLATFORM_1_VERSION') ?? 'v1';
  const recipientVersion = Cypress.env('EFSS_PLATFORM_2_VERSION') ?? 'v1';
  const senderUrl = Cypress.env('OCMSTUB1_URL') || 'https://ocmstub1.docker';
  const recipientUrl = Cypress.env('OCMSTUB2_URL') || 'https://ocmstub2.docker';
  const senderUsername = Cypress.env('OCMSTUB1_USERNAME') || 'einstein';
  const recipientUsername = Cypress.env('OCMSTUB2_USERNAME') || 'mahdi';
  const sharedFileName = 'from-stub.txt';

  // Get the right helper set for each side
  const senderUtils = getUtils('ocmstub', senderVersion);
  const recipientUtils = getUtils('owncloud', recipientVersion);

  /**
   * Test Case: Sending a federated share from OcmStub 1.0 to OcmStub 1.0.
   */
  it('should successfully send a federated share of a file from OcmStub 1.0 to OcmStub 1.0', () => {
    senderUtils.shareViaNativeShareWith({
      senderUrl,
      recipientUsername,
      recipientUrl,
    });
  });

  /**
   * Test Case: Receiving a federated share on OcmStub from ocmStub.
   * 
   */
  it('Receive federated share of a file from from OcmStub v1 to OcmStub v1', () => {
    // Step 1: Log in to the recipient's OcmStub instance
    cy.loginOcmStub(recipientUrl);

    // Expected details of the federated share
    const expectedShareDetails = senderUtils.buildFederatedShareDetails({
      recipientUsername,
      recipientUrl,
      sharedFileName,
      senderUsername,
      senderUrl,
    });

    // Step 2: Generate assertions for share metadata verification
    const shareAssertions = recipientUtils.generateShareAssertions(expectedShareDetails, true);

    // Step 3: Verify all share metadata is correctly displayed
    shareAssertions.forEach((assertion) => {
      cy.contains(assertion, { timeout: 10000 })
        .should('be.visible');
    });
  });
})
