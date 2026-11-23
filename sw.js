const CACHE='gestao-restaurante-v15';
self.addEventListener('install',e=>e.waitUntil(caches.open(CACHE).then(c=>c.addAll(['./','./index.html','./assets/style.css?v=13','./assets/report.css?v=2','./assets/roadmap.css?v=4','./assets/app.js?v=15','./assets/icon-180.png','./assets/icon-192.png','./assets/icon-512.png','./manifest.json'])).then(()=>self.skipWaiting())));
self.addEventListener('activate',e=>e.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(key=>key.startsWith('gestao-restaurante-')&&key!==CACHE).map(key=>caches.delete(key)))).then(()=>self.clients.claim())));
self.addEventListener('fetch',e=>{if(e.request.method==='GET'&&new URL(e.request.url).origin===location.origin)e.respondWith(caches.match(e.request).then(cached=>cached||fetch(e.request)))});
