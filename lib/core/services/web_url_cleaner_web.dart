import 'dart:html' as html;

/// Strips `?code=` / hash tokens from the address bar after auth exchange.
void clearAuthParamsFromBrowserUrl() {
  final path = html.window.location.pathname;
  html.window.history.replaceState(null, '', (path == null || path.isEmpty) ? '/' : path);
}
