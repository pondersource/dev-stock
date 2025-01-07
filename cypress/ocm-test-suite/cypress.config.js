const { defineConfig } = require('cypress')

module.exports = defineConfig({
  e2e: {
    experimentalOriginDependencies: true,
  },
  chromeWebSecurity: false,
  video: true,
  videoCompression: true,
  modifyObstructiveCode: false,
})
