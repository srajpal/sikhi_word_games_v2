import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';

const path = process.argv[2] ?? 'web/flutter_bootstrap.js';
const bootstrap = fs.readFileSync(path, 'utf8');
const source = bootstrap.slice(bootstrap.indexOf('function showAppUpdateNotice()'), bootstrap.indexOf('_flutter.loader.load('));
assert.ok(source.includes('registerAppCache();'));
assert.doesNotMatch(source, /skipWaiting|clients\.claim|location\.reload/);

async function harness({active = false, waiting = false, updateFails = false} = {}) {
  const nodes = new Map();
  const windowEvents = new Map();
  const workerEvents = new Map();
  const registrationEvents = new Map();
  let updateChecks = 0;
  function element() {
    return {
      style: {}, attributes: {}, children: [], events: new Map(),
      setAttribute(key, value) { this.attributes[key] = value; },
      append(...children) { this.children.push(...children); },
      addEventListener(type, listener) { this.events.set(type, listener); },
      remove() { nodes.delete(this.id); },
    };
  }
  const worker = {state: 'installing', addEventListener(type, listener) { workerEvents.set(type, listener); }};
  const registration = {
    active: active ? {} : null, waiting: waiting ? {} : null, installing: worker,
    addEventListener(type, listener) { registrationEvents.set(type, listener); },
    async update() { updateChecks++; if (updateFails) throw Error('offline'); },
  };
  const document = {
    baseURI: 'https://games.example/nested/game/',
    documentElement: {dataset: {}},
    getElementById(id) { return nodes.get(id); },
    createElement: element,
    body: {appendChild(node) { nodes.set(node.id, node); }},
  };
  vm.runInNewContext(source, {
    URL, document,
    navigator: {serviceWorker: {async register() { return registration; }, ready: Promise.resolve()}},
    window: {addEventListener(type, listener) { windowEvents.set(type, listener); }, dispatchEvent() {}},
    CustomEvent: class {}, console: {warn() {}},
  });
  await new Promise(setImmediate);
  return {nodes, document, windowEvents, get updateChecks() { return updateChecks; },
    installed() { registrationEvents.get('updatefound')(); worker.state = 'installed'; workerEvents.get('statechange')(); },
  };
}

const first = await harness();
first.installed();
assert.equal(first.nodes.size, 0, 'first install must not show an update');
const upgraded = await harness({active: true});
upgraded.installed();
const notice = upgraded.nodes.get('app-update-notice');
assert.equal(notice.attributes.role, 'status');
assert.match(notice.children[0].textContent, /close all game tabs/);
upgraded.installed();
assert.equal(upgraded.nodes.size, 1);
notice.children[1].events.get('click')();
assert.equal(upgraded.nodes.size, 0);
const waiting = await harness({active: true, waiting: true, updateFails: true});
assert.equal(waiting.nodes.size, 1, 'already waiting builds are noticed');
assert.equal(waiting.document.documentElement.dataset.offlineReady, 'true');
await waiting.windowEvents.get('focus')();
assert.equal(waiting.updateChecks, 2);
console.log(`Web update notice behavior passed: ${path}`);
