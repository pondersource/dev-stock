/// <reference types="cypress" />

describe('Login ownCloud', () => {
  it('Login test for ownCloud', () => {
    	// Given I visit the Home page
		cy.visit('https://owncloud1.docker')

		// I see the login page
		cy.get('form[name="login"]').should('be.visible')

		// I log in with a valid user
		cy.get('form[name="login"]').within(() => {
			cy.get('input[name="user"]').type('marie')
			cy.get('input[name="password"]').type('radioactivity')
			cy.get('button[id="submit"]').click()
		})

		// Then I see that the current page is the Files app
		cy.url().should('match', /apps\/files(\/|$)/)
  })
})
