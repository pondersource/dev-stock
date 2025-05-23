/**
 * @fileoverview
 * Cypress test suite for testing the login functionality of oCIS.
 * This suite contains tests to validate successful login functionality using valid credentials.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  getUtils
} from '../utils/index.js';

describe('oCIS Login Tests', () => {
  /**
   * Test Case: Validates successful login to oCIS.
   * This test logs into oCIS using valid credentials and checks for a successful login state.
   */
  it('should successfully log into oCIS with valid credentials', () => {
    // Define the oCIS instance URL and credentials from environment variables or use default values
    const platform = Cypress.env('EFSS_PLATFORM_1') ?? 'ocis';
    const paltformVersion = Cypress.env('EFSS_PLATFORM_1_VERSION') ?? 'v5';
    const url = Cypress.env('OCIS1_URL') || 'https://ocis1.docker';
    const username = Cypress.env('OCIS1_USERNAME') || 'einstein';
    const password = Cypress.env('OCIS1_PASSWORD') || 'relativity';

    // Get the right helper set
    const platformUtils = getUtils(platform, paltformVersion);

    platformUtils.login({ url, username, password });
  });
});
