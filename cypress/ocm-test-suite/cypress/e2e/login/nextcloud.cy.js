describe('Login Nextcloud', () => {
  it('Login test for Nextcloud', () => {
		cy.loginNextcloud('https://nextcloud1.docker', 'einstein', 'relativity')
  })
})
