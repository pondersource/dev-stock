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

/**
 * Constructs a federated share URL based on the platform and provided parameters.
 * This function handles the URL construction for different platforms (Nextcloud, ownCloud).
 * 
 * @param {Object} params - The parameters needed to construct the URL
 * @param {string} params.shareUrl - The original share URL to extract token from
 * @param {string} params.senderUrl - The URL of the sender's instance
 * @param {string} params.recipientUrl - The URL of the recipient's instance
 * @param {string} params.senderUsername - The username of the sender
 * @param {string} params.fileName - The name of the shared file
 * @param {string} params.platform - The platform type ('nextcloud' or 'owncloud')
 * @returns {string} The constructed federated share URL
 */
export function constructFederatedShareUrl(params) {
  const {
    shareUrl,
    senderUrl,
    recipientUrl,
    senderUsername,
    fileName,
    platform
  } = params;

  // Extract token from the share URL
  const token = shareUrl.replace(`${senderUrl}/s/`, '');

  // Clean up URLs by ensuring they use https and removing trailing slashes
  const cleanSenderUrl = senderUrl.replace(/^https?:\/\//, 'https://').replace(/\/$/, '');
  const cleanRecipientUrl = recipientUrl.replace(/^https?:\/\//, 'https://').replace(/\/$/, '');

  // Construct the URL based on the platform
  if (platform === 'owncloud') {
    return `${cleanRecipientUrl}/index.php/apps/files#remote=${cleanSenderUrl}&token=${token}&owner=${senderUsername}&ownerDisplayName=${senderUsername}&name=${fileName}&protected=0`;
  } else if (platform === 'nextcloud') {
    return `${cleanRecipientUrl}/index.php/login?redirect_url=%252Findex.php%252Fapps%252Ffiles#remote=${cleanSenderUrl}&token=${token}&owner=${senderUsername}&ownerDisplayName=${senderUsername}&name=${fileName}&protected=0`;
  } else {
    throw new Error(`Unsupported platform: ${platform}`);
  }
}
