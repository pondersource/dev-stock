/**
 * @fileoverview
 * Utility functions for Cypress tests interacting with Nextcloud version 27.
 * These functions provide abstractions for common actions such as sharing files,
 * updating permissions, renaming files, and navigating the UI.
 *
 * @author Michiel B. de Jong <michiel@pondersource.com>
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import * as implementation from './implementation.js';

export const platform = 'nextcloud';
export const version = 'v27';

/**
 * Login to Nextcloud and navigate to the files app.
 * Extends the core login functionality by verifying the dashboard and navigating to the files app.
 *
 * @param {string} url - The URL of the Nextcloud instance.
 * @param {string} username - The username for login.
 * @param {string} password - The password for login.
 */
export function login({ url, username, password }) {
  implementation.loginCore({ url, username, password });

  // Verify dashboard visibility
  cy.url({ timeout: 10000 }).should('match', /apps\/dashboard(\/|$)/);

  // Navigate to the files app
  cy.get('header[id="header"] nav.app-menu ul.app-menu-main li[data-app-id="files"]')
    .should('be.visible')
    .click();

  // Verify files app visibility
  cy.url({ timeout: 10000 }).should('match', /apps\/files(\/|$)/);
};

export function createInviteLink({
  senderUrl,
  senderUsername,
  senderPassword,
  recipientPlatform,
  recipientUrl,
  inviteLinkFileName,
}) {
  // Step 1: Log in to the sender's instance
  login({ url: senderUrl, username: senderUsername, password: senderPassword });

  // Step 2: Navigate to the ScienceMesh app
  cy.visit(`${senderUrl}/index.php/apps/sciencemesh/contacts`);

  if (recipientPlatform == 'nextcloud' || recipientPlatform == 'owncloud') {
    // Step 3: Generate the invite link and save it to a file
    implementation.createInviteLink(recipientUrl).then((inviteLink) => {
      // Step 4: Ensure the invite link is not empty
      expect(inviteLink).to.be.a('string').and.not.be.empty;
      // Step 5: Save the invite link to a file for later use
      cy.writeFile(inviteLinkFileName, inviteLink);
    });
  } else {
    // Step 3: Generate the invite token and save it to a file
    implementation.createInviteToken(recipientUrl).then((inviteToken) => {
      // Step 4: Ensure the invite link is not empty
      expect(inviteToken).to.be.a('string').and.not.be.empty;
      // Step 5: Save the invite link to a file for later use
      cy.writeFile(inviteLinkFileName, inviteToken);
    });
  }
}

export function acceptInviteLink({
  senderPlatform,
  senderDomain,
  senderUsername,
  senderDisplayName,
  recipientUrl,
  recipientDomain,
  recipientUsername,
  recipientPassword,
  inviteLinkFileName,
}) {
  // Step 1: Log in to the recipient's instance
  login({ url: recipientUrl, username: recipientUsername, password: recipientPassword });

  const flag = (senderPlatform == 'nextcloud' || senderPlatform == 'owncloud');

  // Step 1: Load the invite link from the saved file
  cy.readFile(inviteLinkFileName).then((inviteLink) => {
    // Step 2: Ensure the invite link is valid
    expect(inviteLink).to.be.a('string').and.not.be.empty;

    // Step 3: visit invite link.
    cy.visit(inviteLink)

    // Step 4: Accept the invitation
    implementation.acceptScienceMeshInvitation();

    // Step 5: Verify that the sender is now a contact in the recipient's contacts list
    implementation.verifyFederatedContact(
      recipientDomain,
      flag ? senderUsername : senderDisplayName,
      flag ? `reva${senderDomain}` : senderDomain,
    );
  });
}

export function shareViaInviteLink({
  senderUrl,
  senderDomain,
  senderUsername,
  senderPassword,
  recipientPlatform,
  recipientUrl,
  recipientDomain,
  recipientDisplayName,
  originalFileName,
  sharedFileName,
}) {
  // Step 1: Log in to the sender's Nextcloud instance
  login({ url: senderUrl, username: senderUsername, password: senderPassword });

  // Step 2: Ensure the original file exists before renaming
  implementation.ensureFileExists(originalFileName);

  // Step 3: Rename the file to prepare it for sharing
  implementation.renameFile(originalFileName, sharedFileName);

  // Step 4: Verify the file has been renamed
  implementation.ensureFileExists(sharedFileName);

  if (recipientPlatform == 'nextcloud' || recipientPlatform == 'owncloud') {
    // Step 5: Create a federated share for the recipient via ScienceMesh
    // Note: The 'reva' prefix is added to the recipient domain as per application behavior
    implementation.createScienceMeshShare(
      senderDomain,
      recipientDisplayName,
      `reva${recipientDomain}`,
      sharedFileName
    );
  } else {
    implementation.createScienceMeshShare(
      senderDomain,
      recipientDisplayName,
      recipientUrl,
      sharedFileName
    );
  }
}

export function acceptInviteLinkShare({
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

export function shareViaNativeShareWith({
  senderUrl,
  senderUsername,
  senderPassword,
  originalFileName,
  sharedFileName,
  recipientUsername,
  recipientUrl,
}) {
  // Step 1: Log in to the sender's Nextcloud instance
  login({ url: senderUrl, username: senderUsername, password: senderPassword });

  // Step 2: Ensure the original file exists before renaming
  implementation.ensureFileExists(originalFileName);

  // Step 3: Rename the file to prepare it for sharing
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
  recipientUsername,
  recipientUrl,
}) {
  // Step 1: Log in to the sender's Nextcloud instance
  login({ url: senderUrl, username: senderUsername, password: senderPassword });

  // Step 2: Ensure the original file exists before renaming
  implementation.ensureFileExists(originalFileName);

  // Step 3: Rename the file to prepare it for sharing
  implementation.renameFile(originalFileName, sharedFileName);

  // Step 4: Verify the file has been renamed
  implementation.ensureFileExists(sharedFileName);

  // Step 5: Create and send the share link to the recipient
  implementation.createAndSendShareLink(
    sharedFileName,
    recipientUsername,
    recipientUrl.replace(/^https?:\/\/|\/$/g, '')
  );
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
    shareWith: `${recipientUsername}@${recipientUrl}`,
    fileName: sharedFileName,
    owner: `${senderUsername}@${senderUrl}/`,
    sender: `${senderUsername}@${senderUrl}/`,
    shareType: 'user',
    resourceType: 'file',
    protocol: 'webdav'
  };
}
