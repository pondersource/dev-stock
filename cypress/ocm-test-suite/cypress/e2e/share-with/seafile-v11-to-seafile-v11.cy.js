/**
 * @fileoverview
 * Cypress test suite for testing native federated sharing functionality in Seafile v11.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  dismissModalIfPresentV11,
  openShareDialog,
  openFederatedSharingTab,
  selectRemoteServer,
  shareWithRemoteUser,
  navigateToReceivedShares,
  verifyReceivedShare
} from '../utils/seafile-v11';

describe('Native federated sharing functionality for Seafile v11', () => {
  // Shared variables to avoid repetition and improve maintainability
  const senderUrl = Cypress.env('SEAFILE1_URL') || 'http://seafile1.docker';
  const recipientUrl = Cypress.env('SEAFILE2_URL') || 'http://seafile2.docker';
  const senderUsername = Cypress.env('SEAFILE1_USERNAME') || 'jonathan@seafile.com';
  const senderPassword = Cypress.env('SEAFILE1_PASSWORD') || 'xu';
  const recipientUsername = Cypress.env('SEAFILE2_USERNAME') || 'giuseppe@cern.ch';
  const recipientPassword = Cypress.env('SEAFILE2_PASSWORD') || 'lopresti';

  /**
   * Test Case: Sending a federated share from Seafile 1 to Seafile 2.
   */
  it('should successfully send a federated share of a file from Seafile 1 to Seafile 2', () => {
    // Step 1: Log in to Seafile 1
    cy.loginSeafile(senderUrl, senderUsername, senderPassword);

    // Step 2: Dismiss any modals if present
    dismissModalIfPresentV11();

    // Step 3: Open share dialog for the first file
    openShareDialog();

    // Step 4: Open federated sharing tab
    openFederatedSharingTab();

    // Step 5: Select the remote Seafile server
    selectRemoteServer('seafile2');

    // Step 6: Share with remote user
    shareWithRemoteUser(recipientUsername);
  });

  /**
   * Test Case: Receiving a federated share on Seafile 2.
   */
  it('should successfully receive and display a federated share of a file on Seafile 2', () => {
    // Step 1: Log in to Seafile 2
    cy.loginSeafile(recipientUrl, recipientUsername, recipientPassword);

    // Step 2: Dismiss any modals if present
    dismissModalIfPresentV11();

    // Step 3: Navigate to received shares section
    navigateToReceivedShares();

    // Step 4: Verify the received share is visible
    verifyReceivedShare(senderUsername, senderUrl);
  });
});
