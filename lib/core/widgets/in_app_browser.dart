import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'in_app_browser_stub.dart' if (dart.library.io) 'in_app_browser_mobile.dart' as impl;

/// A button pinned under the in-app browser, e.g. "Finished applying? Claim
/// your points". Tapping it closes the browser first, then runs [onPressed].
class BrowserFooterAction {
  const BrowserFooterAction({required this.label, required this.onPressed, this.icon});

  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
}

/// Opens [url] in the phone's own browser or app (Chrome, Google Meet, ...),
/// which already has the user's Google sign-in. If nothing can handle it, or
/// the launch silently fails, it falls back to the in-app browser and says so,
/// instead of doing nothing.
Future<void> openExternal(BuildContext context, String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) return;

  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (!opened) {
    try {
      opened = await launchUrl(uri);
    } catch (_) {}
  }
  if (opened || !context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Could not open your browser, opening it inside the app instead.')),
  );
  await openInApp(context, url);
}

/// Opens [url] inside the app so the user doesn't have to leave GoCollab.
///
/// * Android / iOS: a full-screen in-app WebView with an optional footer
///   action ([BrowserFooterAction]).
/// * Web / desktop: most sites forbid being embedded in an iframe
///   (X-Frame-Options), so this falls back to a new browser tab.
///
/// Only http(s) links are opened; anything else is ignored.
Future<void> openInApp(
  BuildContext context,
  String url, {
  String? title,
  BrowserFooterAction? footerAction,
}) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) return;

  final supportsWebView = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  if (!supportsWebView) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return;
  }

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => impl.buildInAppBrowser(url: uri.toString(), title: title, footerAction: footerAction),
    ),
  );
}
