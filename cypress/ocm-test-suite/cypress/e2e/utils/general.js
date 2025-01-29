/**
 * @fileoverview
 * Utility functions for Cypress tests.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

/**
 * Escapes special characters in a string to be used in a CSS selector.
 * This is necessary because file names may contain characters that have special meanings in CSS selectors.
 *
 * @param {string} selector - The string to escape.
 * @returns {string} - The escaped string safe for use in a CSS selector.
 */
export function escapeCssSelector(selector) {
    // Replace any character that is a CSS selector special character with its escaped version
    return selector.replace(/([ !"#$%&'()*+,.\/:;<=>?@[\\\]^`{|}~])/g, '\\$1');
}
