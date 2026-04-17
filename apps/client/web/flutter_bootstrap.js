{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
    timeoutMillis: 8000,
  },
  onEntrypointLoaded: async function(engineInitializer) {
    let appRunner = await engineInitializer.initializeEngine({
      // Use default renderer selection (Skwasm on modern browsers, CanvasKit fallback)
      renderer: "canvaskit",
    });
    await appRunner.runApp();
  }
});
