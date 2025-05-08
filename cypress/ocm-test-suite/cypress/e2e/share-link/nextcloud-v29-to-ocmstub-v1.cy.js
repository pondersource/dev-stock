/**
 * @fileoverview
 * Cypress test suite for testing federated share link functionality between Nextcloud v29 and OcmStub v1.
 * This suite verifies the ability to send and receive federated file shares via share links between
 * Nextcloud v29 and OcmStub v1 instances.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  createAndSendShareLinkV29,
  renameFileV29,
  ensureFileExistsV29,
} from '../utils/nextcloud-v29';

import {
  generateShareAssertions,
} from '../utils/ocmstub-v1';

describe('Share Link Federated Sharing Functionality for Nextcloud to OcmStub', () => {
  // Shared variables to avoid repetition and improve maintainability
  const senderUrl = Cypress.env('NEXTCLOUD1_URL') || 'https://nextcloud1.docker';
  const recipientUrl = Cypress.env('OCMSTUB1_URL') || 'https://ocmstub1.docker';
  const senderUsername = Cypress.env('NEXTCLOUD1_USERNAME') || 'einstein';
  const senderPassword = Cypress.env('NEXTCLOUD1_PASSWORD') || 'relativity';
  const recipientUsername = Cypress.env('OCMSTUB1_USERNAME') || 'michiel';
  const originalFileName = 'welcome.txt';
  const sharedFileName = 'share-link-nc1-to-os1.txt';

  // Expected details of the federated share
  const expectedShareDetails = {
    shareWith: `${recipientUsername}@${recipientUrl}`,
    fileName: sharedFileName,
    owner: `${senderUsername}@${senderUrl.replace(/^https?:\/\/|\/$/g, '')}`,
    sender: `${senderUsername}@${senderUrl.replace(/^https?:\/\/|\/$/g, '')}`,
    shareType: 'user',
    resourceType: 'file',
    protocol: 'webdav'
  };

  /**
   * Test Case: Sending a federated share link from Nextcloud v29 to Nextcloud v29.
   * Validates that a file can be successfully shared via link from Nextcloud v29 to Nextcloud v29.
   */
  it('Send federated share link of a file from Nextcloud v29 to Nextcloud v29', () => {
    // Step 1: Log in to the sender's Nextcloud instance
    cy.loginNextcloud(senderUrl, senderUsername, senderPassword);

    // Step 2: Ensure the original file exists before renaming
    ensureFileExistsV29(originalFileName);

    // Step 3: Rename the file to prepare it for sharing
    renameFileV29(originalFileName, sharedFileName);

    // Step 4: Verify the file has been renamed
    ensureFileExistsV29(sharedFileName);

    // Step 5: Create and send the share link to the recipient
    createAndSendShareLinkV29(
      sharedFileName,
      recipientUsername,
      recipientUrl.replace(/^https?:\/\/|\/$/g, '')
    );
  });

  /**
   * Test Case: Receiving and verifying a federated share link on the recipient's OcmStub instance.
   * Validates that the share metadata is correctly received and displayed in OcmStub.
   */
  it('Receive federated share link of a file from Nextcloud v29 to OcmStub v1', () => {
    // Step 1: Log in to the recipient's OcmStub instance
    cy.loginOcmStub(recipientUrl);

    // Step 2: Generate assertions for share metadata verification
    const shareAssertions = generateShareAssertions(expectedShareDetails, true);

    // Step 3: Verify all share metadata is correctly displayed
    shareAssertions.forEach((assertion) => {
      cy.contains(assertion, { timeout: 10000 })
        .should('be.visible');
    });
  });
});
