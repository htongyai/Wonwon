/**
 * WonWon Cloud Functions
 *
 * resolveShortUrl
 *   HTTP endpoint that follows redirects on a Google Maps short URL
 *   (maps.app.goo.gl, goo.gl/maps, g.co/kgs) and returns the final
 *   long URL containing extractable lat/lng coordinates.
 *
 *   Why this exists:
 *     The Flutter web client cannot follow redirects through the
 *     `dio` package because browsers enforce CORS on cross-origin
 *     fetches. We proxy through a Cloud Function which runs server-
 *     side without CORS restrictions.
 *
 *   Request:  GET /resolveShortUrl?url=<encoded short url>
 *   Response: 200 application/json { resolvedUrl: "<long url>" }
 *             400 if missing/invalid url param
 *             502 if upstream fetch fails
 *
 *   CORS: allows requests from any origin (the resolved URL is
 *   already public, no auth involved).
 */

const functions = require('firebase-functions/v2/https');
const logger = require('firebase-functions/logger');

const ALLOWED_HOSTS = new Set([
  'maps.app.goo.gl',
  'goo.gl',
  'g.co',
  'maps.google.com',
  'www.google.com',
  'google.com',
]);

const MAX_REDIRECTS = 10;

/**
 * Follow redirects manually so we can support the chain of 30x hops
 * that maps.app.goo.gl uses (typically 2-3 hops to a long
 * google.com/maps URL with embedded coordinates).
 */
async function followRedirects(initialUrl) {
  let currentUrl = initialUrl;
  let hops = 0;
  while (hops < MAX_REDIRECTS) {
    const response = await fetch(currentUrl, {
      method: 'GET',
      redirect: 'manual',
      headers: {
        // CRITICAL: do NOT use a real desktop-Chrome UA here. Google
        // sniffs the UA and serves a JS-shell HTML page to "real"
        // browsers (no HTTP redirect, no extractable URL), but serves
        // a clean 302 with the long URL in `Location:` to bots. We
        // identify as a bot so we get the redirect we want.
        'User-Agent': 'Mozilla/5.0 (compatible; WonWonResolver/1.0)',
      },
    });

    // Not a redirect → this is the final destination.
    if (response.status < 300 || response.status >= 400) {
      return currentUrl;
    }

    const location = response.headers.get('location');
    if (!location) {
      return currentUrl;
    }

    currentUrl = new URL(location, currentUrl).toString();
    hops += 1;
  }
  return currentUrl;
}

exports.resolveShortUrl = functions.onRequest(
  {
    cors: true,
    region: 'us-central1',
    timeoutSeconds: 15,
    // Public — this is a CORS proxy called from the browser with no
    // user auth. Without this, v2 functions deploy as authenticated-only
    // and the browser gets 403 Forbidden.
    invoker: 'public',
  },
  async (req, res) => {
    try {
      const rawUrl = req.query.url;
      if (typeof rawUrl !== 'string' || rawUrl.length === 0) {
        res.status(400).json({ error: 'Missing url parameter' });
        return;
      }

      let parsed;
      try {
        parsed = new URL(rawUrl);
      } catch (_) {
        res.status(400).json({ error: 'Invalid url' });
        return;
      }

      // Only resolve URLs we expect — prevents this function being
      // used as an open redirect-checker against arbitrary hosts.
      if (!ALLOWED_HOSTS.has(parsed.hostname)) {
        res.status(400).json({
          error: 'Host not allowed',
          host: parsed.hostname,
        });
        return;
      }

      const resolvedUrl = await followRedirects(parsed.toString());
      logger.info('resolveShortUrl ok', { input: rawUrl, output: resolvedUrl });
      res.status(200).json({ resolvedUrl });
    } catch (err) {
      logger.error('resolveShortUrl failed', err);
      res.status(502).json({ error: 'Upstream fetch failed' });
    }
  },
);
