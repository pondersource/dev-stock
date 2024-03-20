const { defineConfig } = require('cypress')

module.exports = defineConfig({
  e2e: {
    experimentalOriginDependencies: true,
  },
  video: true,
  videoCompression: true,
})
