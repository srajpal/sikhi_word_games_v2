const BUILD_ID = 'development';
const APP_FILES = [];
const IS_CONFIGURED = BUILD_ID !== 'development' &&
  APP_FILES.length > 0 && APP_FILES.includes('index.html');
const SCOPE_ID = encodeURIComponent(self.registration.scope);
const CACHE_PREFIX = `sikhi-word-games-app-${SCOPE_ID}-`;
const CACHE_NAME = `${CACHE_PREFIX}${BUILD_ID}`;
const APP_URLS = new Set(
  APP_FILES.map(path => new URL(path, self.registration.scope).href),
);
const APP_SHELL = new URL('index.html', self.registration.scope);

self.addEventListener('install', event => {
  event.waitUntil((async () => {
    if (!IS_CONFIGURED) {
      throw new Error('App cache worker was not generated for a release build.');
    }
    const cache = await caches.open(CACHE_NAME);
    try {
      await cache.addAll([...APP_URLS]);
    } catch (error) {
      await caches.delete(CACHE_NAME);
      throw error;
    }
  })());
});

self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    const names = await caches.keys();
    await Promise.all(names
      .filter(name => name.startsWith(CACHE_PREFIX) && name !== CACHE_NAME)
      .map(name => caches.delete(name)));
  })());
});

self.addEventListener('fetch', event => {
  const request = event.request;
  const url = new URL(request.url);
  const scope = new URL(self.registration.scope);
  if (request.method !== 'GET' || url.origin !== scope.origin ||
      !url.pathname.startsWith(scope.pathname)) {
    return;
  }
  const cacheUrl = request.mode === 'navigate' ? APP_SHELL.href : url.href;
  if (!APP_URLS.has(cacheUrl)) return;
  event.respondWith((async () => {
    const cache = await caches.open(CACHE_NAME);
    const cached = await cache.match(cacheUrl);
    if (cached) return cached;
    const response = await fetch(request);
    if (response.ok) await cache.put(cacheUrl, response.clone());
    return response;
  })());
});
