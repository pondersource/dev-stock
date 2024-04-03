Cypress.Commands.add('loginOwncloud', (url, username, password) => {
    cy.visit(url)

    // login page is visible in browser.
	cy.get('form[name="login"]').should('be.visible')

    // login with username and password.
    cy.get('form[name="login"]').within(() => {
        cy.get('input[name="user"]').type(username)
        cy.get('input[name="password"]').type(password)
        cy.get('button[id="submit"]').click()
    })

    // files app should be visible.
    cy.url().should('match', /apps\/files(\/|$)/)
})

Cypress.Commands.add('loginNextcloud', (url, username, password) => {
    cy.visit(url)

    // login page is visible in browser.
	cy.get('form[name="login"]').should('be.visible')

    // login with username and password.
    cy.get('form[name="login"]').within(() => {
        cy.get('input[name="user"]').type(username)
        cy.get('input[name="password"]').type(password)
        cy.contains('button[data-login-form-submit]', 'Log in').click()
    })

    // dashboard should be visible.
    cy.url().should('match', /apps\/dashboard(\/|$)/)

    // open files app.
    cy.get('header[id="header"]')
        .find('div[class="header-left"]')
        .find('nav[class="app-menu"]')
        .find('ul[class="app-menu-main"]')
        .find('li[data-app-id="files"]')
        .click()
    
    // files app should be visible.
    cy.url().should('match', /apps\/files(\/|$)/)
})

Cypress.Commands.add('loginSeafile', (url, username, password) => {
    cy.visit(url)

    // login page is visible in browser.
	cy.get('*[id^="wrapper"]').find('*[id^="log-in-panel"]').find('*[id^="login-form"]').should('be.visible')

    // login with username and password.
    cy.get('*[id^="wrapper"]').find('*[id^="log-in-panel"]').find('*[id^="login-form"]').within(() => {
        cy.get('input[name="login"]').type(username)
        cy.get('input[name="password"]').type(password)
        cy.get('*[type=submit]').click()
    })
})