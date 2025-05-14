/**
 * @fileoverview
 * Utility functions for Cypress tests interacting with Seafile version 11.
 * These functions provide abstractions for common actions such as accepting shares,
 * creating federated shares, renaming files, and interacting with the file menu.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import * as implementation from './implementation.js';

export const platform = 'seafile';
export const version = 'v11';

/**
 * Login to Seafile and navigate to the files app.
 * Extends the core login functionality by verifying the files app is accessible.
 *
 * @param {string} url - The URL of the Seafile instance.
 * @param {string} username - The username for login.
 * @param {string} password - The password for login.
 */
export function login({ url, username, password }) {
  cy.visit(url);

  // Fill in login credentials and submit
  cy.get('input[name="login"]').type(username);
  cy.get('input[name="password"]').type(password);
  cy.get('button[type="submit"]').click();
};

export function shareViaNativeShareWith({
  senderUrl,
  senderUsername,
  senderPassword,
  recipientUsername,
}) {
  // Step 1: Log in to the sender's Seafile instance
  login({ url: senderUrl, username: senderUsername, password: senderPassword });

  // Step 2: Dismiss any modals if present
  implementation.dismissModalIfPresent();

  // Step 3: Open share dialog for the first file
  implementation.openShareDialog();

  // Step 4: Open federated sharing tab
  implementation.openFederatedSharingTab();

  // Step 5: Select the remote Seafile server
  implementation.selectRemoteServer('recipient');

  // Step 6: Share with remote user
  implementation.shareWithRemoteUser(recipientUsername);
}

export function acceptNativeShareWithShare({
  senderUrl,
  senderUsername,
  recipientUrl,
  recipientUsername,
  recipientPassword,
}) {
  // Step 1: Log in to the recipient's instance
  login({ url: recipientUrl, username: recipientUsername, password: recipientPassword });

  // Step 2: Dismiss any modals if present
  implementation.dismissModalIfPresent();

  // Step 3: Navigate to received shares section
  implementation.navigateToReceivedShares();

  // Step 4: Verify the received share is visible
  implementation.verifyReceivedShare(senderUsername, senderUrl);
}
