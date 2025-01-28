import {
  openFilesAppV5,
  openScienceMeshAppV5,
  createInviteTokenV5,
  acceptInviteLinkV5,
  verifyFederatedContactV5,
  createTextFileV5,
  createShareV5,
  acceptShareV5,
  verifyShareV5
} from '../utils/ocis-5'

describe('Invite link federated sharing via ScienceMesh functionality for oCIS', () => {
  it('Send invitation from oCIS v5 to oCIS v5', () => {

    cy.loginOcis('https://ocis1.docker', 'einstein', 'relativity')

    openScienceMeshAppV5()

    createInviteTokenV5().then(
      (result) => {
        // save invite link to file.
        cy.writeFile('invite-link-ocis-ocis.txt', result)
      }
    )
    cy.wait(5000)
  })

  it('Accept invitation from oCIS v5 to oCIS v5', () => {

    // load invite token from file.
    cy.readFile('invite-link-ocis-ocis.txt').then((token) => {
      // Verify token exists and is not empty
      expect(token).to.exist
      expect(token.trim()).to.not.be.empty
      cy.log('Read token from file:', token)

      cy.loginOcis('https://ocis2.docker', 'marie', 'radioactivity')

      acceptInviteLinkV5(token)

      verifyFederatedContactV5('Albert Einstein', 'ocis1.docker')
    })
    cy.wait(5000)
  })

  it('Send ScienceMesh share <file> from oCIS v5 to oCIS v5', () => {
    // share from oCIS 1.
    cy.loginOcis('https://ocis1.docker', 'einstein', 'relativity')

    createTextFileV5('invite-link-ocis-ocis.txt', 'Hello World!')

    openFilesAppV5()

    createShareV5('invite-link-ocis-ocis.txt', 'marie')
    cy.wait(5000)
  })

  it('Receive ScienceMesh share <file> from oCIS v5 to oCIS v5', () => {
    // accept share from oCIS 2.
    cy.loginOcis('https://ocis2.docker', 'marie', 'radioactivity')

    acceptShareV5('invite-link-ocis-ocis.txt')

    cy.reload(true)

    verifyShareV5(
      'invite-link-ocis-ocis.txt',
      'Albert Einstein',
      'Marie Skłodowska Curie'
    )
    cy.wait(5000)
  })
})
