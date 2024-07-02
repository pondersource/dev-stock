// Import commands.js using ES2015 syntax:
import './commands'

const resizeObserverLoopErrRe = /^[^(ResizeObserver loop limit exceeded)]/
Cypress.on('uncaught:exception', (err) => {
    /* returning false here prevents Cypress from failing the test */
    if (resizeObserverLoopErrRe.test(err.message)) {
        return false
    }
})

// code we only want run per test, so it shouldn't be run as part of
// the execution of cy.origin() as well
beforeEach(() => {
// ... code to run before each test ...
})
