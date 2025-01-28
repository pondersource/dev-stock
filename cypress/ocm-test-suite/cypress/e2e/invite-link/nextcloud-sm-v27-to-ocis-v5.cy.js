/**
 * @fileoverview
 * Cypress test suite for testing invite link federated sharing via ScienceMesh functionality
 * between Nextcloud v27 and oCIS v5. This suite covers sending and accepting invitation links,
 * sharing files via ScienceMesh, and verifying that the shares are received correctly.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  createInviteToken,
  createScienceMeshShareV27,
  renameFileV27,
  ensureFileExistsV27,
} from '../utils/nextcloud-v27';

import {
  acceptInviteLinkV5,
  verifyFederatedContactV5,
  acceptShareV5,
  verifyShareV5
} from '../utils/ocis-5';

describe('Invite link federated sharing via ScienceMesh functionality between Nextcloud and oCIS', () => {
  // Shared variables to avoid repetition and improve maintainability
  const senderUrl = Cypress.env('NEXTCLOUD1_URL') || 'https://nextcloud1.docker';
  const recipientUrl = Cypress.env('OCIS1_URL') || 'https://ocis1.docker';
  const senderUsername = Cypress.env('NEXTCLOUD1_USERNAME') || 'marie';
  const senderPassword = Cypress.env('NEXTCLOUD1_PASSWORD') || 'radioactivity';
  const recipientUsername = Cypress.env('OCIS1_USERNAME') || 'einstein';
  const recipientPassword = Cypress.env('OCIS1_PASSWORD') || 'relativity';

  // Display names might be different from usernames
  const senderDisplayName = Cypress.env('NEXTCLOUD1_DISPLAY_NAME') || 'marie';
  const recipientDisplayName = Cypress.env('OCIS1_DISPLAY_NAME') || 'Albert Einstein';

  // Extract domain without protocol or trailing slash
  const senderDomain = senderUrl.replace(/^https?:\/\/|\/$/g, '');
  const recipientDomain = recipientUrl.replace(/^https?:\/\/|\/$/g, '');

  // File-related constants
  const inviteLinkFileName = 'invite-link-nc-ocis.txt';
  const originalFileName = 'welcome.txt';
  const sharedFileName = inviteLinkFileName;

  /**
   * Test case: Sending an invitation link from Nextcloud to oCIS.
   * Steps:
   * 1. Log in to the sender's Nextcloud instance
   * 2. Navigate to the ScienceMesh app
   * 3. Generate the invite link and save it to a file
   */
  it('Send invitation from Nextcloud v27 to oCIS v5', () => {
    // Step 1: Log in to the sender's Nextcloud instance
    cy.loginNextcloud(senderUrl, senderUsername, senderPassword);

    // Step 2: Navigate to the ScienceMesh app
    cy.visit(`${senderUrl}/index.php/apps/sciencemesh/contacts`);

    // Step 3: Generate the invite token and save it to a file
    createInviteToken().then((inviteToken) => {
      // Ensure the invite token is not empty
      expect(inviteToken).to.be.a('string').and.not.be.empty;
      // Save the invite token to a file for later use
      cy.writeFile(inviteLinkFileName, inviteToken);
    });
  });

  /**
   * Test case: Accepting the invitation link on oCIS side.
   * Steps:
   * 1. Load the invite link from the saved file
   * 2. Log in to the recipient's oCIS instance
   * 3. Accept the invitation
   * 4. Verify the federated contact is established
   */
  it('Accept invitation from Nextcloud v27 to oCIS v5', () => {
    // Step 1: Load the invite token from the saved file
    cy.readFile(inviteLinkFileName).then((token) => {
      // Verify token exists and is not empty
      expect(token).to.exist;
      expect(token.trim()).to.not.be.empty;
      cy.log('Read token from file:', token);

      // Step 2: Log in to the recipient's oCIS instance
      cy.loginOcis(recipientUrl, recipientUsername, recipientPassword);

      // Step 3: Accept the invitation
      acceptInviteLinkV5(token);

      // Step 4: Verify the federated contact is established
      verifyFederatedContactV5(senderDisplayName, senderDomain);
    });

    // Wait for the operation to complete
    cy.wait(5000);
  });

  /**
   * Test case: Sharing a file via ScienceMesh from Nextcloud to oCIS.
   * Steps:
   * 1. Log in to the sender's Nextcloud instance
   * 2. Ensure the original file exists
   * 3. Rename the file for sharing
   * 4. Create the share for the recipient
   */
  it('Send ScienceMesh share <file> from Nextcloud v27 to oCIS v5', () => {
    // Step 1: Log in to the sender's Nextcloud instance
    cy.loginNextcloud(senderUrl, senderUsername, senderPassword);

    // Step 2: Ensure the original file exists
    ensureFileExistsV27(originalFileName);

    // Step 3: Rename the file for sharing
    renameFileV27(originalFileName, sharedFileName);

    // Step 4: Verify the file has been renamed
    ensureFileExistsV27(sharedFileName);

    // Step 5: Create the share for the recipient
    createScienceMeshShareV27(
      senderDomain,
      recipientDisplayName,
      recipientUrl,
      sharedFileName
    );
  });

  /**
   * Test case: Receiving and verifying the ScienceMesh share on oCIS side.
   * Steps:
   * 1. Log in to the recipient's oCIS instance
   * 2. Navigate to the Files app
   * 3. Verify the shared file exists
   */
  it('Receive ScienceMesh share <file> from Nextcloud v27 to oCIS v5', () => {
    // Step 1: Log in to the recipient's oCIS instance
    cy.loginOcis(recipientUrl, recipientUsername, recipientPassword);

    // Step 2: Accept the shared file
    acceptShareV5(sharedFileName);

    // Step 3: Reload the page to refresh the view
    cy.reload(true);

    // Step 4: Verify the share details are correct
    verifyShareV5(
      sharedFileName,
      senderDisplayName,
      recipientDisplayName
    );

    // Wait for the operation to complete
    cy.wait(5000);
  });
});
