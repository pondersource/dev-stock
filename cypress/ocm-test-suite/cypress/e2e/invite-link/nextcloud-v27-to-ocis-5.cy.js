import {
  createInviteLinkV27,
  verifyFederatedContactV27,
  createScienceMeshShareAdvancedV27,
  renameFileV27
} from '../utils/nextcloud-v27'

import {
  openScienceMeshAppV5,
  createLegacyInviteLinkV5,
  acceptShareV5,
  verifyShareV5
} from '../utils/ocis-5'

describe('Invite link federated sharing via ScienceMesh functionality for oCIS', () => {
  it('Send invitation from Nextcloud v27 to oCIS v5', () => {

    cy.loginOcis('https://ocis1.docker', 'einstein', 'relativity')

    openScienceMeshAppV5()

    createLegacyInviteLinkV5('nextcloud1.docker', 'ocis1.docker').then(
      (result) => {
        // save invite link to file.
        cy.writeFile('invite-link-nc-ocis.txt', result)
      }
    )
  })

  it('Accept invitation from Nextcloud v27 to oCIS v5', () => {

    // load invite link from file.
    cy.readFile('invite-link-nc-ocis.txt').then((url) => {

      // accept invitation from Nextcloud 1.
      cy.loginNextcloudCore(url, 'marie', 'radioactivity')

      cy.get('input[id="accept-button"]', { timeout: 10000 })
        .click()

      // validate 'Albert Einstein' is shown as a contact.
      verifyFederatedContactV27('nextcloud1.docker', 'Albert Einstein', 'ocis1.docker')
    })
  })

  it('Send ScienceMesh share <file> from Nextcloud v27 to oCIS v5', () => {
    // share from Nextcloud 1.
    cy.loginNextcloud('https://nextcloud1.docker', 'marie', 'radioactivity')

    renameFileV27('welcome.txt', 'invite-link-nc-ocis.txt')
    createScienceMeshShareAdvancedV27('nextcloud1.docker', 'Albert Einstein', 'ocis1.docker', 'invite-link-nc-ocis.txt')
  })

  it('Receive ScienceMesh share <file> from Nextcloud v27 to oCIS v5', () => {
    // accept share from oCIS 1.
    cy.loginOcis('https://ocis1.docker', 'einstein', 'relativity')

    acceptShareV5('invite-link-nc-ocis.txt')

    cy.reload(true)

    verifyShareV5(
      'invite-link-nc-ocis.txt',
      'marie',
      'Albert Einstein'
    )
  })
})
