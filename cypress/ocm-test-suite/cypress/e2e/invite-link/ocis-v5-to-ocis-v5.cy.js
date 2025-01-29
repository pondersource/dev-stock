/**
 * @fileoverview
 * Cypress test suite for testing invite link federated sharing via ScienceMesh functionality in oCIS v5.
 * This suite covers sending and accepting invitation links, sharing files via ScienceMesh,
 * and verifying that the shares are received correctly.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  openFilesAppV5,
  openScienceMeshAppV5,
  createInviteTokenV5,
  acceptInviteLinkV5,
  verifyFederatedContactV5,
  createTextFileV5,
  createShareV5,
  acceptShareV5,
  verifyShareV5
} from '../utils/ocis-v5'

describe('Invite link federated sharing via ScienceMesh functionality for oCIS', () => {
  // Shared variables to avoid repetition and improve maintainability
  const senderUrl = Cypress.env('OCIS1_URL') || 'https://ocis1.docker';
  const recipientUrl = Cypress.env('OCIS2_URL') || 'https://ocis2.docker';
  const senderUsername = Cypress.env('OCIS1_USERNAME') || 'einstein';
  const senderPassword = Cypress.env('OCIS1_PASSWORD') || 'relativity';
  const recipientUsername = Cypress.env('OCIS2_USERNAME') || 'marie';
  const recipientPassword = Cypress.env('OCIS2_PASSWORD') || 'radioactivity';
  
  // Display names might be different from usernames
  const senderDisplayName = Cypress.env('OCIS1_DISPLAY_NAME') || 'Albert Einstein';
  const recipientDisplayName = Cypress.env('OCIS2_DISPLAY_NAME') || 'Marie Skłodowska Curie';
  
  // Extract domain without protocol or trailing slash
  const senderDomain = senderUrl.replace(/^https?:\/\/|\/$/g, '');
  const recipientDomain = recipientUrl.replace(/^https?:\/\/|\/$/g, '');
  
  // File-related constants
  const inviteLinkFileName = 'invite-link-ocis-ocis.txt';
  const sharedFileName = inviteLinkFileName;
  const sharedFileContent = 'Hello World!';

  /**
   * Test case: Sending an invitation token from sender to recipient.
   * Steps:
   * 1. Log in to the sender's oCIS instance
   * 2. Navigate to the ScienceMesh app
   * 3. Generate the invite token and save it to a file
   */
  it('Send invitation from oCIS v5 to oCIS v5', () => {
    // Step 1: Log in to the sender's oCIS instance
    cy.loginOcis(senderUrl, senderUsername, senderPassword);

    // Step 2: Navigate to the ScienceMesh app
    openScienceMeshAppV5();

    // Step 3: Generate the invite token and save it to a file
    createInviteTokenV5().then((token) => {
      // Ensure the token is not empty
      expect(token).to.be.a('string').and.not.be.empty;
      // Save the token to a file for later use
      cy.writeFile(inviteLinkFileName, token);
    });

    // Wait for the operation to complete
    cy.wait(5000);
  });

  /**
   * Test case: Accepting the invitation token on the recipient's side.
   * Steps:
   * 1. Load the invite token from the saved file
   * 2. Log in to the recipient's oCIS instance
   * 3. Accept the invitation
   * 4. Verify the federated contact is established
   */
  it('Accept invitation from oCIS v5 to oCIS v5', () => {
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
   * Test case: Sharing a file via ScienceMesh from sender to recipient.
   * Steps:
   * 1. Log in to the sender's oCIS instance
   * 2. Create a text file with content
   * 3. Navigate to the Files app
   * 4. Share the file with the recipient
   */
  it('Send ScienceMesh share <file> from oCIS v5 to oCIS v5', () => {
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
   * Test case: Receiving and verifying the ScienceMesh share on the recipient's side.
   * Steps:
   * 1. Log in to the recipient's oCIS instance
   * 2. Accept the shared file
   * 3. Reload the page to refresh the view
   * 4. Verify the share details are correct
   */
  it('Receive ScienceMesh share <file> from oCIS v5 to oCIS v5', () => {
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
