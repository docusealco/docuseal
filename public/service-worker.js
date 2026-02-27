self.addEventListener('install', () => {
  console.log('App installed')
})

self.addEventListener('activate', () => {
  console.log('App activated')
})

self.addEventListener('fetch', (event) => {
  event.respondWith(fetch(event.request))
})
