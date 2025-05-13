import * as implementation from './implementation.js';

export const platform = 'ocis';
export const version = 'v5';

/**
 * Login to oCIS and navigate to the files app.
 * Extends the core login functionality by verifying the dashboard and navigating to the files app.
 *
 * @param {string} url - The URL of the oCIS instance.
 * @param {string} username - The username for login.
 * @param {string} password - The password for login.
 */
export function login({ url, username, password }) {
  implementation.loginCore({ url, username, password });

  // Verify personal files app visibility
  cy.url({ timeout: 10000 }).should('match', /files\/spaces\/personal(\/|$)/);
};

export function createInviteLink({
  senderUrl,
  senderUsername,
  senderPassword,
  inviteLinkFileName,
}) {
  // Step 1: Log in to the sender's instance
  login({ url: senderUrl, username: senderUsername, password: senderPassword });

  // Step 2: Navigate to the ScienceMesh app
  implementation.openScienceMeshApp();

  // Step 3: Generate the invite token and save it to a file
  implementation.createInviteToken().then((token) => {
    // Ensure the token is not empty
    expect(token).to.be.a('string').and.not.be.empty;
    // Save the token to a file for later use
    cy.writeFile(inviteLinkFileName, token);
  });

  // Wait for the operation to complete
  cy.wait(5000);
}

export function acceptInviteLink({
  senderDomain,
  senderDisplayName,
  recipientUrl,
  recipientUsername,
  recipientPassword,
  inviteLinkFileName,
}) {
  // Step 1: Log in to the recipient's instance
  login({ url: recipientUrl, username: recipientUsername, password: recipientPassword });

  // Step 2: Load the invite token from the saved file
  cy.readFile(inviteLinkFileName).then((token) => {
    // Verify token exists and is not empty
    expect(token).to.exist;
    expect(token.trim()).to.not.be.empty;
    cy.log('Read token from file:', token);

    // Step 3: Accept the invitation
    implementation.acceptInviteLink(token);

    // Step 4: Verify the federated contact is established
    implementation.verifyFederatedContact(senderDisplayName, senderDomain);
  });

  // Wait for the operation to complete
  cy.wait(5000);
}

export function shareViaInviteLink({
  senderUrl,
  senderUsername,
  senderPassword,
  sharedFileName,
  sharedFileContent,
  recipientUsername,
}) {
  // Step 1: Log in to the sender's instance
  login({ url: senderUrl, username: senderUsername, password: senderPassword });

  // Step 2: Create a text file with content
  implementation.createTextFile(sharedFileName, sharedFileContent);

  // Step 3: Navigate to the Files app
  implementation.openFilesApp();

  // Step 4: Share the file with the recipient
  implementation.createShare(sharedFileName, recipientUsername);

  // Wait for the operation to complete
  cy.wait(5000);
}

export function acceptInviteLinkShare({
  senderDisplayName,
  recipientUrl,
  recipientUsername,
  recipientPassword,
  recipientDisplayName,
  sharedFileName,
}) {
  // Step 1: Log in to the recipient's instance
  login({ url: recipientUrl, username: recipientUsername, password: recipientPassword });

  // Step 2: Accept the shared file
  implementation.acceptShare(sharedFileName);

  // Step 3: Reload the page to refresh the view
  cy.reload(true);

  // Step 4: Verify the share details are correct
  implementation.verifyShare(
    sharedFileName,
    senderDisplayName,
    recipientDisplayName,
  );

  // Wait for the operation to complete
  cy.wait(5000);
}
