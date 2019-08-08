module.exports = function(bs) {
  return {
    port: 8080,
    server: {
      baseDir: ".",
      middleware: {
        // overrides the second middleware default with new settings
        1: require('connect-history-api-fallback')({
          index: '/jsdeployer/lite-server-index.html',
          verbose: true
        })
      }
    }
  };
}
