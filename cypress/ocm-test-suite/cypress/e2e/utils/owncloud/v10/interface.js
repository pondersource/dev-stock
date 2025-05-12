/**
 * @fileoverview
 * Utility functions for Cypress tests interacting with ownCloud version 10.
 * These functions provide abstractions for common actions such as accepting shares,
 * creating federated shares, renaming files, and interacting with the file menu.
 *
 * @author Michiel B. de Jong <michiel@pondersource.com>
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  constructFederatedShareUrl,
} from '../../general.js';

import * as implementation from './implementation.js';

export const platform = 'owncloud';
export const version = 'v10';

/**
 * Login to ownCloud and navigate to the files app.
 * Extends the core login functionality by verifying the files app is accessible.
 *
 * @param {string} url - The URL of the ownCloud instance.
 * @param {string} username - The username for login.
 * @param {string} password - The password for login.
 */
export function login({ url, username, password }) {
  implementation.loginCore({ url, username, password });

  // Verify files app visibility
  cy.url({ timeout: 10000 }).should('match', /apps\/files(\/|$)/);
};

export function shareViaNativeShareWith({
  senderUrl,
  senderUsername,
  senderPassword,
  originalFileName,
  sharedFileName,
  recipientUsername,
  recipientUrl,
}) {
  // Step 1: Log in to the sender's ownCloud instance
  login({ url: senderUrl, username: senderUsername, password: senderPassword });

  // Step 2: Ensure the original file exists
  implementation.ensureFileExists(originalFileName);

  // Step 3: Rename the file
  implementation.renameFile(originalFileName, sharedFileName);

  // Step 4: Verify the file has been renamed
  implementation.ensureFileExists(sharedFileName);

  // Step 5: Create a federated share for the recipient
  implementation.createShare(sharedFileName, recipientUsername, recipientUrl.replace(/^https?:\/\/|\/$/g, ''));
}

export function acceptNativeShareWithShare({
  recipientUrl,
  recipientUsername,
  recipientPassword,
  sharedFileName,
}) {
  // Step 1: Log in to the recipient's instance
  login({ url: recipientUrl, username: recipientUsername, password: recipientPassword });

  // Step 2: Handle any share acceptance pop-ups and verify the file exists
  implementation.handleShareAcceptance(sharedFileName);
}

export function shareViaFederatedLink({
  senderUrl,
  senderUsername,
  senderPassword,
  originalFileName,
  sharedFileName,
}) {
  // Step 1: Log in to the sender's ownCloud instance
  login({ url: senderUrl, username: senderUsername, password: senderPassword });

  // Step 2: Ensure the original file exists before renaming
  implementation.ensureFileExists(originalFileName);

  // Step 3: Rename the file to prepare it for sharing
  implementation.renameFile(originalFileName, sharedFileName);

  // Step 4: Verify the file has been renamed
  implementation.ensureFileExists(sharedFileName);

  // Step 5: Create a share link for the file
  implementation.createShareLink(sharedFileName);
}

export function acceptFederatedLinkShare({
  senderPlatform,
  senderUrl,
  senderUsername,
  recipientPlatform,
  recipientUrl,
  recipientUsername,
  recipientPassword,
  sharedFileName,
}) {
  // Step 1: Log in to the recipient's instance
  login({ url: recipientUrl, username: recipientUsername, password: recipientPassword });

  if (senderPlatform == 'owncloud') {
    // Step 2: Read the share URL from file
    cy.readFile('share-link-url.txt').then((shareUrl) => {
      // Step 3: Construct the federated share URL
      const federatedShareUrl = constructFederatedShareUrl({
        shareUrl,
        senderUrl,
        recipientUrl,
        senderUsername,
        fileName: sharedFileName,
        platform: recipientPlatform
      });

      cy.visit(federatedShareUrl);
    });
  };

  implementation.handleShareAcceptance(sharedFileName);
}

/**
 * Build the federated share details object.
 *
 * @param {string} recipientUsername - Username of the recipient (e.g. "alice")
 * @param {string} recipientUrl - Hostname or URL of the recipient (e.g. "remote.example.com")
 * @param {string} sharedFileName - The name of the file being shared
 * @param {string} senderUsername - Username of the sender (e.g. "bob")
 * @param {string} senderUrl - Full URL of the sender (e.g. "https://my.example.com/")
 * @returns {Object} The federated share details
 */
export function buildFederatedShareDetails({
  recipientUsername,
  recipientUrl,
  sharedFileName,
  senderUsername,
  senderUrl
}) {
  return {
    shareWith: `${recipientUsername}@${recipientUrl.replace(/^https?:\/\/|\/$/g, '')}`,
    fileName: sharedFileName,
    owner: `${senderUsername}@${senderUrl}`,
    sender: `${senderUsername}@${senderUrl}`,
    shareType: 'user',
    resourceType: 'file',
    protocol: 'webdav'
  };
}
