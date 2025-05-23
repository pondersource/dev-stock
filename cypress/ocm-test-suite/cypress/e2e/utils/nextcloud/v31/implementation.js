/**
 * @fileoverview
 * Utility functions for Cypress tests interacting with Nextcloud version 30.
 * These functions provide abstractions for common actions such as sharing files,
 * updating permissions, renaming files, and navigating the UI.
 *
 * @author Michiel B. de Jong <michiel@pondersource.com>
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  escapeCssSelector,
} from '../../general.js';

/**
 * Login to Nextcloud Core.
 * Logs into Nextcloud using provided credentials, ensuring the login page is visible before interacting with it.
 *
 * @param {string} url - The URL of the Nextcloud instance.
 * @param {string} username - The username for login.
 * @param {string} password - The password for login.
 */
export function loginCore({ url, username, password }) {
  cy.visit(url);

  // Ensure the login page is visible
  cy.get('form[name="login"]', { timeout: 10000 }).should('be.visible');

  // Fill in login credentials and submit
  cy.get('form[name="login"]').within(() => {
    cy.get('input[name="user"]').type(username);
    cy.get('input[name="password"]').type(password);
    cy.contains('button[data-login-form-submit]', 'Log in').click();
  });
};

/**
 * Recursively look for a file-row, reloading the view between attempts.
 *
 * @param {string} name      The file name to locate.
 * @param {number} timeout   Final visible-check timeout (ms). Default 20 000.
 * @param {number} depth     Current recursion depth — do not set manually.
 * @param {number} maxDepth  Maximum reload attempts. Default 3.
 * @param {number} waitMs    Delay between attempts (ms). Default 500.
 *
 * @example
 * ensureFileExists('report.pdf');                // default behaviour
 * ensureFileExists('report.pdf', 30000, 0, 5);   // try 5 times, 30 s final wait
 */
export function ensureFileExists(
  name,
  timeout = 20000,
  depth = 0,
  maxDepth = 3,
  waitMs = 500
) {
  cy.wait(waitMs);

  const escaped = escapeCssSelector(name);

  return cy.get('body').then(($body) => {
    if ($body.find(`[data-cy-files-list-row-name="${escaped}"]`).length) {
      return cy
        .get(`[data-cy-files-list-row-name="${escaped}"]`, { timeout })
        .should('be.visible');
    }
    if (depth >= maxDepth) {
      throw new Error(
        `File "${name}" not found after ${maxDepth} reload attempts`
      );
    }

    // Reload, and recurse
    cy.reload(true);
    return ensureFileExists(name, timeout, depth + 1, maxDepth, waitMs);
  });
}

/**
 * Accepts a share dialog by clicking the "primary" button.
 */
export function acceptShare() {
  // Wait for the share dialog to appear and ensure it's visible
  cy.get('div.dialog__modal', { timeout: 10000 })
    .should('be.visible')
    .within(() => {
      // Locate the button row and click the primary button
      cy.get('div.dialog__actions')
        .find('button')
        .contains('Add remote share')
        .should('exist')
        .click({ force: true });
    });
}

/**
 * Creates and sends a federated share link to a recipient.
 * This function creates a share link for a file and sends it to a specified recipient.
 * 
 * @param {string} fileName - The name of the file to share.
 * @param {string} recipientUsername - The username of the recipient.
 * @param {string} recipientDomain - The domain of the recipient (without protocol).
 * @returns {Cypress.Chainable} - A chainable Cypress command.
 */
export function createAndSendShareLink(fileName, recipientUsername, recipientDomain) {
  return createShareLink(fileName).then((shareLink) => {
    cy.visit(shareLink);

    // Open the new header menu (three dots)
    getHeader()
      .find('button.header-menu__trigger[aria-controls="header-menu-public-page-menu"]')
      .click();

    // Pick (Add to your Nextcloud)
    cy.get('a#save--link').click({ force: true });

    // Enter the federated address and confirm
    cy.get('[role="dialog"].dialog__modal')
      .should('be.visible')
      .within(() => {
        cy.get('input[placeholder="user@your-nextcloud.org"]')
          .clear()
          .type(`${recipientUsername}@${recipientDomain}`);
        cy.contains('button', 'Create share').click();
      });
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
export function handleShareAcceptance(fileName, timeout = 10000, appId = 'files', depth = 0, maxDepth = 5) {
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
    const hasDialog = $body.find('div.dialog__modal:visible').length > 0;

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
        handleShareAcceptance(fileName, timeout, appId, depth + 1, maxDepth);
      });
    } else {
      // No more pop-ups, wait for the file list to be loaded
      cy.wait(1000);

      // Reload
      cy.reload(true).then(() => {
        // Wait for page load after reload
        cy.wait(500);
        // Verify the shared file exists with specified timeout
        ensureFileExists(fileName, timeout);
      });
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

  cy.get('#app-sidebar-vue').within(() => {
    // Clear the input field and type the recipient's email
    cy.get('h4').contains('External shares')
      .parents('section')
      .first()
      .find('.sharing-search__input input.vs__search')
      .clear()
      .type(`${username}@${domain}{enter}`);
  });

  // Wait for the user search API request to complete
  cy.wait('@userSearch');

  // Select the correct user from the search results
  cy.get(`[user="${username}"]`)
    .should('be.visible')
    .click();

  cy.get('#app-sidebar-vue').within(() => {
    // Click the "Save share" button to finalize the share
    cy.get('div.sharingTabDetailsView__footer button[data-cy-files-sharing-share-editor-action="save"]')
      .should('be.visible')
      .click({ scrollBehavior: 'nearest' });
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
 * Updates sharing permissions for a specific share.
 * @param {string} fileName - The name of the shared file.
 * @param {number} index - The index of the share to update (0-based).
 */
export function updateShare(fileName, index) {
  // Open the sharing panel for the specified file
  openSharingPanel(fileName);

  cy.get('#app-sidebar-vue').within(() => {
    // Open the actions menu for the specified share
    cy.get('[data-cy-files-sharing-share-actions]')
      .eq(index)
      .should('be.visible')
      .click();

    // Select custom permissions
    cy.get('[data-cy-files-sharing-share-permissions-bundle="custom"]')
      .should('be.visible')
      .click();

    // Update each permission checkbox
    ['download', 'read', 'update', 'delete'].forEach((permission) => {
      cy.get(`[data-cy-files-sharing-share-permissions-checkbox="${permission}"] input`)
        .check({ force: true, scrollBehavior: 'nearest' });
    });

    // Save the changes
    cy.get('button[data-cy-files-sharing-share-editor-action="save"]')
      .should('be.visible')
      .click({ scrollBehavior: 'nearest' });
  });
}

/**
 * Renames a file and waits for the move operation to complete.
 * @param {string} fileName - The current name of the file.
 * @param {string} newFileName - The new name for the file.
 */
export function renameFile(fileName, newFileName) {
  // Trigger the "Rename" action from the file's menu
  triggerActionForFile(fileName, 'rename');

  // Intercept the MOVE API request for renaming files
  cy.intercept('MOVE', '**/remote.php/dav/files/**').as('moveFile');

  // Find the file row and enter the new file name
  const fileRow = getRowForFile(fileName);
  fileRow.find('[data-cy-files-list-row-name] input')
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
  // Trigger the "Details" action to open the sidebar
  triggerActionForFile(fileName, 'details');

  // Ensure the sharing tab is visible and click it
  cy.get('#app-sidebar-vue').within(() => {
    cy.get('[aria-controls="tab-sharing"]')
      .should('be.visible')
      .click();
  });
}

/**
 * Click an app in the header.
 * @param {string} label
 */
export function openApp(label) {
  appEntry(label)
    .find('a.app-menu-entry__link')
    .click();
}

/**
 * Locate an individual app entry by its visible label.
 * @param {string} label ‒ e.g. 'Dashboard', 'Files'
 */
function appEntry(label) {
  return appMenu()
    .contains('li.app-menu-entry', label.trim());
}

function appMenu() {
  return getHeader().find('nav.app-menu');
}

function getHeader() {
  return cy.get('#header');
}

/**
 * Triggers an action for a specific file.
 * @param {string} filename - The name of the file.
 * @param {string} actionId - The action to trigger (e.g., 'rename', 'details').
 */
export function triggerActionForFile(filename, actionId) {
  // Open the file's action menu
  getActionButtonForFile(filename)
    .should('be.visible')
    .click({ force: true });

  // Construct the selector for the desired action
  const actionSelector = `[data-cy-files-list-row-action="${actionId}"] > button`;

  // Click the action button
  cy.get(actionSelector)
    .should('exist')
    .should('be.visible')
    .click({ force: true });
}

/**
 * Retrieves the action button for a specific file.
 * @param {string} filename - The name of the file.
 * @returns {Cypress.Chainable<JQuery<HTMLElement>>} - The action button element.
 */
export function getActionButtonForFile(filename) {
  return getActionsForFile(filename)
    .find('button[aria-label="Actions"]')
    .should('be.visible');
}

/**
 * Retrieves the actions container for a specific file.
 * @param {string} filename - The name of the file.
 * @returns {Cypress.Chainable<JQuery<HTMLElement>>} - The actions container element.
 */
export function getActionsForFile(filename) {
  return getRowForFile(filename)
    .find('[data-cy-files-list-row-actions]');
}

/**
 * Retrieves the row element for a specific file.
 * @param {string} filename - The name of the file.
 * @returns {Cypress.Chainable<JQuery<HTMLElement>>} - The file row element.
 */
export function getRowForFile(filename) {
  return cy.get(`[data-cy-files-list-row-name="${filename}"]`);
}
