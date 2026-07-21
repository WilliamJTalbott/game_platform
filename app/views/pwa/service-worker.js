const CACHE_NAME = "offline-v1"
const OFFLINE_URL = "/offline"

self.addEventListener("install", event => {
    event.waitUntil(
        caches.open(CACHE_NAME).then(cache => cache.add(OFFLINE_URL))
    )
})

self.addEventListener("fetch", event => {
    if (event.request.mode !== "navigate") return

    event.respondWith(
        fetch(event.request).catch(() => caches.match(OFFLINE_URL))
    )
})