/**
 * sw.js – Service worker for rparams-dat PWA.
 * Caches all local app-shell assets on install; serves from cache first.
 */

const CACHE = 'rparams-v1';

const ASSETS = [
    './index.html',
    './manifest.json',
    './css/style.css',
    './vendor/font-awesome.min.css',
    './fonts/fontawesome-webfont.woff2',
    './fonts/fontawesome-webfont.woff',
    './images/RafLogo.svg',
    './images/logo-title.svg'
];

self.addEventListener('install', event => {
    event.waitUntil(
        caches.open(CACHE)
            .then(cache => cache.addAll(ASSETS))
            .then(() => self.skipWaiting())
    );
});

self.addEventListener('activate', event => {
    event.waitUntil(
        caches.keys()
            .then(keys => Promise.all(
                keys.filter(k => k !== CACHE).map(k => caches.delete(k))
            ))
            .then(() => self.clients.claim())
    );
});

self.addEventListener('fetch', event => {
    // Only intercept same-origin GET requests
    if (event.request.method !== 'GET') return;
    if (!event.request.url.startsWith(self.location.origin)) return;

    event.respondWith(
        caches.match(event.request)
            .then(cached => cached || fetch(event.request))
    );
});
