self.addEventListener('install', () => {
  console.log('DocuSeal App installed')
})

self.addEventListener('activate', () => {
  console.log('DocuSeal App activated')
})

self.addEventListener('fetch', (event) => {
  event.respondWith(fetch(event.request))
})
