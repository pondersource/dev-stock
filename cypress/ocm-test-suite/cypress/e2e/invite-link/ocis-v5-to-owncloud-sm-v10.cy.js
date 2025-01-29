/**
 * @fileoverview
 * Cypress test suite for testing invite link federated sharing via ScienceMesh functionality
 * between oCIS v5 and ownCloud v10. This suite covers sending and accepting invitation links,
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
} from '../utils/ocis-5'

import {
  acceptShare,
  verifyFederatedContact,
  acceptScienceMeshInvitation,
  ensureFileExists,
  selectAppFromLeftSide,
} from '../utils/owncloud';

describe('Invite link federated sharing via ScienceMesh functionality between oCIS and ownCloud', () => {
  // Shared variables to avoid repetition and improve maintainability
  const senderUrl = Cypress.env('OCIS1_URL') || 'https://ocis1.docker';
  const recipientUrl = Cypress.env('OWNCLOUD1_URL') || 'https://owncloud1.docker';
  const senderUsername = Cypress.env('OCIS1_USERNAME') || 'einstein';
  const senderPassword = Cypress.env('OCIS1_PASSWORD') || 'relativity';
  const recipientUsername = Cypress.env('OWNCLOUD1_USERNAME') || 'marie';
  const recipientPassword = Cypress.env('OWNCLOUD1_PASSWORD') || 'radioactivity';

  // Display names might be different from usernames
  const senderDisplayName = Cypress.env('OCIS1_DISPLAY_NAME') || 'Albert Einstein';

  // Extract domain without protocol or trailing slash
  const senderDomain = senderUrl.replace(/^https?:\/\/|\/$/g, '');
  const recipientDomain = recipientUrl.replace(/^https?:\/\/|\/$/g, '');

  // File-related constants
  const inviteLinkFileName = 'invite-link-ocis-oc.txt';
  const sharedFileName = inviteLinkFileName;
  const sharedFileContent = 'Hello World!';

  /**
   * Test case: Sending an invitation token from oCIS to ownCloud.
   * Steps:
   * 1. Log in to the sender's oCIS instance
   * 2. Navigate to the ScienceMesh app
   * 3. Generate the invite token and save it to a file
   */
  it('Send invitation from oCIS v5 to ownCloud v10', () => {
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
   * Test case: Accepting the invitation token on ownCloud side.
   * Steps:
   * 1. Load the invite token from the saved file
   * 2. Log in to the recipient's ownCloud instance
   * 3. Accept the invitation
   * 4. Verify the federated contact is established
   */
  it('Accept invitation from oCIS v5 to ownCloud v10', () => {
    const expectedContactDisplayName = senderDisplayName;
    // Extract domain without protocol or trailing slash
    // Note: The 'reva' prefix is added to the expected contact domain as per application behavior
    const expectedContactDomain = senderDomain;

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
   * Test case: Sharing a file via ScienceMesh from oCIS to ownCloud.
   * Steps:
   * 1. Log in to the sender's oCIS instance
   * 2. Create a text file with content
   * 3. Navigate to the Files app
   * 4. Share the file with the recipient
   */
  it('Send ScienceMesh share <file> from oCIS v5 to ownCloud v10', () => {
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
   * Test case: Receiving and verifying the ScienceMesh share on ownCloud side.
   * Steps:
   * 1. Log in to the recipient's ownCloud instance
   * 2. Verify the shared file exists and has correct sharing information
   */
  it('Receive ScienceMesh share <file> from oCIS v5 to ownCloud v10', () => {
    // Step 1: Log in to the recipient's ownCloud instance
    cy.loginOwncloud(recipientUrl, recipientUsername, recipientPassword);

    // Step 2: Wait for the share dialog to appear and accept the incoming federated share
    acceptShare();

    // Step 3: Navigate to the correct section
    selectAppFromLeftSide('files');

    // Step 4: Verify that the shared file is visible
    ensureFileExists(sharedFileName);
  });
})
