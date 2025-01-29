/**
 * @fileoverview
 * Cypress test suite for testing native federated sharing functionality in ownCloud v10 and OcmStub v1.
 *
 * @author Michiel B. de Jong <michiel@pondersource.com>
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  createShare,
  renameFile,
  ensureFileExists,
} from '../utils/owncloud-v10';

import {
  generateShareAssertions,
} from '../utils/ocmstub-v1.js';

describe('Native Federated Sharing Functionality for ownCloud to OcmStub', () => {

  // Shared variables to avoid repetition and improve maintainability
  const senderUrl = Cypress.env('OWNCLOUD1_URL') || 'https://owncloud1.docker';
  const recipientUrl = Cypress.env('OCMSTUB1_URL') || 'https://ocmstub1.docker';
  const senderUsername = Cypress.env('OWNCLOUD1_USERNAME') || 'marie';
  const senderPassword = Cypress.env('OWNCLOUD1_PASSWORD') || 'radioactivity';
  const recipientUsername = Cypress.env('OCMSTUB1_USERNAME') || 'michiel';
  const originalFileName = 'welcome.txt';
  const sharedFileName = 'oc1-to-os1-share.txt';

  // Expected details of the federated share
  const expectedShareDetails = {
    shareWith: `${recipientUsername}@${recipientUrl.replace(/^https?:\/\/|\/$/g, '')}`,
    fileName: sharedFileName,
    owner: `${senderUsername}@${senderUrl}`,
    sender: `${senderUsername}@${senderUrl}`,
    shareType: 'user',
    resourceType: 'file',
    protocol: 'webdav'
  };

  /**
   * Test Case: Sending a federated share from one ownCloud to OcmStub.
   * Validates that a file can be successfully shared from ownCloud to OcmStub.
   */
  it('Send a federated share of a file from ownCloud v10 to OcmStub v1', () => {
    // Step 1: Log in to the sender's ownCloud instance
    cy.loginOwncloud(senderUrl, senderUsername, senderPassword);

    // Step 2: Ensure the original file exists
    ensureFileExists(originalFileName);

    // Step 3: Rename the file
    renameFile(originalFileName, sharedFileName);

    // Step 4: Verify the file has been renamed
    ensureFileExists(sharedFileName);

    // Step 5: Create a federated share for the recipient
    createShare(sharedFileName, recipientUsername, recipientUrl.replace(/^https?:\/\/|\/$/g, ''));

    // TODO @MahdiBaghbani: Verify that the share was created successfully
  });

  /**
   * Test Case: Receiving a federated share on OcmStub from ownCloud.
   * 
   */
  it('Receive federated share of a file from from ownCloud v10 to OcmStub v1', () => {
    // Step 1: Log in to OcmStub
    cy.loginOcmStub(recipientUrl);

    // Create an array of strings to verify. Each string is a snippet of text expected to be found on the page.
    // These assertions represent lines or properties that should appear in the OcmStub's displayed share metadata.
    // Adjust these strings if the page format changes.
    const shareAssertions = generateShareAssertions(expectedShareDetails);

    // Step 2: Loop through all assertions and verify their presence on the page
    // We use `cy.contains()` to search for the text anywhere on the page.
    // The `should('be.visible')` ensures that the text is actually visible, not hidden or off-screen.
    shareAssertions.forEach((assertion) => {
      cy.contains(assertion, { timeout: 10000 })
        .should('be.visible');
    });
  });
})
