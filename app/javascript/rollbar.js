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

      const string = JSON.stringify(payload)

      return JSON.parse(string.replace(/(\/[des]\/)\w{6}/g, (_, m) => m))
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
