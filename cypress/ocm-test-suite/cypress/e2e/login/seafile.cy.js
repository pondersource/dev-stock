/**
 * @fileoverview
 * Cypress test suite for testing the login functionality of Seafile.
 * This suite contains tests to validate successful login functionality using valid credentials.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

describe('Seafile Login Tests', () => {
  /**
   * Test Case: Validates successful login to Seafile.
   * This test logs into Seafile using valid credentials and checks for a successful login state.
   */
  it('should successfully log into Seafile with valid credentials', () => {
    // Define the Seafile instance URL and credentials from environment variables or use default values
    const seafileUrl = Cypress.env('SEAFILE1_URL') || 'https://seafile1.docker';
    const username = Cypress.env('SEAFILE1_USERNAME') || 'jonathan@seafile.com';
    const password = Cypress.env('SEAFILE1_PASSWORD') || 'xu';

    cy.loginOcis(seafileUrl, username, password);
  });
});
