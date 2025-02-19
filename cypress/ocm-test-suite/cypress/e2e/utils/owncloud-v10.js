/**
 * @fileoverview
 * Utility functions for Cypress tests interacting with ownCloud version 10.
 * These functions provide abstractions for common actions such as accepting shares,
 * creating federated shares, renaming files, and interacting with the file menu.
 *
 * @author Michiel B. de Jong <michiel@pondersource.com>
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  escapeCssSelector,
} from './general';

/**
 * Ensures that a file with the specified name exists and is visible in the file list.
 *
 * This function waits for the file element to appear in the DOM within the specified timeout and checks that it is visible.
 * If the file does not exist or is not visible within the timeout, the test will fail with an appropriate error message.
 *
 * @param {string} fileName - The name of the file to check.
 * @param {number} [timeout=10000] - Optional timeout in milliseconds for the check. Defaults to 10000ms.
 *
 * @example
 * // Ensure that the file 'example.txt' exists and is visible
 * ensureFileExists('example.txt');
 *
 * @throws Will cause the test to fail if the file does not exist or is not visible within the timeout.
 */
export function ensureFileExists(fileName, timeout = 10000) {
  // Escape special characters in the file name to safely use it in a CSS selector
  const escapedFileName = escapeCssSelector(fileName);

  // Wait for the file row to exist in the DOM and be visible
  cy.get(`[data-file="${escapedFileName}"]`, { timeout })
    .should('exist')
    .and('be.visible');
}

/**
 * Accepts a share dialog by clicking the "primary" button.
 */
export function acceptShare() {
  // Wait for the share dialog to appear and ensure it's visible
  cy.get('div.oc-dialog', { timeout: 10000 })
    .should('be.visible')
    .within(() => {
      // Locate the button row and click the primary button
      cy.get('div.oc-dialog-buttonrow')
        .find('button.primary')
        .should('exist')
        .click({ force: true });
    });
}

/**
 * Handles multiple share acceptance pop-ups that may appear after reloads.
 * This function recursively checks for and accepts share dialogs until none remain,
 * then verifies the shared file exists.
 * 
 * @param {string} fileName - The name of the shared file to verify exists.
 * @param {number} [timeout=10000] - Optional timeout for the final file existence check.
 * @param {string} [appId='files'] - The app ID to navigate to after accepting shares.
 * @param {number} [depth=0] - Current recursion depth.
 * @param {number} [maxDepth=5] - Maximum allowed recursion depth to prevent infinite loops.
 */
export function handleShareAcceptanceOcV10(fileName, timeout = 10000, appId = 'files', depth = 0, maxDepth = 5) {
  // Check if maximum recursion depth has been reached
  if (depth >= maxDepth) {
    throw new Error(`Maximum recursion depth (${maxDepth}) reached while handling share acceptance. 
      This might indicate an issue with the sharing process.`);
  }

  // Wait for the page to be fully loaded
  cy.wait(500);

  // Try to find the share dialog with a reasonable timeout
  cy.get('body', { timeout: 10000 }).then($body => {
    // Check if dialog exists and is visible
    const hasDialog = $body.find('div.oc-dialog:visible').length > 0;

    if (hasDialog) {
      // If dialog exists, accept it
      acceptShare();
      // Wait a bit for the acceptance to be processed
      cy.wait(500);
      // Reload and continue checking
      cy.reload(true).then(() => {
        // Wait for page load after reload
        cy.wait(500);
        // Recursively check for more pop-ups with incremented depth
        handleShareAcceptanceOcV10(fileName, timeout, appId, depth + 1, maxDepth);
      });
    } else {
      // No more pop-ups, wait for the file list to be loaded
      cy.wait(1000);

      // Step 3: Navigate to the correct section
      selectAppFromLeftSide(appId);

      // Verify the shared file exists with specified timeout
      ensureFileExists(fileName, timeout);
    }
  });
}

/**
 * Creates a share for a specific file and user.
 * @param {string} fileName - The name of the file to be shared.
 * @param {string} username - The username of the recipient.
 * @param {string} domain - The domain of the recipient.
 */
export function createShare(fileName, username, domain) {
  // Open the sharing panel for the specified file
  openSharingPanel(fileName);

  // Set up an intercept for the user search API request
  cy.intercept('GET', '**/apps/files_sharing/api/v1/sharees?*').as('userSearch');

  cy.get('#app-sidebar').within(() => {
    // Clear and type the recipient's federated ID
    cy.get('[id^="shareWith-"]')
      .clear()
      .type(`${username}@${domain}`);
  });

  // Wait for the user search API request to complete
  cy.wait('@userSearch');

  // Select the recipient as a federated user
  cy.get('.ui-autocomplete')
    .contains('span[class="autocomplete-item-typeInfo"]', 'Federated')
    .should('be.visible')
    .click();
}

/**
 * Creates a group share for a file.
 * @param {string} fileName - The name of the file to share.
 * @param {string} group - The group to share with.
 */
export function createShareGroup(fileName, group) {
  // Open the sharing panel for the specified file
  openSharingPanel(fileName);

  // Set up an intercept for the group search API request
  cy.intercept('GET', '**/apps/files_sharing/api/v1/sharees?*').as('groupSearch');

  cy.get('#app-sidebar').within(() => {
    // Clear and type the group name
    cy.get('[id^="shareWith-"]')
      .clear()
      .type(group);

    // Wait for the group search API request to complete
    cy.wait('@groupSearch');

    // Select the group from the search results
    cy.get('.ui-autocomplete')
      .contains('.username', group)
      .should('be.visible')
      .click();
  });
}

/**
 * Creates a shareable link for a file and returns the copied link.
 * @param {string} fileName - The name of the file to create a link for.
 * @returns {Cypress.Chainable<string>} - A chainable containing the copied share link.
 */
export function createShareLink(fileName) {
  // Open the sharing panel for the specified file
  openSharingPanel(fileName);

  cy.get('#app-sidebar').within(() => {
    // Click on "Public Links" tab
    cy.contains('li', 'Public Links')
      .should('be.visible')
      .click();

    // Click on "Create public link" button
    cy.contains('button', 'Create public link')
      .should('be.visible')
      .click();
  });

  // Accept the share dialog if it appears
  cy.get('div.oc-dialog', { timeout: 10000 }).then(($dialog) => {
    if ($dialog.is(':visible')) {
      cy.wrap($dialog)
        .should('be.visible')
        .within(() => {
          cy.get('div.oc-dialog-buttonrow')
            .find('button.primary')
            .should('be.visible')
            .click();
        });
    }
  });

  // Extract and return the public share link
  cy.get('#app-sidebar').within(() => {
    cy.get('.link-entry .linkText')
      .invoke('val')
      .then((link) => {
        cy.visit(link)
        // save share url to file.
        cy.writeFile('share-link-url.txt', link)
      });
  });
}

/**
 * Generates an invite token for federated sharing.
 * Extracts the token from the input field and returns it.
 * @returns {Cypress.Chainable<string>} - A chainable containing the extracted invite token.
 */
export function createInviteToken() {
  // Ensure the "Generate Token" button is visible and click it
  cy.get('button#token-generator')
    .should('be.visible')
    .click();

  // Extract and process the token from the input field
  return cy.get('input.generated-token-link')
    .invoke('val')
    .then((link) => {
      if (!link) {
        throw new Error('Token generation failed: No token found in the input field.');
      }
      // Use URLSearchParams to parse the link and extract the token
      const url = new URL(link);
      const token = url.searchParams.get('token');
      if (!token) {
        throw new Error('Token generation failed: Token parameter not found in the URL.');
      }
      return token;
    });
}

/**
 * Generates an invite link for federated sharing.
 * Combines the extracted token with the target domain to create an invite link.
 * @param {string} targetDomain - The domain of the recipient.
 * @returns {Cypress.Chainable<string>} - A chainable containing the generated invite link.
 */
export function createInviteLink(targetDomain) {
  // Ensure the "Generate Token" button is visible and click it
  cy.get('button#token-generator')
    .should('be.visible')
    .click();

  // Extract the token and construct the invite link
  return cy.get('input.generated-token-link')
    .invoke('val')
    .then((link) => {
      if (!link) {
        throw new Error('Invite link generation failed: No link found in the input field.');
      }
      // Extract the query parameters from the link
      const url = new URL(link);
      const queryParams = url.searchParams.toString();
      // Construct the invite link with the target domain
      return `${targetDomain}/index.php/apps/sciencemesh/accept?${queryParams}`;
    });
}

/**
 * Verifies a federated contact in the contacts table.
 * @param {string} domain - The domain of the application.
 * @param {string} displayName - The display name of the contact.
 * @param {string} contactDomain - The expected domain of the contact.
 */
export function verifyFederatedContact(domain, displayName, contactDomain) {
  cy.visit(`https://${domain}/index.php/apps/sciencemesh`);

  cy.get('table#contact-table')
    .find('p.displayname', { timeout: 10000 })
    // Ensure the display name is present
    .contains(displayName)
    // Traverse to the parent row
    .closest('tr')
    .find('p.username-provider')
    // Extract the username and domain text
    .invoke('text')
    .then((usernameWithDomain) => {
      // Extract domain after '@'
      const extractedDomain = usernameWithDomain.split('@').pop();

      // Assert the domain matches
      expect(extractedDomain).to.equal(contactDomain);
    });
}

/**
 * Accepts an invitation by clicking the accept button in the invitation dialog.
 *
 * This function waits for the invitation accept button to be visible and enabled within the specified timeout,
 * and then clicks it to accept the invitation.
 *
 * @param {number} [timeout=10000] - Optional timeout in milliseconds for waiting for the accept button. Defaults to 10000ms.
 *
 * @example
 * // Accept the invitation
 * acceptScienceMeshInvitation(5000);
 *
 * @throws Will cause the test to fail if the accept button is not visible or interactable within the timeout.
 */
export function acceptScienceMeshInvitation(timeout = 10000) {
  // Wait for the accept button to be visible and enabled
  cy.get('input#accept-button', { timeout })
    .should('be.visible')
    // Ensure the button is not disabled
    .and('not.be.disabled')
    .click();
}

/**
 * Shares a file using ScienceMesh federated sharing.
 * Opens the sharing panel, types the recipient's details, and selects the federated recipient.
 * @param {string} fileName - The name of the file to share.
 * @param {string} username - The username of the recipient.
 * @param {string} domain - The domain of the recipient.
 */
export function createScienceMeshShare(fileName, username, domain) {
  // Open the sharing panel for the file
  openSharingPanel(fileName);

  // Set up an intercept for the user search API request
  cy.intercept('GET', '**/apps/files_sharing/api/v1/sharees?*').as('userSearch');

  cy.get('#app-sidebar').within(() => {
    // Clear the input field and type the recipient's details
    cy.get('[id^="shareWith-"]')
      .clear()
      .type(`${username}@${domain}`);
  });

  // Wait for the user search API request to complete
  cy.wait('@userSearch');

  // Select the recipient as a federated user
  cy.get('.ui-autocomplete')
    .contains('span[class="autocomplete-item-typeInfo"]', 'Federated')
    .should('be.visible', { timeout: 10000 })
    .click();
}

/**
 * Renames a file and waits for the move operation to complete.
 * @param {string} fileName - The current name of the file.
 * @param {string} newFileName - The new name for the file.
 */
export function renameFile(fileName, newFileName) {
  // Trigger the "Rename" action from the file's menu
  triggerActionInFileMenu(fileName, 'Rename');

  // Intercept the MOVE API request for renaming files
  cy.intercept('MOVE', '**/remote.php/dav/files/**').as('moveFile');

  // Find the file row and enter the new file name
  const fileRow = getRowForFile(fileName);
  fileRow.find('form input')
    .should('be.visible')
    .clear()
    .type(`${newFileName}{enter}`);

  // Wait for the move operation to complete
  cy.wait('@moveFile');
}

/**
 * Opens the sharing panel for a specific file.
 * @param {string} fileName - The name of the file.
 */
export function openSharingPanel(fileName) {
  // Trigger the "Share" action for the specified file
  triggerActionForFile(fileName, 'Share');

  // Wait for the sharing panel to be fully loaded
  cy.get('#app-sidebar')
    .should('be.visible')
    .within(() => {
      cy.get('[data-tabid="shareTabView"]')
        .should('be.visible')
        .click()
        .should('have.class', 'selected');
    });
}

/**
 * Selects an app from the left-side navigation menu.
 * @param {string} appId - The identifier of the app to select.
 * Valid values:
 * - "files"
 * - "favorites"
 * - "sharingin"
 * - "sharingout"
 * - "sharinglinks"
 * - "systemtagsfilter"
 * - "trashbin"
 */
export function selectAppFromLeftSide(appId) {
  const validAppIds = [
    "files",
    "favorites",
    "sharingin",
    "sharingout",
    "sharinglinks",
    "systemtagsfilter",
    "trashbin"
  ];

  // Validate the appId
  if (!validAppIds.includes(appId)) {
    throw new Error(`Invalid appId: "${appId}". Valid options are ${validAppIds.join(", ")}.`);
  }

  // Find the app in the navigation menu and click it
  cy.get('div#app-navigation', { timeout: 10000 })
    .should('be.visible')
    .find(`li[data-id="${appId}"]`)
    .should('exist')
    .click({ force: true });
}

/**
 * Triggers a specific action in the file menu.
 * @param {string} fileName - The name of the file.
 * @param {string} actionId - The ID of the action to trigger (e.g., 'Rename').
 */
export function triggerActionInFileMenu(fileName, actionId) {
  // Open the file's action menu
  triggerActionForFile(fileName, 'menu');

  // Find and click the desired action within the file menu
  cy.get('.fileActionsMenu')
    .should('be.visible')
    .within(() => {
      cy.get(`[data-action="${actionId}"]`)
        .should('be.visible')
        .as('btn')
        .click();
    });
}

/**
 * Triggers a specific action for a file.
 * @param {string} fileName - The name of the file.
 * @param {string} actionId - The ID of the action to trigger (e.g., 'Share', 'menu').
 */
export function triggerActionForFile(fileName, actionId) {
  // Find the actions container for the file and click the desired action
  getActionsForFile(fileName)
    .within(() => {
      // Find the action button and ensure it's properly loaded
      cy.get(`*[data-action="${actionId}"]`)
        .should('exist')
        .and('be.visible')
        .and('not.be.disabled')
        // Use { force: true } to handle cases where the element might be covered
        .click({ force: true });
    });
}

/**
 * Retrieves the actions container for a specific file.
 * @param {string} fileName - The name of the file.
 * @returns {Cypress.Chainable<JQuery<HTMLElement>>} - The actions container element.
 */
export function getActionsForFile(fileName) {
  // Wait for the file row to be stable before proceeding
  return getRowForFile(fileName)
    .within(() => {
      return cy.get('.fileactions')
        .should('exist')
        .and('be.visible');
    });
}

/**
 * Retrieves the row element for a specific file.
 * @param {string} fileName - The name of the file.
 * @returns {Cypress.Chainable<JQuery<HTMLElement>>} - The row element for the file.
 */
export function getRowForFile(fileName) {
  return cy.get(`[data-file="${escapeCssSelector(fileName)}"]`)
    .should('exist')
    .and('be.visible');
}
