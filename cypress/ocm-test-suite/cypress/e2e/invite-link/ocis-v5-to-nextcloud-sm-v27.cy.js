/**
 * @fileoverview
 * Cypress test suite for testing invite link federated sharing via ScienceMesh functionality
 * between oCIS v5 and Nextcloud v27. This suite covers sending and accepting invitation links,
 * sharing files via ScienceMesh, and verifying that the shares are received correctly.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  openFilesAppV5,
  openScienceMeshAppV5,
  createLegacyInviteLinkV5,
  createTextFileV5,
  createShareV5,
} from '../utils/ocis-5';

import {
  acceptShareV27,
  verifyFederatedContactV27,
  acceptScienceMeshInvitation,
  ensureFileExistsV27,
  navigationSwitchLeftSideV27,
  selectAppFromLeftSideV27,
} from '../utils/nextcloud-v27';

describe('Invite link federated sharing via ScienceMesh functionality between oCIS and Nextcloud', () => {
  // Shared variables to avoid repetition and improve maintainability
  const senderUrl = Cypress.env('OCIS1_URL') || 'https://ocis1.docker';
  const recipientUrl = Cypress.env('NEXTCLOUD1_URL') || 'https://nextcloud1.docker';
  const senderUsername = Cypress.env('OCIS1_USERNAME') || 'einstein';
  const senderPassword = Cypress.env('OCIS1_PASSWORD') || 'relativity';
  const recipientUsername = Cypress.env('NEXTCLOUD1_USERNAME') || 'michiel';
  const recipientPassword = Cypress.env('NEXTCLOUD1_PASSWORD') || 'dejong';

  // Display names might be different from usernames
  const senderDisplayName = Cypress.env('OCIS1_DISPLAY_NAME') || 'Albert Einstein';

  // Extract domain without protocol or trailing slash
  const senderDomain = senderUrl.replace(/^https?:\/\/|\/$/g, '');
  const recipientDomain = recipientUrl.replace(/^https?:\/\/|\/$/g, '');

  // File-related constants
  const inviteLinkFileName = 'invite-link-ocis-nc.txt';
  const sharedFileName = inviteLinkFileName;
  const sharedFileContent = 'Hello World!';

  /**
   * Test case: Sending an invitation token from oCIS to Nextcloud.
   * Steps:
   * 1. Log in to the sender's oCIS instance
   * 2. Navigate to the ScienceMesh app
   * 3. Generate the invite token and save it to a file
   */
  it('Send invitation from oCIS v5 to Nextcloud v27', () => {
    // Step 1: Log in to the sender's oCIS instance
    cy.loginOcis(senderUrl, senderUsername, senderPassword);

    // Step 2: Navigate to the ScienceMesh app
    openScienceMeshAppV5();

    // Step 3: Generate the invite link and save it to a file
    createLegacyInviteLinkV5(recipientDomain, senderDomain).then((inviteLink) => {
      // Ensure the invite link is not empty
      expect(inviteLink).to.be.a('string').and.not.be.empty;
      // Save the invite link to a file for later use
      cy.writeFile(inviteLinkFileName, inviteLink);
    });

    // Wait for the operation to complete
    cy.wait(5000);
  });

  /**
   * Test case: Accepting the invitation token on Nextcloud side.
   * Steps:
   * 1. Load the invite token from the saved file
   * 2. Log in to the recipient's Nextcloud instance
   * 3. Accept the invitation
   * 4. Verify the federated contact is established
   */
  it('Accept invitation from oCIS v5 to Nextcloud v27', () => {
    const expectedContactDisplayName = senderDisplayName;
    // Extract domain without protocol or trailing slash
    // Note: The 'reva' prefix is added to the expected contact domain as per application behavior
    const expectedContactDomain = senderDomain;

    // Step 1: Load the invite link from the file
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
   * Test case: Sharing a file via ScienceMesh from oCIS to Nextcloud.
   * Steps:
   * 1. Log in to the sender's oCIS instance
   * 2. Create a text file with content
   * 3. Navigate to the Files app
   * 4. Share the file with the recipient
   */
  it('Send ScienceMesh share <file> from oCIS v5 to Nextcloud v27', () => {
    // Step 1: Log in to the sender's oCIS instance
    cy.loginOcis(senderUrl, senderUsername, senderPassword);

    // Step 2: Create a text file with content
    createTextFileV5(sharedFileName, sharedFileContent);

    // Step 3: Navigate to the Files app
    openFilesAppV5();

    // Step 4: Share the file with the recipient
    createShareV5(sharedFileName, recipientUsername);

    // Wait for the operation to complete
    cy.wait(5000);
  });

  /**
   * Test case: Receiving and verifying the ScienceMesh share on Nextcloud side.
   * Steps:
   * 1. Log in to the recipient's Nextcloud instance
   * 2. Accept the shared file
   * 3. Navigate to the correct section
   * 4. Verify the shared file exists
   */
  it('Receive ScienceMesh share <file> from oCIS v5 to Nextcloud v27', () => {
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
  });
});
