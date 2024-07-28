describe('Login oCIS', () => {
  it('Login test for oCIS', () => {
		cy.loginOcis('https://ocis1.docker', 'einstein', 'relativity')
  })
})
