/**
 * @fileoverview
 * Cypress test suite for testing federated sharing functionality via share-link flow in Nextcloud v27 and OcmStub v1.
 *
 * @author Michiel B. de Jong <michiel@pondersource.com>
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  createShareLinkV27,
  ensureFileExistsV27,
  renameFileV27,
} from '../utils/nextcloud-v27';

import {
  generateShareAssertions,
} from '../utils/ocmstub-v1.js';

describe('Share link federated sharing functionality for Nextcloud to OcmStub', () => {
  // Shared variables to avoid repetition and improve maintainability
  const senderUrl = Cypress.env('NEXTCLOUD1_URL') || 'https://nextcloud1.docker';
  const recipientUrl = Cypress.env('OCMSTUB1_URL') || 'https://ocmstub1.docker';
  const senderUsername = Cypress.env('NEXTCLOUD1_USERNAME') || 'einstein';
  const senderPassword = Cypress.env('NEXTCLOUD1_PASSWORD') || 'relativity';
  const recipientUsername = Cypress.env('OCMSTUB1_USERNAME') || 'michiel';
  const originalFileName = 'welcome.txt';
  const sharedFileName = 'nc1-to-os1-share.txt';
  const sharedWith = 'michiel@ocmstub1.docker';

  // Expected details of the federated share
  const expectedShareDetails = {
    shareWith: `${recipientUsername}@${recipientUrl}`,
    fileName: sharedFileName,
    owner: `${senderUsername}@${senderUrl}/`,
    sender: `${senderUsername}@${senderUrl}/`,
    shareType: 'user',
    resourceType: 'file',
    protocol: 'webdav'
  };

  /**
   * Test Case: Sending a federated share from one Nextcloud instance to OcmStub.
   * Validates that a file can be successfully shared from Nextcloud to OcmStub.
   */
  it('Send federated share <file> from Nextcloud v27 to OcmStub v1', () => {
    // Step 1: Log in to the sender's Nextcloud instance
    cy.loginNextcloud(senderUrl, senderUsername, senderPassword)

    // Step 2: Ensure the original file exists before renaming
    ensureFileExistsV27(originalFileName);

    // Step 3: Rename the file to prepare it for sharing
    renameFileV27(originalFileName, sharedFileName);
    
    // Step 4: Verify the file has been renamed
    ensureFileExistsV27(sharedFileName);

    // Step 5: Create a federated share for the recipient
    // TODO @MahdiBaghbani: We should hide any complexity in .cy.js files and move them to utils/*.js files
    createShareLinkV27(sharedFileName).then(
      (result) => {
        cy.visit(result)

        cy.get('button[id="header-actions-toggle"]').click()
        cy.get('button[id="save-external-share"]').click()

        cy.get('form[class="save-form"]').within(() => {
          cy.get('input[id="remote_address"]').type(sharedWith)
          cy.get('input[id="save-button-confirm"]').click()
        })
      }
    )
  })

  /**
   * Test Case: Receiving a federated share on OcmStub from Nextcloud.
   */
  it('Receive federated share of a file from from Nextcloud v27 to OcmStub v1', () => {
    // Step 1: Log in to OcmStub
    cy.loginOcmStub(recipientUrl);

    // Step 2: Create an array of strings to verify. Each string is a snippet of text expected to be found on the page.
    // These assertions represent lines or properties that should appear in the OcmStub's displayed share metadata.
    // Adjust these strings if the page format changes.
    const shareAssertions = generateShareAssertions(expectedShareDetails, true);

    // Step 3: Loop through all assertions and verify their presence on the page
    // We use `cy.contains()` to search for the text anywhere on the page.
    // The `should('be.visible')` ensures that the text is actually visible, not hidden or off-screen.
    shareAssertions.forEach((assertion) => {
      cy.contains(assertion, { timeout: 10000 })
        .should('be.visible');
    });
  });
})
