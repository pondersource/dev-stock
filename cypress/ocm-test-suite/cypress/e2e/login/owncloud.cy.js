describe('Login ownCloud', () => {
  it('Login test for ownCloud', () => {
		cy.loginOwncloud('https://owncloud1.docker', 'marie', 'radioactivity')
  })
})
