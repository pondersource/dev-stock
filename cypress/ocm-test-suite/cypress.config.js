const { defineConfig } = require('cypress')

module.exports = defineConfig({
  e2e: {
    experimentalOriginDependencies: true,
  },
  modifyObstructiveCode: false,
  video: true,
  videoCompression: true,
})
