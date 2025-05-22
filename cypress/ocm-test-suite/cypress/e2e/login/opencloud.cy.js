/**
 * @fileoverview
 * Cypress test suite for testing the login functionality of Opencloud.
 * This suite contains tests to validate successful login functionality using valid credentials.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

import {
  getUtils
} from '../utils/index.js';

describe('Opencloud Login Tests', () => {
  /**
   * Test Case: Validates successful login to Opencloud.
   * This test logs into Opencloud using valid credentials and checks for a successful login state.
   */
  it('should successfully log into Opencloud with valid credentials', () => {
    // Define the Opencloud instance URL and credentials from environment variables or use default values
    const platform = Cypress.env('EFSS_PLATFORM_1') ?? 'opencloud';
    const paltformVersion = Cypress.env('EFSS_PLATFORM_1_VERSION') ?? 'v2';
    const url = Cypress.env('OPENCLOUD1_URL') || 'https://opencloud1.docker';
    const username = Cypress.env('OPENCLOUD1_USERNAME') || 'alan';
    const password = Cypress.env('OPENCLOUD1_PASSWORD') || 'demo';

    // Get the right helper set
    const platformUtils = getUtils(platform, paltformVersion);

    platformUtils.login({ url, username, password });
  });
});
