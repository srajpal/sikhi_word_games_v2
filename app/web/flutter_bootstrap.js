{{flutter_js}}
{{flutter_build_config}}

function showAppUpdateNotice() {
  if (document.getElementById('app-update-notice')) return;
  const notice = document.createElement('div');
  notice.id = 'app-update-notice';
  notice.setAttribute('role', 'status');
  notice.setAttribute('aria-live', 'polite');
  Object.assign(notice.style, {
    position: 'fixed', top: '12px', left: '12px', right: '12px',
    zIndex: '10000', padding: '12px', border: '1px solid CanvasText',
    borderRadius: '8px', background: 'Canvas', color: 'CanvasText',
    font: '1rem system-ui, sans-serif', colorScheme: 'light dark',
  });
  const message = document.createElement('span');
  message.textContent = 'An update is ready. Finish your round, then close all game tabs and reopen the game to update.';
  const dismiss = document.createElement('button');
  dismiss.type = 'button';
  dismiss.textContent = 'Dismiss';
  Object.assign(dismiss.style, {minHeight: '44px', marginLeft: '12px', font: 'inherit'});
  dismiss.addEventListener('click', () => notice.remove());
  notice.append(message, dismiss);
  document.body.appendChild(notice);
}

async function registerAppCache() {
  if (!('serviceWorker' in navigator)) return;
  try {
    const workerUrl = new URL('app_cache_service_worker.js', document.baseURI);
    const registration = await navigator.serviceWorker.register(workerUrl, {scope: './'});
    const watchInstalling = () => {
      const installing = registration.installing;
      if (!installing) return;
      installing.addEventListener('statechange', () => {
        if (installing.state === 'installed' && registration.active) showAppUpdateNotice();
      });
    };
    registration.addEventListener('updatefound', watchInstalling);
    watchInstalling();
    if (registration.waiting && registration.active) showAppUpdateNotice();
    const checkForUpdate = () => registration.update().catch(error => {
      console.warn('Unable to check for an app update.', error);
    });
    window.addEventListener('focus', checkForUpdate);
    await checkForUpdate();
    await navigator.serviceWorker.ready;
    document.documentElement.dataset.offlineReady = 'true';
    window.dispatchEvent(new CustomEvent('sikhi-offline-ready'));
  } catch (error) {
    console.warn('Offline app cache is unavailable.', error);
  }
}

registerAppCache();

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const loading = document.getElementById('loading');
    try {
      const appRunner = await engineInitializer.initializeEngine();
      await appRunner.runApp();
      loading?.remove();
    } catch (error) {
      console.error(error);
      if (loading) {
        loading.textContent = 'The game could not start. Please reload the page.';
      }
    }
  }
});
