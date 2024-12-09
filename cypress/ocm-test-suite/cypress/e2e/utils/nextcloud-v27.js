/**
 * @fileoverview
 * Utility functions for Cypress tests interacting with Nextcloud version 27.
 * These functions provide abstractions for common actions such as sharing files,
 * updating permissions, renaming files, and navigating the UI.
 *
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
export function ensureFileExistsV27(fileName, timeout = 10000) {
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
export function acceptShareV27() {
  // Wait for the share dialog to appear and ensure it's visible
  cy.get('div.oc-dialog', { timeout: 10000 })
    .should('be.visible')
    .within(() => {
      // Locate the button row and click the primary button
      cy.get('div.oc-dialog-buttonrow')
        .find('button.primary')
        .should('be.visible')
        .click();
    });
}

/**
 * Creates a share for a specific file and user.
 * @param {string} fileName - The name of the file to be shared.
 * @param {string} username - The username of the recipient.
 * @param {string} domain - The domain of the recipient.
 */
export function createShareV27(fileName, username, domain) {
  // Open the sharing panel for the specified file
  openSharingPanelV27(fileName);

  // Set up an intercept for the user search API request
  cy.intercept('GET', '**/apps/files_sharing/api/v1/sharees?*').as('userSearch');

  cy.get('#app-sidebar-vue').within(() => {
    // Clear the search input and type the recipient's email
    cy.get('#sharing-search-input')
      .clear()
      .type(`${username}@${domain}`);
  });

  // Wait for the user search API request to complete
  cy.wait('@userSearch');

  // Select the correct user from the search results
  cy.get(`[user="${username}"]`)
    .should('be.visible')
    .click();

  // Click the "Save share" button to finalize the share
  cy.get('div.button-group')
    .contains('Save share')
    .should('be.visible')
    .click();
}

/**
 * Creates a shareable link for a file and returns the copied link.
 * @param {string} fileName - The name of the file to create a link for.
 * @returns {Cypress.Chainable<string>} - A chainable containing the copied share link.
 */
export function createShareLinkV27(fileName) {
  // Open the sharing panel for the specified file
  openSharingPanelV27(fileName);

  // Stub the clipboard API to intercept the copied link
  cy.window().then((win) => {
    cy.stub(win.navigator.clipboard, 'writeText').as('copy');
  });

  cy.get('#app-sidebar-vue').within(() => {
    // Locate and click the "Create a new share link" button
    cy.get('button[title="Create a new share link"]')
      .should('be.visible')
      .click();
  });

  // Verify that the link was copied to the clipboard and retrieve it
  return cy.get('@copy').should('have.been.calledOnce').then((stub) => {
    const copiedLink = stub.args[0][0];
    return copiedLink;
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
export function createInviteLinkV27(targetDomain) {
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
export function verifyFederatedContactV27(domain, displayName, contactDomain) {
  cy.visit(`https://${domain}/index.php/apps/sciencemesh/contacts`);

  cy.get('table#contact-table')
    .find('p.displayname', { timeout: 10000 })
    .contains(displayName) // Ensure the display name is present
    .closest('tr') // Traverse to the parent row
    .find('p.username-provider')
    .invoke('text') // Extract the username and domain text
    .then((usernameWithDomain) => {
      const extractedDomain = usernameWithDomain.split('@').pop(); // Extract domain after '@'
      expect(extractedDomain).to.equal(contactDomain); // Assert the domain matches
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
 * Retrieves the ScienceMesh contact ID from a display name and verifies the contact.
 * @param {string} domain - The domain of the ScienceMesh instance.
 * @param {string} displayName - The display name of the contact.
 * @param {string} contactDomain - The expected domain of the contact.
 * @returns {Cypress.Chainable<string>} - A chainable containing the contact ID in the format "username@domain".
 */
export function getScienceMeshContactIdFromDisplayNameV27(domain, displayName, contactDomain) {
  // Verify that the contact exists in the table
  verifyFederatedContactV27(domain, displayName, contactDomain);

  // Locate the contact in the table and extract the username and domain
  return cy.get('table#contact-table')
    .find('p.displayname')
    .contains(displayName) // Ensure the correct display name is found
    .closest('tr') // Traverse to the parent row
    .find('p.username-provider')
    .invoke('text') // Extract the full username and domain text
    .then((usernameWithDomain) => {
      // Extract username and domain
      const lastIndex = usernameWithDomain.lastIndexOf('@');
      const username = usernameWithDomain.substring(0, lastIndex); // Extract username
      let extractedDomain = usernameWithDomain.substring(lastIndex + 1); // Extract domain

      // Remove protocols (e.g., https:// or http://) from the domain
      extractedDomain = extractedDomain.replace(/^https?:\/\/|^\/\/|www\./, '');

      // Return the contact ID in the format "username@domain"
      return `${username}@${extractedDomain}`;
    });
}

/**
 * Creates a ScienceMesh share for a specific contact and file.
 * @param {string} domain - The domain of the ScienceMesh instance.
 * @param {string} displayName - The display name of the contact.
 * @param {string} contactDomain - The domain of the contact.
 * @param {string} fileName - The name of the file to be shared.
 */
export function createScienceMeshShareV27(domain, displayName, contactDomain, fileName) {
  // Retrieve the contact ID
  getScienceMeshContactIdFromDisplayNameV27(domain, displayName, contactDomain).then((shareWith) => {
    // Navigate to the files app
    cy.visit(`https://${domain}/index.php/apps/files`);

    // Open the sharing panel for the file
    openSharingPanelV27(fileName);

    // Set up an intercept for the user search API request
    cy.intercept('GET', '**/apps/files_sharing/api/v1/sharees?*').as('userSearch');

    cy.get('#app-sidebar-vue').within(() => {
      // Clear the search input and type the contact's display name
      cy.get('#sharing-search-input')
        .clear()
        .type(displayName);
    });

    // Wait for the user search API request to complete
    cy.wait('@userSearch');

    // Select the contact from the search results
    cy.get(`[sharewith="${shareWith}"]`)
      .eq(0) // Ensure the correct match is selected
      .should('be.visible') // Assert visibility
      .click(); // Click to select the contact

    // Click the "Save share" button to finalize the share
    cy.get('div.button-group')
      .contains('Save share')
      .should('be.visible')
      .click();
  });
}

/**
 * Renames a file and waits for the move operation to complete.
 * @param {string} fileName - The current name of the file.
 * @param {string} newFileName - The new name for the file.
 */
export function renameFileV27(fileName, newFileName) {
  // Trigger the "Rename" action from the file's menu
  triggerActionInFileMenuV27(fileName, 'Rename');

  // Intercept the MOVE API request for renaming files
  cy.intercept('MOVE', /\/remote\.php\/dav\/files\//).as('moveFile');

  // Find the file row and enter the new file name
  const fileRow = getRowForFileV27(fileName);
  fileRow.find('form input')
    .clear()
    .type(`${newFileName}{enter}`);

  // Wait for the move operation to complete
  cy.wait('@moveFile');
}

/**
 * Opens the sharing panel for a specific file.
 * @param {string} fileName - The name of the file.
 */
export function openSharingPanelV27(fileName) {
  triggerActionForFileV27(fileName, 'Share');

  // Ensure the sharing tab is visible and click it
  cy.get('#app-sidebar-vue').within(() => {
    cy.get('[aria-controls="tab-sharing"]')
      .should('be.visible')
      .click();
  });
}

/**
 * Toggles the left-side navigation panel based on the provided action.
 * @param {string} actionId - The action to perform (e.g., "Open navigation", "Close navigation").
 * Valid values:
 * - "Open navigation"
 * - "Close navigation"
 */
export function navigationSwitchLeftSideV27(actionId) {
  const validActions = ["Open navigation", "Close navigation"];

  // Validate the actionId
  if (!validActions.includes(actionId)) {
    throw new Error(`Invalid actionId: "${actionId}". Valid options are ${validActions.join(", ")}.`);
  }

  // Find the button for the specified action and click it
  cy.get('div#app-navigation-vue', { timeout: 10000 })
    .find(`button[aria-label="${actionId}"]`)
    .should('be.visible')
    .click();
}

/**
 * Selects an app from the left-side navigation menu.
 * @param {string} appId - The identifier of the app to select.
 * Valid values:
 * - "files"
 * - "recent"
 * - "favorites"
 * - "shareoverview"
 * - "systemtagsfilter"
 * - "trashbin"
 */
export function selectAppFromLeftSideV27(appId) {
  const validAppIds = [
    "files",
    "recent",
    "favorites",
    "shareoverview",
    "systemtagsfilter",
    "trashbin"
  ];

  // Validate the appId
  if (!validAppIds.includes(appId)) {
    throw new Error(`Invalid appId: "${appId}". Valid options are ${validAppIds.join(", ")}.`);
  }

  // Find the app in the navigation menu and click it
  cy.get('div#app-navigation-vue', { timeout: 10000 })
    .find(`li[data-cy-files-navigation-item="${appId}"]`)
    .should('be.visible')
    .click();
}

/**
 * Triggers an action (e.g., rename, details) in a file's menu.
 * @param {string} filename - The name of the file.
 * @param {string} actionId - The action to trigger.
 */
export function triggerActionInFileMenuV27(fileName, actionId) {
  // Open the file's action menu
  triggerActionForFileV27(fileName, 'menu');

  // Find the specific action within the menu and click it
  getRowForFileV27(fileName)
    .find(`*[data-action="${actionId}"]`)
    .should('be.visible')
    .as('btn')
    .click();
}

/**
 * Triggers an action for a specific file.
 * @param {string} fileName - The name of the file.
 * @param {string} actionId - The action to trigger.
 */
export function triggerActionForFileV27(fileName, actionId) {
  // Find the actions container for the file
  getActionsForFileV27(fileName)
    .find(`*[data-action="${actionId}"]`)
    .should('be.visible')
    .as('btn')
    .click();
}

/**
 * Retrieves the actions container for a specific file.
 * @param {string} fileName - The name of the file.
 * @returns {Cypress.Chainable<JQuery<HTMLElement>>} - The actions container element.
 */
export function getActionsForFileV27(fileName) {
  return getRowForFileV27(fileName).find('.fileactions');
}

/**
 * Retrieves the row element for a specific file.
 * @param {string} fileName - The name of the file.
 * @returns {Cypress.Chainable<JQuery<HTMLElement>>} - The file row element.
 */
export function getRowForFileV27(fileName) {
  return cy.get(`[data-file="${fileName}"]`);
}
