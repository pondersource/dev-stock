describe('Login Seafile', () => {
    it('Login test for Seafile', () => {
          cy.loginSeafile('http://seafile1.docker', 'jonathan@seafile.com', 'xu')
    })
  })
  