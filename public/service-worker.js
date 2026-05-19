self.addEventListener('install', () => {
  console.log('WaboSign App installed')
})

self.addEventListener('activate', () => {
  console.log('WaboSign App activated')
})

self.addEventListener('fetch', (event) => {
  event.respondWith(fetch(event.request))
})
