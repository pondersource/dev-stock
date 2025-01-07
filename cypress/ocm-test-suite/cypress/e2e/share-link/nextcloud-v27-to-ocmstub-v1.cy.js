import {
  createShareLinkV27,
  renameFileV27,
  navigationSwitchLeftSideV27,
  selectAppFromLeftSideV27,
} from '../utils/nextcloud-v27'

describe('Share link federated sharing functionality for Nextcloud', () => {
  it('Send federated share <file> from Nextcloud v27 to Nextcloud v27', () => {
    // send share from Nextcloud 1.
    cy.loginNextcloud('https://nextcloud1.docker', 'einstein', 'relativity')

    renameFileV27('welcome.txt', 'nc1-to-nc2-share-link.txt')
    createShareLinkV27('nc1-to-nc2-share-link.txt').then(
      (result) => {
        cy.visit(result)

        cy.get('button[id="header-actions-toggle"]').click()
        cy.get('button[id="save-external-share"]').click()

        cy.get('form[class="save-form"]').within(() => {
          cy.get('input[id="remote_address"]').type('michiel@nextcloud2.docker')
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

    // Create an array of strings to verify. Each string is a snippet of text expected to be found on the page.
    // These assertions represent lines or properties that should appear in the OcmStub's displayed share metadata.
    // Adjust these strings if the page format changes.
    const shareAssertions = generateShareAssertions(expectedShareDetails);

    // work around https://github.com/nextcloud/server/issues/36340
    shareAssertions['sharedBy'] = shareAssertions['sender'];
    delete shareAssertions['sender'];

    // Step 2: Loop through all assertions and verify their presence on the page
    // We use `cy.contains()` to search for the text anywhere on the page.
    // The `should('be.visible')` ensures that the text is actually visible, not hidden or off-screen.
    shareAssertions.forEach((assertion) => {
      cy.contains(assertion, { timeout: 10000 })
        .should('be.visible');
    });
  });
})
