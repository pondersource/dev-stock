/**
 * @fileoverview
 * Cypress test suite for testing native federated sharing functionality in OcmStub.
 *
 * @author Michiel De Jong <michiel@pondersource.com>
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  generateShareAssertions,
} from '../utils/ocmstub-v1.js';

describe('Native federated sharing functionality for OcmStub', () => {

  // Shared variables to avoid repetition and improve maintainability
  const senderUrl = Cypress.env('OCMSTUB1_URL') || 'https://ocmstub1.docker';
  const recipientUrl = Cypress.env('OCMSTUB2_URL') || 'https://ocmstub2.docker';
  const senderUsername = Cypress.env('OCMSTUB1_USERNAME') || 'einstein';
  const recipientUsername = Cypress.env('OCMSTUB2_USERNAME') || 'mahdi';
  const expectedMessage = 'yes shareWith';

  // Expected details of the federated share
  const expectedShareDetails = {
    shareWith: `${recipientUsername}@${recipientUrl.replace(/^https?:\/\/|\/$/g, '')}`,
    fileName: 'Test share from stub',
    owner: `${senderUsername}@${senderUrl.replace(/^https?:\/\/|\/$/g, '')}`,
    sender: `${senderUsername}@${senderUrl.replace(/^https?:\/\/|\/$/g, '')}`,
    shareType: 'user',
    resourceType: 'file',
    protocol: 'webdav'
  };

  /**
   * Test Case: Sending a federated share from OcmStub 1.0 to OcmStub 1.0.
   */
  it('should successfully send a federated share of a file from OcmStub 1.0 to OcmStub 1.0', () => {
    // Step 1: Navigate to the federated share link on OcmStub 1.0
    // Remove trailing slash and leading https or http from recipientUrl
    cy.visit(`${senderUrl}/shareWith?${recipientUsername}@${recipientUrl.replace(/^https?:\/\/|\/$/g, '')}`);

    // Step 2: Verify the confirmation message is displayed
    cy.contains(expectedMessage, { timeout: 10000 })
      .should('be.visible')
  });

  /**
   * Test Case: Receiving a federated share on OcmStub from ocmStub.
   * 
   */
  it('Receive federated share of a file from from OcmStub v1 to OcmStub v1', () => {
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
