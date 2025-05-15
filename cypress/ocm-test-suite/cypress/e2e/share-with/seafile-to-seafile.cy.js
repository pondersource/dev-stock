/**
 * @fileoverview
 * Cypress test suite for testing native federated sharing functionality in Seafile.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  getUtils
} from '../utils/index.js';

describe('Native federated sharing functionality for Seafile', () => {
  // Shared variables to avoid repetition and improve maintainability
  const senderPlatform = Cypress.env('EFSS_PLATFORM_1') ?? 'seafile';
  const recipientPlatform = Cypress.env('EFSS_PLATFORM_2') ?? 'seafile';
  const senderVersion = Cypress.env('EFSS_PLATFORM_1_VERSION') ?? 'v11';
  const recipientVersion = Cypress.env('EFSS_PLATFORM_2_VERSION') ?? 'v11';
  const senderUrl = Cypress.env('SEAFILE1_URL') || 'http://seafile1.docker';
  const recipientUrl = Cypress.env('SEAFILE2_URL') || 'http://seafile2.docker';
  const senderUsername = Cypress.env('SEAFILE1_USERNAME') || 'jonathan@seafile.com';
  const senderPassword = Cypress.env('SEAFILE1_PASSWORD') || 'xu';
  const recipientUsername = Cypress.env('SEAFILE2_USERNAME') || 'giuseppe@cern.ch';
  const recipientPassword = Cypress.env('SEAFILE2_PASSWORD') || 'lopresti';

  // Get the right helper set for each side
  const senderUtils = getUtils(senderPlatform, senderVersion);
  const recipientUtils = getUtils(recipientPlatform, recipientVersion);

  /**
   * Test Case: Sending a federated share from Seafile 1 to Seafile 2.
   */
  it('should successfully send a federated share of a file from Seafile 1 to Seafile 2', () => {
    senderUtils.shareViaNativeShareWith({
      senderUrl,
      senderUsername,
      senderPassword,
      recipientUsername,
      recipientUrl,
    });
  });

  /**
   * Test Case: Receiving a federated share on Seafile 2.
   */
  it('should successfully receive and display a federated share of a file on Seafile 2', () => {
    recipientUtils.acceptNativeShareWithShare({
      senderUrl,
      senderUsername,
      recipientUrl,
      recipientUsername,
      recipientPassword,
    });
  });
});
