/**
 * @fileoverview
 * Utility functions for Cypress tests interacting with Seafile version 11.
 * These functions provide abstractions for common actions such as accepting shares,
 * creating federated shares, renaming files, and interacting with the file menu.
 *
 * @author Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
 */

// Utility function to dismiss a modal if it appears
export function dismissModalIfPresentV11() {
  // No waiting; check immediately
  cy.get('[role="dialog"]', { timeout: 5000 })
    .then((modals) => {
      if (modals.length > 0) {
        // If modal exists, close it
        cy.wrap(modals)
          .find('.modal-dialog .modal-content .modal-body button')
          .should('be.visible')
          .click();
      }
    });
}
