/**
 * Reenvía la request actual al backend del scraper (Velionix Data Collector),
 * desplegado aparte (Render, VPS, etc.). Así el navegador siempre habla con
 * un solo dominio: el de este sitio. Esto es clave para que, empaquetado
 * como APK (TWA), nunca se salga a una pestaña del navegador del celular.
 *
 * Requiere la variable de entorno SCRAPER_BACKEND_URL configurada en
 * Cloudflare Pages → Settings → Environment variables, ej:
 *   https://tu-scraper.onrender.com
 */
export async function proxyToScraper(context) {
  const { request, env, params } = context;
  const backend = env.SCRAPER_BACKEND_URL;

  if (!backend) {
    return new Response(
      JSON.stringify({
        error: "SCRAPER_BACKEND_URL no está configurada en Cloudflare Pages.",
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }

  const incoming = new URL(request.url);
  // "path" llega desde el catch-all de la ruta ([[path]]); si no existe,
  // se usa el pathname tal cual (rutas fijas como /health, /jobs, etc.)
  const suffix = params && params.path ? "/" + params.path.join("/") : incoming.pathname;
  const target = new URL(backend.replace(/\/$/, "") + suffix);
  target.search = incoming.search;

  const headers = new Headers(request.headers);
  headers.delete("host");
  headers.delete("cf-connecting-ip");
  headers.delete("cf-ipcountry");
  headers.delete("cf-ray");
  headers.delete("cf-visitor");

  const init = {
    method: request.method,
    headers,
    redirect: "manual",
  };
  if (!["GET", "HEAD"].includes(request.method)) {
    init.body = await request.arrayBuffer();
  }

  const upstream = await fetch(target.toString(), init);
  const respHeaders = new Headers(upstream.headers);
  respHeaders.delete("content-encoding");
  respHeaders.delete("content-length");
  return new Response(upstream.body, {
    status: upstream.status,
    statusText: upstream.statusText,
    headers: respHeaders,
  });
}
