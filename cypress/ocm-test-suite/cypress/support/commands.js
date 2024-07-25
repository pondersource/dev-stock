Cypress.Commands.add('loginNextcloud', (url, username, password) => {
    cy.loginNextcloudCore(url, username, password)

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

Cypress.Commands.add('loginOwncloudCore', (url, username, password) => {
    cy.visit(url)

    // login page is visible in browser.
	cy.get('form[name="login"]').should('be.visible')

    // login with username and password.
    cy.get('form[name="login"]').within(() => {
        cy.get('input[name="user"]').type(username)
        cy.get('input[name="password"]').type(password)
        cy.get('button[id="submit"]').click()
    })
})

Cypress.Commands.add('loginOwncloud', (url, username, password) => {
    cy.loginOwncloudCore(url, username, password)

    // files app should be visible.
    cy.url().should('match', /apps\/files(\/|$)/)
})

Cypress.Commands.add('loginOCISCore', (url, username, password) => {
    cy.visit(url)

    // login page is visible in browser.
	cy.get('form[class="oc-login-form"]').should('be.visible')

    // login with username and password.
    cy.get('form[class="oc-login-form"]').within(() => {
        cy.get('input[id="oc-login-username"]').type(username)
        cy.get('input[id="oc-login-password"]').type(password)
        cy.get('button[type="submit"]').click()
    })
})

Cypress.Commands.add('loginOCIS', (url, username, password) => {
    cy.loginOCISCore(url, username, password)

    // files app should be visible.
    cy.url().should('match', /files\/spaces\/personal(\/|$)/)
})

Cypress.Commands.add('loginNextcloudCore', (url, username, password) => {
    cy.visit(url)

    // login page is visible in browser.
	cy.get('form[name="login"]').should('be.visible')

    // login with username and password.
    cy.get('form[name="login"]').within(() => {
        cy.get('input[name="user"]').type(username)
        cy.get('input[name="password"]').type(password)
        cy.contains('button[data-login-form-submit]', 'Log in').click()
    })
})
