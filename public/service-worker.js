self.addEventListener('install', () => {
  console.log('arcab Sign App installed')
})

self.addEventListener('activate', () => {
  console.log('arcab Sign App activated')
})

self.addEventListener('fetch', (event) => {
  event.respondWith(fetch(event.request))
})
