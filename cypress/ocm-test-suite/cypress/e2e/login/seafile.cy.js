/**
 * @fileoverview
 * Cypress test suite for testing the login functionality of Seafile.
 * This suite contains tests to validate successful login functionality using valid credentials.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  getUtils
} from '../utils/index.js';

describe('Seafile Login Tests', () => {
  /**
   * Test Case: Validates successful login to Seafile.
   * This test logs into Seafile using valid credentials and checks for a successful login state.
   */
  it('should successfully log into Seafile with valid credentials', () => {
    // Define the Seafile instance URL and credentials from environment variables or use default values
    const platform = Cypress.env('EFSS_PLATFORM_1') ?? 'seafile';
    const paltformVersion = Cypress.env('EFSS_PLATFORM_1_VERSION') ?? 'v11';
    const url = Cypress.env('SEAFILE1_URL') || 'http://seafile1.docker';
    const username = Cypress.env('SEAFILE1_USERNAME') || 'jonathan@seafile.com';
    const password = Cypress.env('SEAFILE1_PASSWORD') || 'xu';

    // Get the right helper set
    const platformUtils = getUtils(platform, paltformVersion);

    platformUtils.login({ url, username, password });
  });
});
