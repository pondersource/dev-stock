/// <reference types="cypress" />

import type { WebappShareFlowReceiverAdapter } from "../../../contracts/webapp-share";
import type { CernboxWebappShareLaunchArtifact } from "../../../shared/webapp-share-launch-artifact";
import {
  assertHubLaunchOrigin,
  extractHubLaunchOriginFromOpenInApp,
} from "../../../shared/webapp-share-launch-artifact";
import { cssEscapeAttributeValue } from "../../../shared/selectors";
import {
  isLauncherForm,
  readCernboxLaunchPayload,
  replayCernboxLaunch,
  requestCernboxLauncher,
  verifyLaunchForm,
  verifyLauncherForm,
  type LaunchPayload,
  type LauncherRequest,
} from "../../../shared/cernbox-launch-replay";
import { makeCernboxFilesHelpers } from "../shared/files";
import { makeCernboxSharingHelpers } from "../shared/sharing";
import { cernboxV11Profile } from "./profile";

const files = makeCernboxFilesHelpers(cernboxV11Profile);
const sharing = makeCernboxSharingHelpers(cernboxV11Profile, files);
const sel = cernboxV11Profile.selectors.sharing;
const sharesNavTimeoutMs = 60000;
const launchTimeoutMs = 90000;

function openReceivedFolderMenu(sharedFolderName: string): void {
  const escapedName = cssEscapeAttributeValue(sharedFolderName);

  sharing.openSharesWithMe();
  sharing.openResourceContextMenu(
    sel.receivedResourceByName(escapedName),
    sharesNavTimeoutMs,
  );
}

export const cernboxV11WebappShareFlowReceiverAdapter: WebappShareFlowReceiverAdapter =
  {
    key: "cernbox/v11",
    // Browser launch and request replay bypass the server-to-server OCM MITM.
    // The real launch response (open-in-app or the served launcher page), the
    // verified form and the cookie-authenticated Lab are gated separately from
    // the terminal UI proof.
    mitmLaunchExpectations: [],

    acceptIncomingWebappShare({ sharedFolderName }) {
      sharing.acceptIncomingShare(sharedFolderName);
    },

    launchRemoteWebapp({ sharedFolderName }) {
      // Explicit experiment mode preserves the old native navigation for A1.
      if (!Boolean(Cypress.expose("webapp_request_replay"))) {
        // Keep the launch in-tab: the "Open remotely" action pre-opens a named
        // popup then form-POSTs the launch into it. The stub names the current
        // window so the POST targets this tab.
        files.stubWindowOpenForInTabNavigation();

        // Observe (do not modify) the open-in-app response; the app_url in its
        // JSON body is the cross-origin remote hub the browser then POSTs into.
        cy.intercept("POST", "**/sciencemesh/open-in-app").as("cernboxOpenInApp");

        openReceivedFolderMenu(sharedFolderName);

        cy.get(sel.contextMenu)
          .contains(
            'button, [role="menuitem"], li, span',
            /Open remotely/i,
            { timeout: sharesNavTimeoutMs },
          )
          .should("be.visible")
          .click({ force: true });

        const receiverOrigin = new URL(String(Cypress.config("baseUrl"))).origin;

        return cy
          .wait("@cernboxOpenInApp", { timeout: launchTimeoutMs })
          .then((interception) => {
            const statusCode = interception.response?.statusCode;
            expect(statusCode, "CERNBox open-in-app status code").to.be.oneOf([
              200, 201, 204,
            ]);

            const hubOrigin = extractHubLaunchOriginFromOpenInApp(
              interception.response?.body,
            );
            assertHubLaunchOrigin(hubOrigin, receiverOrigin);

            const artifact: CernboxWebappShareLaunchArtifact = {
              receiverKind: "cernbox",
              launchGate: "cross-origin-open",
              hubOrigin: hubOrigin as string,
            };
            return cy.wrap(artifact);
          });
      }

      // Preserve the named-window setup; the form submission itself is stubbed.
      // Two launch shapes exist: the SPA form-POSTs the open-in-app result to
      // the hub, or it form-POSTs to Reva's same-origin served launcher.
      files.stubWindowOpenForInTabNavigation();
      const receiverOrigin = new URL(String(Cypress.config("baseUrl"))).origin;
      let payload: LaunchPayload | null = null;
      let openInAppStatus: number | undefined;
      let launcher: LauncherRequest | null = null;
      let handoffError: Error | null = null;
      let submitted = 0;
      let parseHtml: (html: string) => Document;
      cy.intercept("POST", "**/sciencemesh/open-in-app", (request) => {
        request.continue((response) => {
          openInAppStatus = response.statusCode;
          payload = readCernboxLaunchPayload(response.body);
        });
      }).as("cernboxOpenInApp");
      openReceivedFolderMenu(sharedFolderName);
      cy.window({ log: false }).then((win) => {
        parseHtml = (html) => new win.DOMParser().parseFromString(html, "text/html");
        // Stub, never observe/pass through: no top-level form navigation occurs.
        cy.stub(win.HTMLFormElement.prototype, "submit").callsFake(function(this: HTMLFormElement) {
          // The SPA catches submit errors to show a toast, so keep the
          // rejection and fail the step with it instead of timing out.
          try {
            if (isLauncherForm(this, receiverOrigin)) {
              launcher = verifyLauncherForm(this, receiverOrigin, win.name);
            } else {
              if (!payload) throw new Error("Missing CERNBox launch payload");
              verifyLaunchForm(this, payload, win.name);
            }
          } catch (error) {
            handoffError = error as Error;
            throw error;
          }
          submitted += 1;
        }).log(false);
      });
      cy.get(sel.contextMenu)
        .contains('button, [role="menuitem"], li, span', /Open remotely/i, {
          timeout: sharesNavTimeoutMs,
        })
        .should("be.visible")
        .click({ force: true });
      return cy.wrap(null, { log: false, timeout: launchTimeoutMs })
        .should(() => {
          expect(submitted + (handoffError ? 1 : 0), "native launch POST was stubbed exactly once").to.equal(1);
        })
        .then(() => {
          if (handoffError) throw handoffError;
          if (launcher) {
            expect(openInAppStatus, "served launch does not call open-in-app").to.equal(undefined);
          } else {
            expect(openInAppStatus, "CERNBox open-in-app status code").to.equal(200);
            expect(payload !== null, "validated launch payload exists").to.equal(true);
          }
        })
        .then(() => cy.window({ log: false }))
        .then((win) => {
          expect(win.location.origin, "receiver did not navigate on form submission").to.equal(receiverOrigin);
          const resolved = launcher
            ? requestCernboxLauncher(launcher, parseHtml)
            : cy.wrap(payload!, { log: false });
          return resolved.then((launch) => {
            assertHubLaunchOrigin(launch.hubOrigin, receiverOrigin);
            return replayCernboxLaunch(launch, parseHtml);
          });
        })
        .then((result) => {
          const artifact: CernboxWebappShareLaunchArtifact = {
            receiverKind: "cernbox",
            launchGate: "request-replay",
            hubOrigin: result.hubOrigin,
            labUrl: result.labUrl,
          };
          return cy.wrap(artifact, { log: false });
        });
    },
  };
