/**
 * @fileoverview
 * Cypress test suite for testing invite link federated sharing via ScienceMesh functionality
 * between ownCloud v10 and Nextcloud v27. This suite covers sending and accepting invitation links,
 * sharing files via ScienceMesh, and verifying that the shares are received correctly.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  createInviteLink,
  createScienceMeshShare,
  renameFile,
  ensureFileExists,
} from '../utils/owncloud';

import {
  acceptShareV27,
  verifyFederatedContactV27,
  acceptScienceMeshInvitation,
  ensureFileExistsV27,
  navigationSwitchLeftSideV27,
  selectAppFromLeftSideV27,
} from '../utils/nextcloud-v27';

describe('Invite link federated sharing via ScienceMesh functionality between ownCloud and Nextcloud', () => {
  // Shared variables to avoid repetition and improve maintainability
  const senderUrl = Cypress.env('OWNCLOUD1_URL') || 'https://owncloud1.docker';
  const recipientUrl = Cypress.env('NEXTCLOUD1_URL') || 'https://nextcloud1.docker';
  const senderUsername = Cypress.env('OWNCLOUD1_USERNAME') || 'marie';
  const senderPassword = Cypress.env('OWNCLOUD1_PASSWORD') || 'radioactivity';
  const recipientUsername = Cypress.env('NEXTCLOUD1_USERNAME') || 'einstein';
  const recipientPassword = Cypress.env('NEXTCLOUD1_PASSWORD') || 'relativity';

  // Extract domain without protocol or trailing slash
  const senderDomain = senderUrl.replace(/^https?:\/\/|\/$/g, '');
  const recipientDomain = recipientUrl.replace(/^https?:\/\/|\/$/g, '');
  
  // File-related constants
  const inviteLinkFileName = 'invite-link-oc-nc.txt';
  const originalFileName = 'welcome.txt';
  const sharedFileName = inviteLinkFileName;

  /**
   * Test case: Sending an invitation link from ownCloud to Nextcloud.
   * Steps:
   * 1. Log in to the sender's ownCloud instance
   * 2. Navigate to the ScienceMesh app
   * 3. Generate the invite link and save it to a file
   */
  it('Send invitation from ownCloud v10 to Nextcloud v27', () => {
    // Step 1: Log in to the sender's ownCloud instance
    cy.loginOwncloud(senderUrl, senderUsername, senderPassword);

    // Step 2: Navigate to the ScienceMesh app
    cy.visit(`${senderUrl}/index.php/apps/sciencemesh/`);

    // Step 3: Generate an invite link and save it to a file
    createInviteLink(recipientUrl).then((inviteLink) => {
      // Step 4: Ensure the invite link is not empty
      expect(inviteLink).to.be.a('string').and.not.be.empty;
      // Step 5: Save the invite link to a file for later use
      cy.writeFile(inviteLinkFileName, inviteLink);
    });
  });

  /**
   * Test case: Accepting the invitation link on Nextcloud side.
   * Steps:
   * 1. Load the invite link from the saved file
   * 2. Log in to the recipient's Nextcloud instance
   * 3. Accept the invitation
   * 4. Verify the federated contact is established
   */
  it('Accept invitation from ownCloud v10 to Nextcloud v27', () => {
    const expectedContactDisplayName = senderUsername;
    // Extract domain without protocol or trailing slash
    // Note: The 'reva' prefix is added to the expected contact domain as per application behavior
    const expectedContactDomain = `reva${senderDomain}`;

    // Step 1: Load the invite link from the saved file
    cy.readFile(inviteLinkFileName).then((inviteLink) => {
      // Step 2: Ensure the invite link is valid
      expect(inviteLink).to.be.a('string').and.not.be.empty;

      // Step 3: Login to the recipient's Nextcloud instance using the invite link
      cy.loginNextcloudCore(inviteLink, recipientUsername, recipientPassword);

      // Step 4: Accept the invitation
      acceptScienceMeshInvitation();

      // Step 5: Verify that the sender is now a contact in the recipient's contacts list
      verifyFederatedContactV27(
        recipientDomain,
        expectedContactDisplayName,
        expectedContactDomain
      );
    });
  });

  /**
   * Test case: Sharing a file via ScienceMesh from ownCloud to Nextcloud.
   * Steps:
   * 1. Log in to the sender's ownCloud instance
   * 2. Ensure the original file exists
   * 3. Rename the file for sharing
   * 4. Create the share for the recipient
   */
  it('Send ScienceMesh share <file> from ownCloud v10 to Nextcloud v27', () => {
    // Step 1: Log in to the sender's ownCloud instance
    cy.loginOwncloud(senderUrl, senderUsername, senderPassword);

    // Step 2: Ensure the original file exists
    ensureFileExists(originalFileName);

    // Step 3: Rename the file
    renameFile(originalFileName, sharedFileName);

    // Step 4: Verify the file has been renamed
    ensureFileExists(sharedFileName);

    // Step 5: Create a federated share for the recipient via ScienceMesh
    // Note: The 'reva' prefix is added to the recipient domain as per application behavior
    createScienceMeshShare(
      sharedFileName,
      recipientUsername,
      `reva${recipientDomain}`,
    );
  });

  /**
   * Test case: Receiving and verifying the ScienceMesh share on Nextcloud side.
   * Steps:
   * 1. Log in to the recipient's Nextcloud instance
   * 2. Accept the shared file
   * 3. Navigate to the correct section
   * 4. Verify the shared file exists
   */
  it('Receive ScienceMesh share <file> from ownCloud v10 to Nextcloud v27', () => {
    // Step 1: Log in to the recipient's Nextcloud instance
    cy.loginNextcloud(recipientUrl, recipientUsername, recipientPassword);

    // Step 2: Wait for the share dialog to appear and accept the incoming federated share
    acceptShareV27();

    // Step 3: Navigate to the correct section
    navigationSwitchLeftSideV27('Open navigation');
    selectAppFromLeftSideV27('files');
    navigationSwitchLeftSideV27('Close navigation');

    // Step 4: Verify the shared file is visible
    ensureFileExistsV27(sharedFileName);

    // TODO @MahdiBaghbani: Download or open the file to verify content (if required)
  });
});
