/// <reference types="cypress" />

describe('Login Nextcloud', () => {
  it('Login test for Nextcloud', () => {
    	// Given I visit the Home page
		cy.visit('https://nextcloud1.docker')

		// I see the login page
		cy.get('form[name="login"]').should('be.visible')

		// I log in with a valid user
		cy.get('form[name="login"]').within(() => {
			cy.get('input[name="user"]').type('einstein')
			cy.get('input[name="password"]').type('relativity')
			cy.contains('button[data-login-form-submit]', 'Log in').click()
		})

		// Then I see that the current page is the Files app
		cy.url().should('match', /apps\/dashboard(\/|$)/)
  })
})
