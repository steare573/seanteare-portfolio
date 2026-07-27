/**
 * Directory-index rewriting for an S3 REST origin.
 *
 * The S3 *website* endpoint resolves index documents by itself; the REST API
 * that Origin Access Control talks to does not. Without this, /resume/ asks S3
 * for a key named "resume/" which does not exist, and the viewer gets a 403.
 *
 * Astro emits directory-style output (build.format: 'directory'), so:
 *   /                       -> /index.html
 *   /resume/                -> /resume/index.html
 *   /resume                 -> /resume/index.html
 *   /blog/agentic-workflows -> /blog/agentic-workflows/index.html
 *
 * Anything with a file extension (/_astro/app.css, /Sean-Teare-Resume.pdf) is
 * passed through untouched.
 *
 * Runs on viewer-request. CloudFront Functions are billed per invocation and
 * capped at 1ms of CPU, so this stays deliberately trivial — no regex.
 */
function handler(event) {
  var request = event.request;
  var uri = request.uri;

  if (uri.endsWith('/')) {
    request.uri = uri + 'index.html';
    return request;
  }

  // No dot in the last path segment means it is a route, not a file.
  var lastSegment = uri.substring(uri.lastIndexOf('/') + 1);
  if (lastSegment.indexOf('.') === -1) {
    request.uri = uri + '/index.html';
  }

  return request;
}
