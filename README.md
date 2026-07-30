# Velionix Dashboard

Sitio estático (sin build) del dashboard de prospección comercial, listo para
desplegar en **Cloudflare Pages** conectado a **GitHub**.

## Qué se corrigió

1. **Conexión con Supabase**: el repo tenía dos proyectos de Supabase distintos
   mezclados (uno en `index.html`, otro en `dashboard.html` y en `src/lib/supabase.ts`).
   Se unificó todo al proyecto correcto: `lqvaliumnjprkekslnsq`, tabla `leads`.
2. **Logo**: `favicon.png` (el logo real) estaba en el repo pero ningún HTML lo
   usaba — el header mostraba una "V" de texto genérica y el `<link rel="icon">`
   era un SVG placeholder. Ahora el logo real se usa como ícono del header,
   favicon y en el `manifest.json` (`/logo.png`), sin el fondo de color que
   generaba un reborde feo alrededor.
3. **Manifest no reconocido**: `start_url` apuntaba a `/dashboard.html`, un
   archivo distinto al que realmente se sirve como página principal
   (`index.html`), y sus íconos apuntaban al `favicon.png` genérico en vez del
   logo real. Se corrigió `start_url` a `/` y los íconos a `/logo.png`.
4. **`_headers` / `_redirects` no se aplicaban**: existían como
   `_headers.txt` / `_redirects.txt` (con extensión), pero Cloudflare Pages solo
   reconoce los nombres exactos `_headers` y `_redirects`, sin extensión. Ya
   están renombrados y simplificados (el sitio no tiene build ni carpeta
   `/assets`, así que se quitaron reglas que no aplicaban).
5. **Scaffold de Vite/React roto y sin usar**: había un proyecto React a medio
   armar (`src/App.tsx`, `main.tsx`, dos versiones distintas de
   `lib/supabase.ts`) que **no se usa en ningún lado** — el dashboard real es
   HTML+JS plano (usa ES Modules vía import map desde `esm.sh`, sin necesidad
   de build). `App.tsx` ni siquiera compila (tiene código pegado a medias). Se
   eliminó todo ese scaffold para evitar la confusión y los errores de build en
   Cloudflare.
6. Se eliminaron `dashboard.html` y `prueba.html` (versiones duplicadas/de
   prueba con la config vieja de Supabase) — `dashboard.html` redirige a `/`
   por si alguien tenía el link guardado.

## Rediseño de marca

- Paleta nueva negro / plateado / dorado (inspirada en el fénix del logo), en
  modo oscuro y claro — aplicada tanto al dashboard como al panel del scraper.
- Botón **"Exportar CSV"** en la tabla de registros: descarga los leads
  filtrados/buscados en ese momento.
- Botón **"Scraper"** en el header, que abre el panel del scraper **dentro del
  mismo dominio** (`/scraper`) — no se sale de la app ni abre el navegador,
  algo clave para cuando esto sea una APK.
- **Categorías del scraper reorganizadas**: antes eran 184 categorías sueltas
  en una sola lista. Ahora están agrupadas por rubro (Salud, Legal, Turismo,
  etc.) en secciones colapsables, con "seleccionar todo" por grupo y contador
  de cuántas elegiste en cada una. La búsqueda ahora abre automáticamente los
  grupos que tienen resultados.
- **Copiar al portapapeles**: en el detalle de cada lead (dashboard), cada
  dato de contacto (email, teléfono, web, WhatsApp) tiene un botón para
  copiarlo con un clic.
- **Atajo de teclado**: presionar `/` en el dashboard enfoca la búsqueda al
  instante.

### Cómo funciona la integración con el scraper (mismo dominio)

El scraper (`Velionix Data Collector`) es una app Python/FastAPI aparte, que
seguís desplegando donde ya la tenés configurada (Render, con el
`render.yaml` de ese proyecto). Para que se sienta parte de la misma app:

- `/scraper` sirve una copia estática del panel de control del scraper
  (`scraper/index.html`), en este mismo dominio.
- Ese panel llama a su API (`/health`, `/jobs`, `/scrape`, etc.) usando
  siempre el dominio actual (`window.location.origin`) — por eso, en vez de
  llamar directo a Render, esas llamadas llegan a **Cloudflare Pages
  Functions** (carpeta `functions/`) que las reenvían al backend real.

Para activarlo, en Cloudflare Pages → tu proyecto → **Settings → Environment
variables**, agregá:

```
SCRAPER_BACKEND_URL = https://tu-scraper.onrender.com
```

(sin barra al final). Con eso, todo el tráfico de `/health`, `/jobs`,
`/scrape`, `/scrape/osm`, `/status/:id`, `/results/:id`, `/categories` y
`/enviar-a-n8n-cloud` se reenvía automáticamente a tu backend real, sin que
el navegador (ni la futura APK) note que son dos servidores distintos.

Si en algún momento el backend agrega un endpoint nuevo, hay que sumar el
archivo correspondiente en `functions/` (mirá los que ya existen como
ejemplo — todos usan el mismo helper `functions/_lib/proxy.js`).

## Camino a APK

Una vez que el dashboard esté funcionando bien como PWA (ya tiene manifest e
íconos correctos), convertirlo a `.apk` es un paso aparte y no requiere tocar
este código: se puede usar **PWABuilder** (pwabuilder.com) o **Bubblewrap**
apuntando a la URL ya desplegada en Cloudflare Pages. Avisame cuando quieras
hacer ese paso y te guío.

### Cómo generar la APK gratis (PWABuilder)

1. Andá a **https://pwabuilder.com**.
2. Pegá la URL de tu dashboard ya desplegado en Cloudflare Pages (ej.
   `https://dashboard-v2-2au.pages.dev` o tu dominio propio si le pusiste uno)
   y dale a **Start**.
3. PWABuilder analiza el manifest, los íconos y el service worker (ya están
   todos correctos en este repo) y te muestra un puntaje. Con esto debería
   pasar en verde "Manifest" y "Service Worker".
4. Andá a la pestaña **"Android"** → **"Generate Package"**.
   - Package ID: algo tipo `com.velionix.dashboard` (el que quieras).
   - Dejá tildado **"Generate Signing Key"** (PWABuilder te crea una llave de
     firma nueva, gratis, no hace falta cuenta de Google Play para esto).
5. Te descarga un `.zip` con:
   - un `.apk` (para instalar directo en un celular Android, sin Play Store)
   - un `.aab` (el formato que pide Play Store si algún día lo publicás ahí)
   - un `assetlinks.json` y los datos de tu llave de firma (fingerprint SHA-256)
6. **Paso clave para que la app no muestre la barra del navegador arriba**
   (que se vea 100% como app nativa): subí el `assetlinks.json` que te dio
   PWABuilder a este repo, en la ruta exacta:
   ```
   .well-known/assetlinks.json
   ```
   y hacé commit/push. Cloudflare Pages lo va a servir automáticamente en
   `https://tudashboard.com/.well-known/assetlinks.json`. Sin este archivo la
   APK igual funciona, pero se abre como una pestaña de Chrome con la barra
   de direcciones visible en vez de sentirse una app nativa.
7. Instalá el `.apk` en tu celular (activando "Instalar apps de orígenes
   desconocidos" la primera vez) y probalo.

Todo este proceso es gratis. Lo único que cuesta dinero es publicarla en
Google Play Store (~$25 USD, pago único, si en el futuro querés eso) — para
solo tener el `.apk` funcional e instalable no hace falta pagar nada.


## Estructura

```
index.html          → el dashboard completo (HTML + CSS + JS, un solo archivo)
logo.png             → tu logo real (favicon, ícono de PWA y logo del header)
manifest.json        → manifest de PWA, corregido
_headers             → cabeceras HTTP para Cloudflare Pages
_redirects           → redirects para Cloudflare Pages
scraper/index.html   → panel del scraper, servido en /scraper (mismo dominio)
functions/           → Cloudflare Pages Functions: proxy hacia el backend real del scraper
supabase/migrations  → SQL de referencia de las tablas (no se ejecuta en el deploy)
```

## Desplegar en Cloudflare Pages vía GitHub

1. Crea un repo nuevo en GitHub y sube esta carpeta:
   ```bash
   git init
   git add .
   git commit -m "Dashboard Velionix optimizado"
   git branch -M main
   git remote add origin https://github.com/TU_USUARIO/TU_REPO.git
   git push -u origin main
   ```
2. En Cloudflare Dashboard → **Workers & Pages** → **Create** → **Pages** →
   **Connect to Git**, elige el repo.
3. En la configuración del build:
   - **Framework preset**: `None`
   - **Build command**: (vacío)
   - **Build output directory**: `/`
4. Deploy. No hace falta ninguna variable de entorno: el sitio es 100%
   estático y usa la anon key pública de Supabase (segura de exponer porque
   RLS solo permite `SELECT`, sin escritura).

## Nota de seguridad

La anon key de Supabase que ves en `index.html` está pensada para ser
pública (así funciona el modelo de Supabase): el acceso real está controlado
por las políticas de RLS de la tabla `leads`, que solo permiten lectura
(`SELECT`) y bloquean cualquier `INSERT/UPDATE/DELETE` desde el dashboard.
