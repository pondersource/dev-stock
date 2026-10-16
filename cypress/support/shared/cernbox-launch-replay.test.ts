import { describe, expect, test } from "bun:test";
import {
  nextReplayHop, readLauncherPage, verifyLauncherForm, type LaunchPayload,
} from "./cernbox-launch-replay";

const secret = "SYNTHETIC-LAUNCH-SECRET";
const payload: LaunchPayload = {
  appUrl: "https://jupyterhub1.docker/services/ocm/open", accessToken: secret, hubOrigin: "https://jupyterhub1.docker",
};
const post = { url: payload.appUrl, method: "POST" as const, body: { access_token: secret } };
function form(attributes: Record<string, string>, fields: Array<Record<string, any>>) {
  return {
    getAttribute: (name: string) => attributes[name] ?? null,
    querySelectorAll: () => fields,
  } as unknown as HTMLFormElement;
}
function documentWith(forms: HTMLFormElement[]) {
  return { querySelectorAll: () => forms } as unknown as Document;
}
const noForms = () => documentWith([]);

describe("request replay handoff", () => {
  test("HTTP 200 auto-submit becomes a POST with every hidden field", () => {
    const html = '<form method="POST" action="/hub/ocm-login"></form>';
    const parsed = () => documentWith([form({ method: "POST", action: "/hub/ocm-login" }, [
      { name: "access_token", type: "hidden", value: secret, disabled: false },
      { name: "next", type: "hidden", value: "/user/demo/share-1/lab", disabled: false },
    ])]);
    expect(nextReplayHop(post, { status: 200, headers: {}, body: html }, payload.hubOrigin, parsed)).toEqual({
      hop: { url: payload.hubOrigin + "/hub/ocm-login", method: "POST",
        body: { access_token: secret, next: "/user/demo/share-1/lab" } },
    });
  });
  test("302/303 drop the POST body; 307/308 retain it", () => {
    for (const status of [302, 303, 307, 308]) {
      const result = nextReplayHop(post, {
        status, headers: { location: "/hub/ocm-login" }, body: "",
      }, payload.hubOrigin, noForms) as { hop: any };
      expect(result.hop.method).toBe(status >= 307 ? "POST" : "GET");
      expect(result.hop.body).toEqual(status >= 307 ? post.body : undefined);
    }
  });
  test("unnamed and named server Lab URLs are terminal and query-free", () => {
    for (const suffix of ["/user/demo/lab", "/user/demo/share-1/lab"]) {
      expect(nextReplayHop({ url: payload.hubOrigin + suffix + "?workspace=one", method: "GET" }, {
        status: 200, headers: {}, body: '<script id="jupyter-config-data"></script>',
      }, payload.hubOrigin, noForms)).toEqual({ labUrl: payload.hubOrigin + suffix });
    }
  });
  test("location.replace is decoded without executing HTML or JavaScript", () => {
    expect(nextReplayHop(post, { status: 200, headers: {}, body:
      '<script>window.location.replace("/user/demo/share-1/lab?one=1&amp;two=2")</script>',
    }, payload.hubOrigin, noForms)).toEqual({
      hop: { method: "GET", url: payload.hubOrigin + "/user/demo/share-1/lab?one=1&two=2" },
    });
  });
  test("external redirect, login HTML, unexpected status and duplicate fields fail closed", () => {
    for (const response of [
      { status: 302, headers: { location: "https://attacker.test/?access_token=" + secret }, body: "" },
      { status: 302, headers: { location: "https://other.test/lab" }, body: "" },
      { status: 401, headers: {}, body: secret },
      { status: 200, headers: {}, body: "<html>login</html>" },
    ]) {
      expect(() => nextReplayHop(post, response, payload.hubOrigin, noForms)).toThrow("Invalid CERNBox webapp launch handoff");
    }
    const duplicate = () => documentWith([form({ method: "POST", action: "/hub/ocm-login" }, [
      { name: "access_token", type: "hidden", value: secret },
      { name: "access_token", type: "hidden", value: secret },
    ])]);
    expect(() => nextReplayHop(post, { status: 200, headers: {}, body: "form" }, payload.hubOrigin, duplicate))
      .toThrow("Invalid CERNBox webapp launch handoff");
  });
});

const receiver = "https://cernbox1.docker";
const launcherAction = receiver + "/sciencemesh/webapp-launch";
const hidden = (name: string, value: string) => ({ name, type: "hidden", value, disabled: false });
function expectHandoffRejected(run: () => unknown) {
  try { run(); throw new Error("accepted"); }
  catch (error) {
    expect((error as Error).message).toBe("Invalid CERNBox webapp launch handoff");
    expect((error as Error).message).not.toContain(secret);
  }
}

describe("served launcher form is verified before being stubbed", () => {
  const spaFields = [
    hidden("file", "storage$space!share-1"), hidden("expired_session_redirect_uri", receiver),
    hidden("access-token", secret), hidden("access_token", secret),
  ];
  function submitted(overrides: any = {}) {
    return {
      method: "post", action: launcherAction, target: "ocm-remote-123",
      querySelectorAll: () => spaFields, ...overrides,
    } as unknown as HTMLFormElement;
  }
  const withFields = (fields: any[]) => submitted({ querySelectorAll: () => fields });

  test("exact form passes and keeps every field for the launcher POST", () => {
    expect(verifyLauncherForm(submitted(), receiver, "ocm-remote-123")).toEqual({
      url: launcherAction,
      fields: {
        file: "storage$space!share-1", expired_session_redirect_uri: receiver,
        "access-token": secret, access_token: secret,
      },
    });
    expect(verifyLauncherForm(withFields(spaFields.filter((field) =>
      field.name !== "expired_session_redirect_uri")), receiver, "ocm-remote-123").fields)
      .not.toHaveProperty("expired_session_redirect_uri");
  });
  test("wrong origin, path, method, target or fields fail without a secret echo", () => {
    const [file, redirect, dashed, underscored] = spaFields;
    for (const [form, windowName] of [
      [submitted({ action: payload.appUrl }), "ocm-remote-123"],
      [submitted({ action: receiver + "/sciencemesh/open-in-app" }), "ocm-remote-123"],
      [submitted({ action: "" }), "ocm-remote-123"],
      [submitted({ action: "https://other.docker/sciencemesh/webapp-launch" }), "ocm-remote-123"],
      [submitted({ action: launcherAction + "?file=1" }), "ocm-remote-123"],
      [submitted({ action: "http://cernbox1.docker/sciencemesh/webapp-launch" }), "ocm-remote-123"],
      [submitted({ method: "get" }), "ocm-remote-123"],
      [submitted({ target: "_self" }), "_self"],
      [submitted(), "ocm-remote-456"],
      [withFields([redirect, dashed, underscored]), "ocm-remote-123"],
      [withFields([hidden("file", " "), redirect, dashed, underscored]), "ocm-remote-123"],
      [withFields([file, redirect, hidden("access-token", "other"), underscored]), "ocm-remote-123"],
      [withFields([file, redirect, hidden("access-token", ""), hidden("access_token", "")]), "ocm-remote-123"],
      [withFields([file, redirect, dashed, { ...underscored, type: "text" }]), "ocm-remote-123"],
      [withFields([file, redirect, dashed, { ...underscored, disabled: true }]), "ocm-remote-123"],
      [withFields([file, redirect, dashed, underscored, underscored]), "ocm-remote-123"],
      [withFields([...spaFields, hidden("next", "/lab")]), "ocm-remote-123"],
      [withFields([file, hidden("expired_session_redirect_uri", "https://other.docker"), dashed, underscored]),
        "ocm-remote-123"],
    ] as Array<[HTMLFormElement, string]>) {
      expectHandoffRejected(() => verifyLauncherForm(form, receiver, windowName));
    }
  });
});

describe("served launcher page becomes the hub launch payload", () => {
  const hub = "https://jupyterhub1.docker";
  const nonce = "c3ludGhldGljLW5vbmNl";
  const policy = `default-src 'none'; base-uri 'none'; frame-ancestors 'none'; form-action ${hub}; ` +
    `script-src 'nonce-${nonce}'`;
  const pageFields = [hidden("access_token", secret), hidden("expired_session_redirect_uri", receiver)];
  type Page = { forms?: HTMLFormElement[]; scripts?: Array<Record<string, string>> };
  const launchForm = (attributes: Record<string, string> = {}, fields: any[] = pageFields) =>
    form({ id: "launch", method: "post", action: hub + "/services/ocm/open", ...attributes }, fields);
  function page({ forms = [launchForm()], scripts = [{ nonce }] }: Page = {}) {
    const elements = scripts.map((attributes) => ({ getAttribute: (name: string) => attributes[name] ?? null }));
    return () => ({
      querySelectorAll: (selector: string) => selector === "form" ? forms : selector === "script" ? elements : [],
    } as unknown as Document);
  }
  const response = (headers: Record<string, unknown> = { "content-security-policy": policy }, extra: any = {}) =>
    ({ status: 200, headers, body: "<launcher>", ...extra });

  test("form action, exchanged token and redirect are taken from the page", () => {
    expect(readLauncherPage(response(), page())).toEqual({
      appUrl: hub + "/services/ocm/open", accessToken: secret, hubOrigin: hub, expiredSessionRedirectUri: receiver,
    });
    expect(readLauncherPage(response({ "Content-Security-Policy": policy }),
      page({ forms: [launchForm({}, [pageFields[0]])] }))).toEqual({
      appUrl: hub + "/services/ocm/open", accessToken: secret, hubOrigin: hub,
    });
  });
  test("policy drift fails closed", () => {
    for (const headers of [
      {},
      { "content-security-policy": [policy] },
      { "content-security-policy": policy, "Content-Security-Policy": policy },
      { "content-security-policy": policy + ", form-action 'self'" },
      { "content-security-policy": policy.replace(hub, "https://other.docker") },
      { "content-security-policy": policy.replace(hub, hub + " https://other.docker") },
      { "content-security-policy": policy.replace(hub, "https://*.docker") },
      { "content-security-policy": policy.replace(hub, "'self'") },
      { "content-security-policy": policy.replace("default-src 'none'; ", "") },
      { "content-security-policy": policy.replace(`'nonce-${nonce}'`, "'none'") },
      { "content-security-policy": policy + "; form-action " + hub },
    ]) {
      expectHandoffRejected(() => readLauncherPage(response(headers), page()));
    }
  });
  test("page drift and non-200 responses fail closed", () => {
    expectHandoffRejected(() => readLauncherPage(response(undefined, { status: 400 }), page()));
    expectHandoffRejected(() => readLauncherPage(response(undefined, { body: { access_token: secret } }), page()));
    for (const parsed of [
      page({ scripts: [{ nonce: "other" }] }), page({ scripts: [] }), page({ scripts: [{ nonce }, { nonce }] }),
      page({ forms: [] }), page({ forms: [launchForm(), launchForm()] }),
      page({ forms: [launchForm({ id: "other" })] }), page({ forms: [launchForm({ method: "get" })] }),
      page({ forms: [launchForm({ action: "/services/ocm/open" })] }),
      page({ forms: [launchForm({ action: "https://other.docker/services/ocm/open" })] }),
      page({ forms: [launchForm({ action: hub + "/services/ocm/open/share-1" })] }),
      page({ forms: [launchForm({}, [...pageFields, hidden("next", "/lab")])] }),
      page({ forms: [launchForm({}, [hidden("access_token", " ")])] }),
      page({ forms: [launchForm({}, [pageFields[0], pageFields[0]])] }),
    ]) {
      expectHandoffRejected(() => readLauncherPage(response(), parsed));
    }
  });
});
