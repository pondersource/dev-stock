import {
  createInviteToken,
  createScienceMeshShare,
  renameFile
} from '../utils/owncloud'
import {
  acceptInviteLinkV5,
  verifyFederatedContactV5,
  acceptShareV5,
  verifyShareV5
} from '../utils/ocis-5'

describe('Invite link federated sharing via ScienceMesh functionality for ownCloud', () => {
  it('Send invitation from ownCloud v10 to oCIS v5', () => {

    cy.loginOwncloud('https://owncloud1.docker', 'marie', 'radioactivity')
    cy.visit('https://owncloud1.docker/index.php/apps/sciencemesh/')

    createInviteToken().then(
      (result) => {
        // save invite link to file.
        cy.writeFile('invite-link-oc-ocis.txt', result)
      }
    )
  })

  it('Accept invitation from ownCloud v10 to oCIS v5', () => {

    // load invite token from file.
    cy.readFile('invite-link-oc-ocis.txt').then((token) => {

      cy.loginOcis('https://ocis1.docker', 'einstein', 'relativity')

      acceptInviteLinkV5(token)

      verifyFederatedContactV5('marie', 'revaowncloud1.docker')
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