import {
  createInviteTokenV27,
  createScienceMeshShareV27,
  renameFileV27
} from '../utils/nextcloud-v27'

import {
  acceptInviteLinkV5,
  verifyFederatedContactV5,
  acceptShareV5,
  verifyShareV5
} from '../utils/ocis-5'

describe('Invite link federated sharing via ScienceMesh functionality for oCIS', () => {
  it('Send invitation from Nextcloud v27 to oCIS v5', () => {

    cy.loginNextcloud('https://nextcloud1.docker', 'marie', 'radioactivity')
    cy.visit('https://nextcloud1.docker/index.php/apps/sciencemesh/contacts')

    createInviteTokenV27().then(
      (result) => {
        // save invite link to file.
        cy.writeFile('invite-link-nc-ocis.txt', result)
      }
    )
  })

  it('Accept invitation from Nextcloud v27 to oCIS v5', () => {

    // load invite token from file.
    cy.readFile('invite-link-nc-ocis.txt').then((token) => {

      cy.loginOcis('https://ocis1.docker', 'einstein', 'relativity')

      acceptInviteLinkV5(token)

      verifyFederatedContactV5('marie', 'revanextcloud1.docker')
    })
  })

  it('Send ScienceMesh share <file> from Nextcloud v27 to oCIS v5', () => {
    // share from Nextcloud 1.
    cy.loginNextcloud('https://nextcloud1.docker', 'marie', 'radioactivity')

    renameFileV27('welcome.txt', 'invite-link-nc-ocis.txt')
    createScienceMeshShareV27('nextcloud1.docker', 'Albert Einstein', 'https://ocis1.docker', 'invite-link-nc-ocis.txt')
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
