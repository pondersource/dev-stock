import { createInviteToken, createScienceMeshShare, renameFile } from '../utils/owncloud'
import {
  openScienceMeshAppV5,
  createLegacyInviteLinkV5,
  acceptShareV5,
  verifyShareV5
} from '../utils/ocis-5'

describe('Invite link federated sharing via ScienceMesh functionality for ownCloud', () => {
  // Temporary diablle this scenario beacuase of: https://github.com/pondersource/dev-stock/issues/129#issuecomment-2254133337
  // until that issue resolves, try to initiate invites from oCIS.
  // it('Send invitation from ownCloud v10 to oCIS v5', () => {

  //   cy.loginOwncloud('https://owncloud1.docker', 'marie', 'radioactivity')
  //   cy.visit('https://owncloud1.docker/index.php/apps/sciencemesh/')

  //   createInviteToken('revaowncloud1.docker').then(
  //     (result) => {
  //       // save invite link to file.
  //       cy.writeFile('invite-link-oc-ocis.txt', result)
  //     }
  //   )
  // })

  // it('Accept invitation from ownCloud v10 to oCIS v5', () => {

  //   // load invite token from file.
  //   cy.readFile('invite-link-oc-ocis.txt').then((token) => {

  //     cy.loginOcis('https://ocis1.docker', 'einstein', 'relativity')

  //     acceptInviteLinkV5(token)

  //     verifyFederatedContactV5('marie', 'revaowncloud1.docker')
  //   })
  // })

  it('Send invitation from oCIS v5 to ownCloud v10', () => {

    cy.loginOcis('https://ocis1.docker', 'einstein', 'relativity')

    openScienceMeshAppV5()

    createLegacyInviteLinkV5('owncloud1.docker', 'ocis1.docker').then(
      (result) => {
        // save invite link to file.
        cy.writeFile('invite-link-ocis-oc.txt', result)
      }
    )
  })

  it('Accept invitation from oCIS v5 to ownCloud v10', () => {

    // load invite link from file.
    cy.readFile('invite-link-ocis-oc.txt').then((url) => {

      // accept invitation from ownCloud 1.
      cy.loginOwncloudCore(url, 'marie', 'radioactivity')

      cy.get('input[id="accept-button"]', { timeout: 10000 })
        .click()

      // validate 'Albert Einstein' is shown as a contact. 
      cy.visit('https://owncloud1.docker/index.php/apps/sciencemesh/contacts')

      cy.get('table[id="contact-table"]')
        .find('p[class="displayname"]')
        .should("have.text", "Albert Einstein");
    })
  })

  it('Send ScienceMesh share <file> from ownCloud v10 to oCIS v5', () => {
    // share from ownCloud 1.
    cy.loginOwncloud('https://owncloud1.docker', 'marie', 'radioactivity')

    renameFile('welcome.txt', 'invite-link-oc-ocis.txt')
    createScienceMeshShare('invite-link-oc-ocis.txt', 'einstein', 'ocis1.docker')
  })

  it('Receive ScienceMesh share <file> from ownCloud v10 to oCIS v5', () => {
    // accept share from oCIS 1.
    cy.loginOcis('https://ocis1.docker', 'einstein', 'relativity')

    acceptShareV5('invite-link-oc-ocis.txt')

    cy.reload(true)

    verifyShareV5(
      'invite-link-oc-ocis.txt',
      'marie',
      'Albert Einstein'
    )
  })
})