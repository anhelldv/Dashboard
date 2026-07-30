import { proxyToScraper } from "./_lib/proxy.js";

export const onRequest = (context) => proxyToScraper(context);
