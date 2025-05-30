/**
 * @fileoverview
 * Cypress test suite for testing the login functionality of Nextcloud.
 * This suite contains tests to validate successful login functionality using valid credentials.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  getUtils
} from '../utils/index.js';

describe('Nextcloud Login Tests', () => {
  /**
   * Test Case: Validates successful login to Nextcloud.
   * This test logs into Nextcloud using valid credentials and checks for a successful login state.
   */
  it('should successfully log into Nextcloud with valid credentials', () => {
    // Define the Nextcloud instance URL and credentials from environment variables or use default values
    const platform = Cypress.env('EFSS_PLATFORM_1') ?? 'nextcloud';
    const paltformVersion = Cypress.env('EFSS_PLATFORM_1_VERSION') ?? 'v27';
    const url = Cypress.env('NEXTCLOUD1_URL') || 'https://nextcloud1.docker';
    const username = Cypress.env('NEXTCLOUD1_USERNAME') || 'einstein';
    const password = Cypress.env('NEXTCLOUD1_PASSWORD') || 'relativity';

    // Get the right helper set
    const platformUtils = getUtils(platform, paltformVersion);

    platformUtils.login({ url, username, password });
  });
});
