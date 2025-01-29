/**
 * @fileoverview
 * Cypress test suite for testing invite link federated sharing via ScienceMesh functionality
 * between Nextcloud v27 and ownCloud v10. This suite covers sending and accepting invitation links,
 * sharing files via ScienceMesh, and verifying that the shares are received correctly.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  createInviteLinkV27,
  createScienceMeshShareV27,
  renameFileV27,
  ensureFileExistsV27,
} from '../utils/nextcloud-v27';

import {
  acceptShare,
  verifyFederatedContact,
  acceptScienceMeshInvitation,
  ensureFileExists,
  selectAppFromLeftSide,
} from '../utils/owncloud-v10';

describe('Invite link federated sharing via ScienceMesh functionality between Nextcloud and ownCloud', () => {
  // Shared variables to avoid repetition and improve maintainability
  const senderUrl = Cypress.env('NEXTCLOUD1_URL') || 'https://nextcloud1.docker';
  const recipientUrl = Cypress.env('OWNCLOUD1_URL') || 'https://owncloud1.docker';
  const senderUsername = Cypress.env('NEXTCLOUD1_USERNAME') || 'einstein';
  const senderPassword = Cypress.env('NEXTCLOUD1_PASSWORD') || 'relativity';
  const recipientUsername = Cypress.env('OWNCLOUD1_USERNAME') || 'marie';
  const recipientPassword = Cypress.env('OWNCLOUD1_PASSWORD') || 'radioactivity';

  // Extract domain without protocol or trailing slash
  const senderDomain = senderUrl.replace(/^https?:\/\/|\/$/g, '');
  const recipientDomain = recipientUrl.replace(/^https?:\/\/|\/$/g, '');

  // File-related constants
  const inviteLinkFileName = 'invite-link-nc-oc.txt';
  const originalFileName = 'welcome.txt';
  const sharedFileName = inviteLinkFileName;

  /**
   * Test case: Sending an invitation link from Nextcloud to ownCloud.
   * Steps:
   * 1. Log in to the sender's Nextcloud instance
   * 2. Navigate to the ScienceMesh app
   * 3. Generate the invite link and save it to a file
   */
  it('Send invitation from Nextcloud v27 to ownCloud v10', () => {
    // Step 1: Log in to the sender's Nextcloud instance
    cy.loginNextcloud(senderUrl, senderUsername, senderPassword);

    // Step 2: Navigate to the ScienceMesh app
    cy.visit(`${senderUrl}/index.php/apps/sciencemesh/contacts`);

    // Step 3: Generate the invite link and save it to a file
    createInviteLinkV27(recipientUrl).then((inviteLink) => {
      // Step 4: Ensure the invite link is not empty
      expect(inviteLink).to.be.a('string').and.not.be.empty;
      // Step 5: Save the invite link to a file for later use
      cy.writeFile(inviteLinkFileName, inviteLink);
    });
  });

  /**
   * Test case: Accepting the invitation link on ownCloud side.
   * Steps:
   * 1. Load the invite link from the saved file
   * 2. Log in to the recipient's ownCloud instance
   * 3. Accept the invitation
   * 4. Verify the federated contact is established
   */
  it('Accept invitation from Nextcloud v27 to ownCloud v10', () => {
    const expectedContactDisplayName = senderUsername;
    // Extract domain without protocol or trailing slash
    // Note: The 'reva' prefix is added to the expected contact domain as per application behavior
    const expectedContactDomain = `reva${senderDomain}`;

    // Step 1: Read the invite link from the file
    cy.readFile(inviteLinkFileName).then((inviteLink) => {
      // Step 2: Ensure the invite link is valid
      expect(inviteLink).to.be.a('string').and.not.be.empty;

      // Step 3: Login to the recipient's ownCloud instance using the invite link
      cy.loginOwncloudCore(inviteLink, recipientUsername, recipientPassword);

      // Step 4: Accept the invitation
      acceptScienceMeshInvitation();

      // Step 5: Verify that the sender is now a contact in the recipient's contacts list
      verifyFederatedContact(
        recipientDomain,
        expectedContactDisplayName,
        expectedContactDomain
      );
    });
  });

  /**
   * Test case: Sharing a file via ScienceMesh from Nextcloud to ownCloud.
   * Steps:
   * 1. Log in to the sender's Nextcloud instance
   * 2. Ensure the original file exists
   * 3. Rename the file for sharing
   * 4. Create the share for the recipient
   */
  it('Send ScienceMesh share <file> from Nextcloud v27 to ownCloud v10', () => {
    // Step 1: Log in to the sender's Nextcloud instance
    cy.loginNextcloud(senderUrl, senderUsername, senderPassword);

    // Step 2: Ensure the original file exists before renaming
    ensureFileExistsV27(originalFileName);

    // Step 3: Rename the file to prepare it for sharing
    renameFileV27(originalFileName, sharedFileName);

    // Step 4: Verify the file has been renamed
    ensureFileExistsV27(sharedFileName);

    // Step 5: Create a federated share for the recipient via ScienceMesh
    // Note: The 'reva' prefix is added to the recipient domain as per application behavior
    createScienceMeshShareV27(
      senderDomain,
      recipientUsername,
      `reva${recipientDomain}`,
      sharedFileName
    );
  });

  /**
   * Test case: Receiving and verifying the ScienceMesh share on ownCloud side.
   * Steps:
   * 1. Log in to the recipient's ownCloud instance
   * 2. Verify the shared file exists and has correct sharing information
   */
  it('Receive ScienceMesh share <file> from Nextcloud v27 to ownCloud v10', () => {
    // Step 1: Log in to the recipient's ownCloud instance
    cy.loginOwncloud(recipientUrl, recipientUsername, recipientPassword);

    // Step 2: Wait for the share dialog to appear and accept the incoming federated share
    acceptShare();

    // Step 3: Navigate to the correct section
    selectAppFromLeftSide('files');

    // Step 4: Verify that the shared file is visible
    ensureFileExists(sharedFileName);
  });
});
