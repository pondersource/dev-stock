/**
 * @fileoverview
 * Utility functions for Cypress tests interacting with Nextcloud version 27.
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
    if ($body.find(`[data-file="${escaped}"]`).length) {
      return cy
        .get(`[data-file="${escaped}"]`, { timeout })
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
        handleShareAcceptance(fileName, timeout, appId, depth + 1, maxDepth);
      });
    } else {
      // No more pop-ups, wait for the file list to be loaded
      cy.wait(1000);

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

    // Open the header actions menu and click save external share
    cy.get('button[id="header-actions-toggle"]').click();
    cy.get('button[id="save-external-share"]').click();

    // Fill in the recipient's address and save
    cy.get('form[class="save-form"]').within(() => {
      cy.get('input[id="remote_address"]').type(`${recipientUsername}@${recipientDomain}`);
      cy.get('input[id="save-button-confirm"]').click();
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
  cy.visit(`https://${domain}/index.php/apps/sciencemesh/contacts`);

  cy.get('table#contact-table')
    .find('p.displayname', { timeout: 10000 })
    .contains(displayName) // Ensure the display name is present
    .closest('tr') // Traverse to the parent row
    .find('p.username-provider')
    .invoke('text') // Extract the username and domain text
    .then((usernameWithDomain) => {
      const extractedDomain = usernameWithDomain.split('@').pop(); // Extract domain after '@'
      expect(extractedDomain.replace(/^https?:\/\/|\/$/g, '')).to.equal(contactDomain); // Assert the domain matches
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
export function getScienceMeshContactIdFromDisplayName(domain, displayName, contactDomain) {
  // Verify that the contact exists in the table
  verifyFederatedContact(domain, displayName, contactDomain);

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
export function createScienceMeshShare(domain, displayName, contactDomain, fileName) {
  // Retrieve the contact ID
  getScienceMeshContactIdFromDisplayName(domain, displayName, contactDomain).then((shareWith) => {
    // Navigate to the files app
    cy.visit(`https://${domain}/index.php/apps/files`);

    // Open the sharing panel for the file
    openSharingPanel(fileName);

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
export function renameFile(fileName, newFileName) {
  // Trigger the "Rename" action from the file's menu
  triggerActionInFileMenu(fileName, 'Rename');

  // Intercept the MOVE API request for renaming files
  cy.intercept('MOVE', /\/remote\.php\/dav\/files\//).as('moveFile');

  // Find the file row and enter the new file name
  const fileRow = getRowForFile(fileName);
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
export function openSharingPanel(fileName) {
  triggerActionForFile(fileName, 'Share');

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
export function navigationSwitchLeftSide(actionId) {
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
export function selectAppFromLeftSide(appId) {
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
export function triggerActionInFileMenu(fileName, actionId) {
  // Open the file's action menu
  triggerActionForFile(fileName, 'menu');

  // Find the specific action within the menu and click it
  getRowForFile(fileName)
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
export function triggerActionForFile(fileName, actionId) {
  // Find the actions container for the file and ensure it's stable
  getActionsForFile(fileName)
    .should('exist')
    .and('be.visible')
    .within(() => {
      // Find the action button and ensure it's properly loaded
      cy.get(`*[data-action="${actionId}"]`)
        .should('exist')
        .and('be.visible')
        .and('not.be.disabled')
        .click({ force: true });
    });
}

/**
 * Retrieves the actions container for a specific file.
 * @param {string} fileName - The name of the file.
 * @returns {Cypress.Chainable<JQuery<HTMLElement>>} - The actions container element.
 */
export function getActionsForFile(fileName) {
  return getRowForFile(fileName).find('.fileactions');
}

/**
 * Retrieves the row element for a specific file.
 * @param {string} fileName - The name of the file.
 * @returns {Cypress.Chainable<JQuery<HTMLElement>>} - The file row element.
 */
export function getRowForFile(fileName) {
  return cy.get(`[data-file="${fileName}"]`);
}
