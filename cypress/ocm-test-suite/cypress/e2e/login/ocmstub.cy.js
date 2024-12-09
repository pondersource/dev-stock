/**
 * @fileoverview
 * Cypress test suite for testing the login functionality of OcmStub.
 * This suite contains tests to validate successful login functionality using valid credentials.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

describe('OcmStub Login Tests', () => {
  /**
   * Test Case: Validates successful login to OcmStub.
   * This test logs into OcmStub using valid credentials and checks for a successful login state.
   */
  it('should successfully log into OcmStub with valid credentials', () => {
    // Define the OcmStub instance URL and credentials from environment variables or use default values
    const ocmstubUrl = Cypress.env('OCMSTUB1_URL') || 'https://ocmstub1.docker';
    const username = Cypress.env('OCMSTUB1_USERNAME') || 'einstein';
    const password = Cypress.env('OCMSTUB1_PASSWORD') || 'relativity';

    cy.loginOcmStub('https://ocmstub1.docker/?');
  });
});
