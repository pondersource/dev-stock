/**
 * @fileoverview
 * Utility functions for Cypress tests interacting with OcmStub version 1.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */


/**
 * Generates an array of share assertions for validation on a page.
 * This function helps validate that the expected share metadata is displayed correctly in the UI.
 *
 * @param {Object} expectedDetails - An object containing the expected share details.
 * @param {string} expectedDetails.shareWith - The recipient of the share (e.g., "marie@ocmstub2.docker").
 * @param {string} expectedDetails.fileName - The name of the shared file (e.g., "example-file.txt").
 * @param {string} expectedDetails.shareType - The type of share (e.g., "user" or "group").
 * @param {string} expectedDetails.owner - The owner of the shared resource (e.g., "einstein@nextcloud.com").
 * @param {string} expectedDetails.sender - The sender of the shared resource (e.g., "einstein@nextcloud.com").
 * @param {string} expectedDetails.resourceType - The type of the shared resource ("file", "folder", etc.).
 * @param {string} expectedDetails.protocol - The protocol used for the share (e.g., "webdav").
 * @param {boolean} isNextcloud - Whether the instance being checked is nectcloud or not.
 * @returns {string[]} - An array of strings representing expected lines of text that should appear in the UI.
 *
 * @throws {Error} Throws an error if any required field in expectedDetails is missing or not a string.
 *
 * @example
 * // Define the expected details of a federated share
 * const expectedDetails = {
 *   shareWith: 'marie@ocmstub2.docker',
 *   fileName: 'example-file.txt',
 *   owner: 'einstein@nextcloud.com',
 *   sender: 'einstein@nextcloud.com',
 *   shareType: 'user',
 *   resourceType: 'file',
 *   protocol: 'webdav',
 * };
 *
 * // Generate the share assertions
 * const shareAssertions = generateShareAssertions(expectedDetails, true);
 * // The returned array can then be used with `cy.contains()` calls in Cypress tests:
 * // shareAssertions.forEach(assertion => cy.contains(assertion).should('be.visible'));
 */
export function generateShareAssertions(expectedDetails, isNextcloud = false) {
  // Required fields that must be present and non-empty strings
  const requiredFields = [
    'shareWith',
    'fileName',
    'owner',
    'sender',
    'shareType',
    'resourceType',
    'protocol',
  ];

  // Identify any fields that are missing or invalid
  const missingFields = requiredFields.filter((field) => {
    return !expectedDetails[field] || typeof expectedDetails[field] !== 'string';
  });

  // If there are any missing or invalid fields, throw an error
  if (missingFields.length > 0) {
    throw new Error(
      `Missing or invalid fields in expectedDetails: ${missingFields.join(', ')}`
    );
  }

  // Return an array of expected strings to match in the UI.
  // Note: Some values (like providerId and protocol options) are partially asserted
  // because their exact values may vary dynamically. We assert on the known portion of the string.
  return [
    `"shareWith": "${expectedDetails.shareWith}"`,
    `"name": "${expectedDetails.fileName}"`,
    // Partial assertion, expecting a providerId line to appear
    `"providerId":`,
    `"shareType": "${expectedDetails.shareType}"`,
    `"owner": "${expectedDetails.owner}"`,
    // Nextcloud is not following OCM specification at this moment, see: https://github.com/nextcloud/server/issues/36340#issuecomment-2575333222
    // this should be fixed via https://github.com/nextcloud/server/pull/50069
    // TODO @MahdiBaghbani: rename this to isLegacyNextcloud once the PR is merged and available in a new Nextcloud release.
    (isNextcloud? `"sharedBy": "${expectedDetails.sender}"` : `"sender": "${expectedDetails.sender}"`),
    `"resourceType": "${expectedDetails.resourceType}"`,
    // For protocol, we know 'name' but 'sharedSecret' may vary.
    // We assert on part of the structure to ensure the protocol block is present.
    `"protocol": { "name": "${expectedDetails.protocol}", "options": { "sharedSecret": "`,
  ];
}
