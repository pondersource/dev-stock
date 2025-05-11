/**
 * @fileoverview
 * Utility functions for Cypress tests interacting with OcmStub version 1.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import * as implementation from './implementation.js';

export const platform = 'ocmstub';
export const version = 'v1';

export function login({ url }) {
  cy.visit(`${url}/?`);

  // Ensure the login button is visible
  cy.get('input[value="Log in"]', { timeout: 10000 }).should('be.visible');

  // Perform login by clicking the button
  cy.get('input[value="Log in"]').click();

  // Verify session activation
  cy.url({ timeout: 10000 }).should('match', /\/?session=active/);
};

export function shareViaNativeShareWith({
  senderUrl,
  recipientUsername,
  recipientUrl,
}) {
  // Step 1: Navigate to the federated share link on OcmStub 1.0
  // Remove trailing slash and leading https or http from recipientUrl
  cy.visit(`${senderUrl}/shareWith?${recipientUsername}@${recipientUrl.replace(/^https?:\/\/|\/$/g, '')}`);

  // Step 2: Verify the confirmation message is displayed
  cy.contains('yes shareWith', { timeout: 10000 })
    .should('be.visible')
}

export function acceptNativeShareWithShare({
  senderPlatform,
  recipientUrl,
  recipientUsername,
  sharedFileName,
  senderUsername,
  senderUrl,
  senderUtils,
}) {
  login({ url: recipientUrl });
  implementation.acceptShare({
    senderPlatform,
    recipientUrl,
    recipientUsername,
    sharedFileName,
    senderUsername,
    senderUrl,
    senderUtils,
  });
}

export function acceptFederatedLinkShare({
  senderPlatform,
  recipientUrl,
  recipientUsername,
  sharedFileName,
  senderUsername,
  senderUrl,
  senderUtils,
}) {
  login({ url: recipientUrl });
  implementation.acceptShare({
    senderPlatform,
    recipientUrl,
    recipientUsername,
    sharedFileName,
    senderUsername,
    senderUrl,
    senderUtils,
  });
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
    owner: `${senderUsername}@${senderUrl.replace(/^https?:\/\/|\/$/g, '')}`,
    sender: `${senderUsername}@${senderUrl.replace(/^https?:\/\/|\/$/g, '')}`,
    shareType: 'user',
    resourceType: 'file',
    protocol: 'webdav'
  };
}
