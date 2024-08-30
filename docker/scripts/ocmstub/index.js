/* jshint ignore:start */
const https = require("https");
const fs = require("fs");
const url = require("url");

const SERVER_NAME = process.env.HOST || "meshdir";
const SERVER_PORT = process.env.PORT || 443;
const SERVER_HOST = `${SERVER_NAME}.docker`;

const HTTPS_OPTIONS = {
    key: fs.readFileSync(`/tls/${SERVER_NAME}.key`), cert: fs.readFileSync(`/tls/${SERVER_NAME}.crt`)
}

function sendHTML(res, text) {
    res.statusCode = 200;
    res.setHeader("Content-Type", "text/html");
    res.end(`<!DOCTYPE html><html lang="en-US"><head><title>OCM Stub</title></head><body>${text}</body></html>`);
}

const server = https.createServer(HTTPS_OPTIONS, async (req, res) => {

    let bodyIn = "";
    req.on("data", (chunk) => {

        bodyIn += chunk.toString();
    });
    req.on("end", async () => {
        try {
            if (req.url.startsWith("/meshdir?")) {
                url.parse(req.url, true).query;
                const config = {
                    nextcloud1: "https://nextcloud1.docker/index.php/apps/sciencemesh/accept",
                    nextcloud2: "https://nextcloud2.docker/index.php/apps/sciencemesh/accept",
                    owncloud1: "https://owncloud1.docker/index.php/apps/sciencemesh/accept",
                    owncloud2: "https://owncloud2.docker/index.php/apps/sciencemesh/accept",
                };
                const items = [];
                const scriptLines = [];
                Object.keys(config).forEach(key => {
                    if (typeof config[key] === "string") {
                        items.push(`  <li><a id="${key}">${key}</a></li>`);
                        scriptLines.push(`  document.getElementById("${key}").setAttribute("href", "${config[key]}"+window.location.search);`);
                    } else {
                        const params = new URLSearchParams(req.url.split("?")[1]);

                        const token = params.get("token");
                        const providerDomain = params.get("providerDomain");
                        items.push(`  <li>${key}: Please run <pre>ocm-invite-forward -idp ${providerDomain} -token ${token}</pre> in Reva's CLI tool.</li>`);
                    }
                })

                sendHTML(res, `Welcome to the meshdir stub. Please click a server to continue to:\n<ul>${items.join("\n")}</ul>\n<script>\n${scriptLines.join("\n")}\n</script>\n`);
            } else {

                sendHTML(res, "'OK'");
            }
        } catch (e) {
            console.error(e);
        }
    });
});

server.listen(SERVER_PORT, SERVER_HOST);
/* jshint ignore:end */
