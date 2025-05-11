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
  const senderPlatform = Cypress.env('EFSS_PLATFORM_1') ?? 'ocmstub';
  const recipientPlatform = Cypress.env('EFSS_PLATFORM_2') ?? 'ocmstub';
  const senderVersion = Cypress.env('EFSS_PLATFORM_1_VERSION') ?? 'v1';
  const recipientVersion = Cypress.env('EFSS_PLATFORM_2_VERSION') ?? 'v1';
  const senderUrl = Cypress.env('OCMSTUB1_URL') || 'https://ocmstub1.docker';
  const recipientUrl = Cypress.env('OCMSTUB2_URL') || 'https://ocmstub2.docker';
  const senderUsername = Cypress.env('OCMSTUB1_USERNAME') || 'einstein';
  const recipientUsername = Cypress.env('OCMSTUB2_USERNAME') || 'mahdi';
  const sharedFileName = 'from-stub.txt';

  // Get the right helper set for each side
  const senderUtils = getUtils(senderPlatform, senderVersion);
  const recipientUtils = getUtils(recipientPlatform, recipientVersion);

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
    recipientUtils.acceptNativeShareWithShare({
      senderPlatform,
      recipientUrl,
      recipientUsername,
      sharedFileName,
      senderUsername,
      senderUrl,
      senderUtils,
    });
  });
})
