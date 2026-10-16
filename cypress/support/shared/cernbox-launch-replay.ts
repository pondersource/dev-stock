/// <reference types="cypress" />

export type LaunchPayload = {
  appUrl: string; accessToken: string; hubOrigin: string; expiredSessionRedirectUri?: string;
};
export type LauncherRequest = { url: string; fields: Record<string, string> };
export type ReplayHop = { url: string; method: "GET" | "POST"; body?: Record<string, string> };
export type ReplayResponse = { status: number; headers: Record<string, unknown>; body: unknown };

// The first hop blocks while the sender hub starts the named server, for up to
// JUPYTERHUB_SLOW_SPAWN_TIMEOUT_SEC in config/compose/cookbooks/nextcloud.webapp-hub.yml.
export const REPLAY_REQUEST_TIMEOUT_MS = 40000;
const REPLAY_DEADLINE_MS = 90000;

const launcherPath = "/sciencemesh/webapp-launch";
const launcherFormFields = new Set(["file", "expired_session_redirect_uri", "access-token", "access_token"]);
const launcherPageFields = new Set(["access_token", "expired_session_redirect_uri"]);

function reject(): never {
  throw new Error("Invalid CERNBox webapp launch handoff");
}

function checkedUrl(raw: string, base?: string): URL {
  try {
    const url = base ? new URL(raw, base) : new URL(raw);
    if (url.protocol !== "https:" || url.username || url.password ||
        url.searchParams.has("access_token") || url.searchParams.has("token")) reject();
    return url;
  } catch { return reject(); }
}

export function readCernboxLaunchPayload(body: unknown): LaunchPayload {
  let value: any;
  try { value = typeof body === "string" ? JSON.parse(body) : body; } catch { return reject(); }
  if (!value || typeof value !== "object" || Array.isArray(value) ||
      typeof value.app_url !== "string" || typeof value.access_token !== "string" ||
      value.access_token.trim() === "") reject();
  const url = checkedUrl(value.app_url);
  if (url.pathname !== "/services/ocm/open" || url.hash) reject();
  return { appUrl: url.href, accessToken: value.access_token, hubOrigin: url.origin };
}

export function verifyLaunchForm(form: HTMLFormElement, payload: LaunchPayload, windowName: string): void {
  const inputs = Array.from(form.querySelectorAll<HTMLInputElement>('input[name="access_token"]'));
  if (form.method.toUpperCase() !== "POST" ||
      form.action !== payload.appUrl ||
      !/^ocm-remote-\d+$/.test(form.target) || form.target !== windowName ||
      inputs.length !== 1 || inputs[0].type !== "hidden" ||
      inputs[0].value !== payload.accessToken ||
      form.querySelectorAll("input").length !== 1) reject();
}

function hiddenFields(inputs: HTMLInputElement[], allowed: ReadonlySet<string>): Record<string, string> {
  const fields: Record<string, string> = {};
  for (const input of inputs) {
    if (!allowed.has(input.name) || input.type !== "hidden" || input.disabled || input.name in fields) reject();
    fields[input.name] = input.value;
  }
  return fields;
}

// The served launcher shape: the SPA posts its own token to Reva on the same
// origin, and Reva answers with a page that posts the exchanged token onward.
export function isLauncherForm(form: HTMLFormElement, receiverOrigin: string): boolean {
  try {
    const url = new URL(form.action);
    return url.origin === receiverOrigin && url.pathname === launcherPath;
  } catch { return false; }
}

export function verifyLauncherForm(form: HTMLFormElement, receiverOrigin: string, windowName: string): LauncherRequest {
  const url = checkedUrl(form.action);
  if (form.method.toUpperCase() !== "POST" || url.origin !== receiverOrigin ||
      url.pathname !== launcherPath || url.search || url.hash ||
      !/^ocm-remote-\d+$/.test(form.target) || form.target !== windowName) reject();
  const fields = hiddenFields(Array.from(form.querySelectorAll<HTMLInputElement>("input")), launcherFormFields);
  const token = fields.access_token;
  if (typeof token !== "string" || token.trim() === "" || fields["access-token"] !== token ||
      typeof fields.file !== "string" || fields.file.trim() === "") reject();
  const redirect = fields.expired_session_redirect_uri;
  if (redirect !== undefined && checkedUrl(redirect).origin !== receiverOrigin) reject();
  return { url: url.href, fields };
}

function headerValue(headers: Record<string, unknown>, name: string): string {
  const entries = Object.entries(headers).filter(([key]) => key.toLowerCase() === name);
  if (entries.length !== 1 || typeof entries[0][1] !== "string") reject();
  return entries[0][1] as string;
}

// A comma would mean a second policy stacked on Reva's, which is exactly what
// the launcher must not get from an edge proxy.
function launcherPolicy(raw: string): { formAction: string; nonce: string } {
  if (raw.includes(",")) reject();
  const directives = new Map<string, string[]>();
  for (const part of raw.split(";")) {
    const [name, ...sources] = part.trim().split(/\s+/);
    if (!name) continue;
    if (directives.has(name.toLowerCase())) reject();
    directives.set(name.toLowerCase(), sources);
  }
  const only = (name: string) => {
    const sources = directives.get(name);
    if (!sources || sources.length !== 1) reject();
    return sources[0];
  };
  if (only("default-src") !== "'none'") reject();
  const formAction = only("form-action");
  if (!/^https:\/\/[^/\s'*]+$/.test(formAction)) reject();
  const nonce = only("script-src").match(/^'nonce-([A-Za-z0-9_-]+)'$/)?.[1];
  if (!nonce) reject();
  return { formAction: checkedUrl(formAction).origin, nonce };
}

export function readLauncherPage(response: ReplayResponse, parseHtml: (html: string) => Document): LaunchPayload {
  if (response.status !== 200 || typeof response.body !== "string") reject();
  const policy = launcherPolicy(headerValue(response.headers, "content-security-policy"));
  const document = parseHtml(response.body);
  const forms = Array.from(document.querySelectorAll<HTMLFormElement>("form"));
  const scripts = Array.from(document.querySelectorAll<HTMLScriptElement>("script"));
  if (forms.length !== 1 || forms[0].getAttribute("id") !== "launch" ||
      (forms[0].getAttribute("method") || "").toUpperCase() !== "POST" ||
      scripts.length !== 1 || scripts[0].getAttribute("nonce") !== policy.nonce) reject();
  const url = checkedUrl(forms[0].getAttribute("action") || "");
  if (url.pathname !== "/services/ocm/open" || url.hash || url.origin !== policy.formAction) reject();
  const fields = hiddenFields(Array.from(forms[0].querySelectorAll<HTMLInputElement>("input")), launcherPageFields);
  if (typeof fields.access_token !== "string" || fields.access_token.trim() === "") reject();
  return {
    appUrl: url.href, accessToken: fields.access_token, hubOrigin: url.origin,
    ...(fields.expired_session_redirect_uri !== undefined
      ? { expiredSessionRedirectUri: fields.expired_session_redirect_uri } : {}),
  };
}

export function nextReplayHop(
  hop: ReplayHop,
  response: ReplayResponse,
  hubOrigin: string,
  parseHtml: (html: string) => Document,
): { hop: ReplayHop } | { labUrl: string } {
  const current = checkedUrl(hop.url);
  if (current.origin !== hubOrigin) reject();
  const status = response.status;
  if ([301, 302, 303, 307, 308].includes(status)) {
    const location = response.headers.location ?? response.headers.Location;
    if (typeof location !== "string") reject();
    const target = checkedUrl(location, hop.url);
    if (target.origin !== hubOrigin) reject();
    const preservePost = [307, 308].includes(status) && hop.method === "POST";
    return { hop: { url: target.href, method: preservePost ? "POST" : "GET",
      ...(preservePost ? { body: hop.body } : {}) } };
  }
  if (status !== 200 || typeof response.body !== "string") reject();
  if (hop.method === "GET" && /^\/user\/[^/]+\/(?:[^/]+\/)?lab(?:\/.*)?$/.test(current.pathname)) {
    if (!/jupyter-config-data|jupyterlab|jp-LabShell/.test(response.body)) reject();
    return { labUrl: current.origin + current.pathname };
  }
  const document = parseHtml(response.body);
  const forms = Array.from(document.querySelectorAll<HTMLFormElement>("form"));
  const candidates = forms.filter((form) => {
    const rawAction = form.getAttribute("action");
    if (!rawAction) return false;
    try {
      const url = checkedUrl(rawAction, hop.url);
      return url.origin === hubOrigin && url.pathname === "/hub/ocm-login";
    } catch { return false; }
  });
  if (candidates.length === 1 && forms.length === 1) {
    const form = candidates[0];
    if ((form.getAttribute("method") || "GET").toUpperCase() !== "POST") reject();
    const fields: Record<string, string> = {};
    for (const input of Array.from(form.querySelectorAll<HTMLInputElement>("input"))) {
      if (!input.name || input.type !== "hidden" || input.disabled || input.name in fields) reject();
      fields[input.name] = input.value;
    }
    if (typeof fields.access_token !== "string" || fields.access_token.trim() === "") reject();
    const target = checkedUrl(form.getAttribute("action")!, hop.url);
    return { hop: { url: target.href, method: "POST", body: fields } };
  }
  const replace = response.body.match(/(?:window\.)?location\.replace\(\s*(["'])(.*?)\1\s*\)/);
  if (replace?.[2] && forms.length === 0) {
    const decoded = replace[2].replace(/&amp;/g, "&").replace(/&quot;/g, '"').replace(/&#39;/g, "'");
    const target = checkedUrl(decoded, hop.url);
    if (target.origin !== hubOrigin) reject();
    return { hop: { url: target.href, method: "GET" } };
  }
  return reject();
}

export function replayCernboxLaunch(
  payload: LaunchPayload,
  parseHtml: (html: string) => Document,
): Cypress.Chainable<{ hubOrigin: string; labUrl: string }> {
  const deadline = Date.now() + REPLAY_DEADLINE_MS;
  const redactedFailure = () => { throw new Error("CERNBox webapp launch replay failed"); };
  Cypress.once("fail", redactedFailure);

  function request(hop: ReplayHop, count: number): Cypress.Chainable<{ hubOrigin: string; labUrl: string }> {
    if (count >= 12 || Date.now() >= deadline) reject();
    return cy.request({
      method: hop.method, url: hop.url, body: hop.body,
      form: hop.method === "POST",
      followRedirect: false,
      failOnStatusCode: false,
      retryOnNetworkFailure: false,
      log: false,
      timeout: Math.max(1, Math.min(REPLAY_REQUEST_TIMEOUT_MS, deadline - Date.now())),
    }).then((response) => {
      const next = nextReplayHop(hop, response, payload.hubOrigin, parseHtml);
      if ("hop" in next) return request(next.hop, count + 1);
      const contentsUrl = next.labUrl.replace(/\/lab(?:\/.*)?$/, "/api/contents");
      if (Date.now() >= deadline) reject();
      return cy.request({
        method: "GET", url: contentsUrl, followRedirect: false,
        failOnStatusCode: false, retryOnNetworkFailure: false, log: false,
        timeout: Math.max(1, Math.min(REPLAY_REQUEST_TIMEOUT_MS, deadline - Date.now())),
      }).then((contents) => {
        const value = contents.body as { content?: Array<{ name?: string }> };
        const notebookPresent = contents.status === 200 && Array.isArray(value?.content) &&
          value.content.some((entry) => typeof entry.name === "string" && /\.ipynb$/i.test(entry.name));
        if (!notebookPresent) reject();
        return cy.getAllCookies({ log: false }).then((cookies) => {
          const hostname = new URL(payload.hubOrigin).hostname;
          const hubCookiePresent = cookies.some((cookie) =>
            cookie.domain.replace(/^\./, "") === hostname && cookie.secure);
          if (!hubCookiePresent) reject();
          Cypress.off("fail", redactedFailure);
          return cy.wrap({ hubOrigin: payload.hubOrigin, labUrl: next.labUrl }, { log: false });
        });
      });
    });
  }

  const body: Record<string, string> = { access_token: payload.accessToken };
  if (payload.expiredSessionRedirectUri !== undefined) {
    body.expired_session_redirect_uri = payload.expiredSessionRedirectUri;
  }
  return request({ url: payload.appUrl, method: "POST", body }, 0);
}

export function requestCernboxLauncher(
  launcher: LauncherRequest,
  parseHtml: (html: string) => Document,
): Cypress.Chainable<LaunchPayload> {
  const redactedFailure = () => { throw new Error("CERNBox webapp launch replay failed"); };
  Cypress.once("fail", redactedFailure);
  return cy.request({
    method: "POST", url: launcher.url, body: launcher.fields,
    form: true,
    followRedirect: false,
    failOnStatusCode: false,
    retryOnNetworkFailure: false,
    log: false,
    timeout: 15000,
  }).then((response) => {
    const payload = readLauncherPage(response, parseHtml);
    Cypress.off("fail", redactedFailure);
    return cy.wrap(payload, { log: false });
  });
}
