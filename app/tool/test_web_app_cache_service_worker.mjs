import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';

const template = fs.readFileSync('web/app_cache_service_worker.js', 'utf8');
const files = ['index.html', 'main.dart.js', 'assets/words.json'];

function workerSource(buildId = 'build-one') {
  return template
    .replace("const BUILD_ID = 'development';", `const BUILD_ID = ${JSON.stringify(buildId)};`)
    .replace('const APP_FILES = [];', `const APP_FILES = ${JSON.stringify(files)};`);
}

function createHarness(scope, {failUrl, generated = true} = {}) {
  const listeners = new Map();
  const stores = new Map();
  let offline = false;
  class FakeResponse {
    constructor(body) { this.body = body; this.ok = true; }
    clone() { return new FakeResponse(this.body); }
  }
  const keyFor = value => typeof value === 'string' ? value : value.url;
  const network = async value => {
    const url = keyFor(value);
    if (offline || url === failUrl) throw new Error(`Network unavailable: ${url}`);
    return new FakeResponse(`network:${url}`);
  };
  const caches = {
    async open(name) {
      if (!stores.has(name)) stores.set(name, new Map());
      const store = stores.get(name);
      return {
        async addAll(urls) {
          for (const url of urls) store.set(keyFor(url), await network(url));
        },
        async match(key) { return store.get(keyFor(key)); },
        async put(key, response) { store.set(keyFor(key), response); },
      };
    },
    async keys() { return [...stores.keys()]; },
    async delete(name) { return stores.delete(name); },
  };
  const self = {
    registration: {scope},
    addEventListener(type, listener) { listeners.set(type, listener); },
  };
  vm.runInNewContext(generated ? workerSource() : template, {
    self, caches, fetch: network, URL, Set,
  });
  return {
    stores,
    setOffline(value) { offline = value; },
    async dispatch(type, request) {
      let pending;
      let response;
      const event = {
        request,
        waitUntil(value) { pending = value; },
        respondWith(value) { response = value; },
      };
      listeners.get(type)(event);
      if (pending) await pending;
      return response ? response : null;
    },
  };
}

const scope = 'https://games.example/itch/release/';
const harness = createHarness(scope);
await harness.dispatch('install');
assert.equal(harness.stores.size, 1);
const [currentCache] = harness.stores.keys();
assert.equal(harness.stores.get(currentCache).size, files.length);

harness.setOffline(true);
const navigation = await harness.dispatch('fetch', {
  method: 'GET', mode: 'navigate', url: scope,
});
assert.match((await navigation).body, /index\.html/);
assert.equal(await harness.dispatch('fetch', {
  method: 'POST', mode: 'cors', url: `${scope}main.dart.js`,
}), null);
assert.equal(await harness.dispatch('fetch', {
  method: 'GET', mode: 'cors', url: 'https://other.example/main.dart.js',
}), null);
assert.equal(await harness.dispatch('fetch', {
  method: 'GET', mode: 'cors', url: 'https://games.example/other/main.dart.js',
}), null);
assert.equal(await harness.dispatch('fetch', {
  method: 'GET', mode: 'cors', url: `${scope}main.dart.js?unbounded=1`,
}), null);
assert.equal(harness.stores.get(currentCache).size, files.length);

const ownPrefix = currentCache.slice(0, -'build-one'.length);
const otherScopeCache = `sikhi-word-games-app-${encodeURIComponent('https://games.example/itch/a_b/')}-old`;
harness.stores.set(`${ownPrefix}old`, new Map());
harness.stores.set(otherScopeCache, new Map());
harness.stores.set('unrelated-app-cache', new Map());
await harness.dispatch('activate');
assert.equal(harness.stores.has(`${ownPrefix}old`), false);
assert.equal(harness.stores.has(otherScopeCache), true);
assert.equal(harness.stores.has('unrelated-app-cache'), true);

const dashScope = createHarness('https://games.example/itch/a-b/');
const underscoreScope = createHarness('https://games.example/itch/a_b/');
await dashScope.dispatch('install');
await underscoreScope.dispatch('install');
assert.notEqual([...dashScope.stores.keys()][0], [...underscoreScope.stores.keys()][0]);

const failedAsset = `${scope}main.dart.js`;
const failed = createHarness(scope, {failUrl: failedAsset});
await assert.rejects(failed.dispatch('install'));
assert.equal(failed.stores.size, 0);

const unconfigured = createHarness(scope, {generated: false});
await assert.rejects(unconfigured.dispatch('install'), /not generated/);
assert.equal(unconfigured.stores.size, 0);
assert.doesNotMatch(template, /skipWaiting|clients\.claim/);

console.log('Web app cache service worker behavior passed.');
