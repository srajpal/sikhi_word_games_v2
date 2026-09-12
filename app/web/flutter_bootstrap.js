{{flutter_js}}
{{flutter_build_config}}

async function registerAppCache() {
  if (!('serviceWorker' in navigator)) return;
  try {
    const workerUrl = new URL('app_cache_service_worker.js', document.baseURI);
    const registration = await navigator.serviceWorker.register(workerUrl, {scope: './'});
    await registration.update();
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
