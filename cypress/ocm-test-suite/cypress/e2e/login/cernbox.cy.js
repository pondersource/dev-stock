/**
 * @fileoverview
 * Cypress test suite for testing the login functionality of CERNBox.
 * This suite contains tests to validate successful login functionality using valid credentials.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  getUtils
} from '../utils/index.js';

describe('CERNBox Login Tests', () => {
  /**
   * Test Case: Validates successful login to CERNBox.
   * This test logs into CERNBox using valid credentials and checks for a successful login state.
   */
  it('should successfully log into CERNBox with valid credentials', () => {
    // Define the CERNBox instance URL and credentials from environment variables or use default values
    const platform = Cypress.env('EFSS_PLATFORM_1') ?? 'cernbox';
    const paltformVersion = Cypress.env('EFSS_PLATFORM_1_VERSION') ?? 'v1';
    const url = Cypress.env('CERNBOX1_URL') || 'https://cernbox1.docker';
    const username = Cypress.env('CERNBOX1_USERNAME') || 'einstein';
    const password = Cypress.env('CERNBOX1_PASSWORD') || 'relativity';

    // Get the right helper set
    const platformUtils = getUtils(platform, paltformVersion);

    platformUtils.login({ url, username, password });
  });
});
