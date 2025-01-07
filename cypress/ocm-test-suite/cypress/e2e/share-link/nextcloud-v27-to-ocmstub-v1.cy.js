import {
  createShareLinkV27,
  renameFileV27
} from '../utils/nextcloud-v27'

import {
  generateShareAssertions,
} from '../utils/ocmstub-v1.js';

describe('Share link federated sharing functionality for Nextcloud', () => {
  // Shared variables to avoid repetition and improve maintainability
  const senderUrl = Cypress.env('NEXTCLOUD1_URL') || 'https://nextcloud1.docker';
  const recipientUrl = Cypress.env('OCMSTUB1_URL') || 'https://ocmstub1.docker';
  const recipientDomain = recipientUrl.replace(/^https?:\/\/|\/$/g, '');
  const senderUsername = Cypress.env('NEXTCLOUD1_USERNAME') || 'einstein';
  const senderPassword = Cypress.env('NEXTCLOUD1_PASSWORD') || 'relativity';
  const recipientUsername = Cypress.env('OCMSTUB1_USERNAME') || 'michiel';
  const originalFileName = 'welcome.txt';
  const sharedFileName = 'nc1-to-os1-share-link.txt';

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

  it('Send federated share <file> from Nextcloud v27 to ocmstub v1', () => {
    // send share from Nextcloud 1.
    cy.loginNextcloud(senderUrl, senderUsername, senderPassword)

    renameFileV27(originalFileName, sharedFileName)
    createShareLinkV27(sharedFileName).then(
      (result) => {
        cy.visit(result)

        cy.get('button[id="header-actions-toggle"]').click()
        cy.get('button[id="save-external-share"]').click()

        cy.get('form[class="save-form"]').within(() => {
          cy.get('input[id="remote_address"]').type(`${recipientUsername}@${recipientDomain}`)
          cy.get('input[id="save-button-confirm"]').click()
        })
      }
    )
  })

  it('Receive federated share <file> from Nextcloud v27 to ocmstub v1', () => {
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
  })
})
