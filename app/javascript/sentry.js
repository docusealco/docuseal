import * as Sentry from '@sentry/browser'

const sentryDsn = document.querySelector('meta[name="sentry-dsn"]')?.getAttribute('content')

if (sentryDsn) {
  Sentry.init({
    dsn: sentryDsn,
    beforeSend (event) {
      if (event.request.url.match(/\/[ds]\//)) {
        event.request.url = event.request.url.slice(0, -6)
      }

      return event
    },
    beforeBreadcrumb () {
      return null
    }
  })
}
