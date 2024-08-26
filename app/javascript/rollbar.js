import Rollbar from 'rollbar/dist/rollbar.umd'

const token = document.querySelector('meta[name="rollbar-token"]')?.getAttribute('content')

if (token) {
  window.Rollbar ||= new Rollbar({
    accessToken: token,
    captureUncaught: true,
    captureUnhandledRejections: true,
    captureIp: false,
    autoInstrument: false,
    ignoredMessages: [
      /Failed to fetch/i,
      /NetworkError/i,
      /Load failed/i,
      /Clipboard write is not allowed/i
    ],
    transform (payload) {
      payload.body.telemetry = []

      if (payload.request.query_string) {
        payload.request.query_string = ''
      }

      if (payload.request.url) {
        payload.request.url = payload.request.url.replace(/(\/[sdep]\/)(\w{5})[^/]+/, '$1$2')
      }

      return payload
    },
    payload: {
      client: {
        javascript: {
          source_map_enabled: true
        }
      },
      environment: 'production'
    }
  })
}
