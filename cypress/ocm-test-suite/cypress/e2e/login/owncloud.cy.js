/**
 * @fileoverview
 * Cypress test suite for testing the login functionality of ownCloud.
 * This suite contains tests to validate successful login functionality using valid credentials.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

describe('ownCloud Login Tests', () => {
  /**
   * Test Case: Validates successful login to ownCloud.
   * This test logs into ownCloud using valid credentials and checks for a successful login state.
   */
  it('should successfully log into ownCloud with valid credentials', () => {
    // Define the ownCloud instance URL and credentials from environment variables or use default values
    const paltformVersion     = Cypress.env('EFSS_PLATFORM_1_VERSION') ?? 'v10';
    const owncloudUrl = Cypress.env('OWNCLOUD1_URL') || 'https://owncloud1.docker';
    const username = Cypress.env('OWNCLOUD1_USERNAME') || 'einstein';
    const password = Cypress.env('OWNCLOUD1_PASSWORD') || 'relativity';

    cy.loginOwncloud(owncloudUrl, username, password);
  });
});
