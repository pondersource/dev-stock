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
  const senderVersion = Cypress.env('EFSS_PLATFORM_1_VERSION') ?? 'v11';
  const recipientVersion = Cypress.env('EFSS_PLATFORM_2_VERSION') ?? 'v11';
  const senderUrl = Cypress.env('SEAFILE1_URL') || 'http://seafile1.docker';
  const recipientUrl = Cypress.env('SEAFILE2_URL') || 'http://seafile2.docker';
  const senderUsername = Cypress.env('SEAFILE1_USERNAME') || 'jonathan@seafile.com';
  const senderPassword = Cypress.env('SEAFILE1_PASSWORD') || 'xu';
  const recipientUsername = Cypress.env('SEAFILE2_USERNAME') || 'giuseppe@cern.ch';
  const recipientPassword = Cypress.env('SEAFILE2_PASSWORD') || 'lopresti';

  // Get the right helper set for each side
  const senderUtils = getUtils('seafile', senderVersion);
  const recipientUtils = getUtils('seafile', recipientVersion);

  /**
   * Test Case: Sending a federated share from Seafile 1 to Seafile 2.
   */
  it('should successfully send a federated share of a file from Seafile 1 to Seafile 2', () => {
    // Step 1: Log in to Seafile 1
    cy.loginSeafile(senderUrl, senderUsername, senderPassword);

    // Step 2: Dismiss any modals if present
    senderUtils.dismissModalIfPresentV11();

    // Step 3: Open share dialog for the first file
    senderUtils.openShareDialog();

    // Step 4: Open federated sharing tab
    senderUtils.openFederatedSharingTab();

    // Step 5: Select the remote Seafile server
    senderUtils.selectRemoteServer('seafile2');

    // Step 6: Share with remote user
    senderUtils.shareWithRemoteUser(recipientUsername);
  });

  /**
   * Test Case: Receiving a federated share on Seafile 2.
   */
  it('should successfully receive and display a federated share of a file on Seafile 2', () => {
    // Step 1: Log in to Seafile 2
    cy.loginSeafile(recipientUrl, recipientUsername, recipientPassword);

    // Step 2: Dismiss any modals if present
    recipientUtils.dismissModalIfPresentV11();

    // Step 3: Navigate to received shares section
    recipientUtils.navigateToReceivedShares();

    // Step 4: Verify the received share is visible
    recipientUtils.verifyReceivedShare(senderUsername, senderUrl);
  });
});
