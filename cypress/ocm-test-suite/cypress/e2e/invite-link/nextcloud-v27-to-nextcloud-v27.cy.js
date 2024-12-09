/**
 * @fileoverview
 * Cypress test suite for testing invite link federated sharing via ScienceMesh functionality in Nextcloud v27.
 * This suite covers sending and accepting invitation links, sharing files via ScienceMesh,
 * and verifying that the shares are received correctly.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  acceptShareV27,
  createInviteLinkV27,
  verifyFederatedContactV27,
  acceptScienceMeshInvitation,
  createScienceMeshShareV27,
  renameFileV27,
  ensureFileExistsV27,
  navigationSwitchLeftSideV27,
  selectAppFromLeftSideV27,
} from '../utils/nextcloud-v27';

describe('Invite link federated sharing via ScienceMesh functionality for Nextcloud', () => {

  // Shared variables to avoid repetition and improve maintainability
  const senderUrl = Cypress.env('NEXTCLOUD1_URL') || 'https://nextcloud1.docker';
  const recipientUrl = Cypress.env('NEXTCLOUD2_URL') || 'https://nextcloud2.docker';
  const senderUsername = Cypress.env('NEXTCLOUD1_USERNAME') || 'einstein';
  const senderPassword = Cypress.env('NEXTCLOUD1_PASSWORD') || 'relativity';
  const recipientUsername = Cypress.env('NEXTCLOUD2_USERNAME') || 'michiel';
  const recipientPassword = Cypress.env('NEXTCLOUD2_PASSWORD') || 'dejong';
  const inviteLinkFileName = 'invite-link-nc-nc.txt';
  const originalFileName = 'welcome.txt';
  const sharedFileName = 'invite-link-nc-nc.txt';

  /**
   * Test case: Sending an invitation link from sender to recipient.
   */
  it('Send invitation from Nextcloud v27 to Nextcloud v27', () => {
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
   * Test case: Accepting the invitation link on the recipient's side.
   */
  it('Accept invitation from Nextcloud v27 to Nextcloud v27', () => {
    const expectedContactDisplayName = senderUsername;
    // Extract domain without protocol or trailing slash
    // Note: The 'reva' prefix is added to the expected contact domain as per application behavior
    const expectedContactDomain = `reva${senderUrl.replace(/^https?:\/\/|\/$/g, '')}`;

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
        recipientUrl.replace(/^https?:\/\/|\/$/g, ''),
        expectedContactDisplayName,
        expectedContactDomain
      );
    });
  });

  /**
   * Test case: Sharing a file via ScienceMesh from sender to recipient.
   */
  it('Send ScienceMesh share of a file from Nextcloud v27 to Nextcloud v27', () => {
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
      senderUrl.replace(/^https?:\/\/|\/$/g, ''),
      recipientUsername,
      `reva${recipientUrl.replace(/^https?:\/\/|\/$/g, '')}`,
      sharedFileName
    );

    // TODO @MahdiBaghbani: Verify that the share was created successfully
  });

  /**
   * Test case: Receiving and verifying the ScienceMesh share on the recipient's side.
   */
  it('Receive ScienceMesh share of a file from Nextcloud v27 to Nextcloud v27', () => {
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
