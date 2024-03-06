/// <reference types="cypress" />

describe('Native federated sharing functionality', () => {
  it('Accept federated share from Nextcoud to ownCloud', () => {
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

		cy.visit('https://nextcloud1.docker/index.php/apps/files/')

		cy.get('table').find('tbody').find('tr[data-cy-files-list-row-name="welcome.txt"]').within(
			() => {
				cy.get('*[class^="files-list__row-actions files-list__row-actions"]').within(
					() => {
						cy.get('button').click()
					}
				)
			}
		)

		cy.get('table')
		.find('div[id^="popper_"]')
		.find('div[class="v-popper__wrapper"]')
		.find('div[class="v-popper__inner"]')
		.find('div')
		.find('div[class="open"]')
		.find('ul[id^="menu-"]')
		.find('li[class="action files-list__row-action-details"]').within(
			() => {
				cy.get('button').click()
			}
		)
  })
})
