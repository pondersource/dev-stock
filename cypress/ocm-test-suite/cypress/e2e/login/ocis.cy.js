describe('Login oCIS', () => {
  it('Login test for oCIS', () => {
		cy.loginOCIS('https://ocis1.docker', 'einstein', 'relativity')
  })
})
