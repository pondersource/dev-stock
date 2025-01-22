/**
 * Cypress custom commands for logging into various platforms.
 */

/**
 * Login to Nextcloud Core.
 * Logs into Nextcloud using provided credentials, ensuring the login page is visible before interacting with it.
 *
 * @param {string} url - The URL of the Nextcloud instance.
 * @param {string} username - The username for login.
 * @param {string} password - The password for login.
 */
Cypress.Commands.add('loginNextcloudCore', (url, username, password) => {
  cy.visit(url);

  // Ensure the login page is visible
  cy.get('form[name="login"]', { timeout: 10000 }).should('be.visible');

  // Fill in login credentials and submit
  cy.get('form[name="login"]').within(() => {
    cy.get('input[name="user"]').type(username);
    cy.get('input[name="password"]').type(password);
    cy.contains('button[data-login-form-submit]', 'Log in').click();
  });
});

/**
 * Login to Nextcloud and navigate to the files app.
 * Extends the core login functionality by verifying the dashboard and navigating to the files app.
 *
 * @param {string} url - The URL of the Nextcloud instance.
 * @param {string} username - The username for login.
 * @param {string} password - The password for login.
 */
Cypress.Commands.add('loginNextcloud', (url, username, password) => {
  cy.loginNextcloudCore(url, username, password);

  // Verify dashboard visibility
  cy.url({ timeout: 10000 }).should('match', /apps\/dashboard(\/|$)/);

  // Navigate to the files app
  cy.get('header[id="header"] nav.app-menu ul.app-menu-main li[data-app-id="files"]')
    .should('be.visible')
    .click();

  // Verify files app visibility
  cy.url({ timeout: 10000 }).should('match', /apps\/files(\/|$)/);
});

/**
 * Login to Seafile.
 * Logs into Seafile using provided credentials.
 *
 * @param {string} url - The URL of the Seafile instance.
 * @param {string} username - The username for login.
 * @param {string} password - The password for login.
 */
Cypress.Commands.add('loginSeafile', (url, username, password) => {
  cy.visit(url);

  // Fill in login credentials and submit
  cy.get('input[name="login"]').type(username);
  cy.get('input[name="password"]').type(password);
  cy.get('button[type="submit"]').click();
});

/**
 * Login to ownCloud Core.
 * Logs into ownCloud using provided credentials.
 *
 * @param {string} url - The URL of the ownCloud instance.
 * @param {string} username - The username for login.
 * @param {string} password - The password for login.
 */
Cypress.Commands.add('loginOwncloudCore', (url, username, password) => {
  cy.visit(url);

  // Ensure the login page is visible
  cy.get('form[name="login"]', { timeout: 10000 }).should('be.visible');

  // Fill in login credentials and submit
  cy.get('form[name="login"]').within(() => {
    cy.get('input[name="user"]').type(username);
    cy.get('input[name="password"]').type(password);
    cy.get('button[id="submit"]').click();
  });
});

/**
 * Login to ownCloud and navigate to the files app.
 * Extends the core login functionality by verifying the files app is accessible.
 *
 * @param {string} url - The URL of the ownCloud instance.
 * @param {string} username - The username for login.
 * @param {string} password - The password for login.
 */
Cypress.Commands.add('loginOwncloud', (url, username, password) => {
  cy.loginOwncloudCore(url, username, password);

  // Verify files app visibility
  cy.url({ timeout: 10000 }).should('match', /apps\/files(\/|$)/);
});

/**
 * Login to OCIS Core.
 * Logs into OCIS using provided credentials.
 *
 * @param {string} url - The URL of the OCIS instance.
 * @param {string} username - The username for login.
 * @param {string} password - The password for login.
 */
Cypress.Commands.add('loginOcisCore', (url, username, password) => {
  cy.visit(url);

  // Ensure the login page is visible
  cy.get('form.oc-login-form', { timeout: 10000 }).should('be.visible');

  // Fill in login credentials and submit
  cy.get('form.oc-login-form').within(() => {
    cy.get('input#oc-login-username').type(username);
    cy.get('input#oc-login-password').type(password);
    cy.get('button[type="submit"]').click();
  });
});

/**
 * Login to OCIS and navigate to the personal files app.
 * Extends the core login functionality by verifying the personal files app is accessible.
 *
 * @param {string} url - The URL of the OCIS instance.
 * @param {string} username - The username for login.
 * @param {string} password - The password for login.
 */
Cypress.Commands.add('loginOcis', (url, username, password) => {
  cy.loginOcisCore(url, username, password);

  // Verify personal files app visibility
  cy.url({ timeout: 10000 }).should('match', /files\/spaces\/personal(\/|$)/);
});

/**
 * Login to OCM Stub.
 * Navigates to the OCM Stub login page and logs in using a default flow.
 *
 * @param {string} url - The URL of the OCM Stub instance.
 */
Cypress.Commands.add('loginOcmStub', (url) => {
  cy.visit(`${url}/?`);

  // Ensure the login button is visible
  cy.get('input[value="Log in"]', { timeout: 10000 }).should('be.visible');

  // Perform login by clicking the button
  cy.get('input[value="Log in"]').click();

  // Verify session activation
  cy.url({ timeout: 10000 }).should('match', /\/?session=active/);
});
