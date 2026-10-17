import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';
import 'in_app_browser.dart';

Widget buildInAppBrowser({required String url, String? title, BrowserFooterAction? footerAction}) =>
    _InAppBrowserScreen(url: url, title: title, footerAction: footerAction);

class _InAppBrowserScreen extends StatefulWidget {
  const _InAppBrowserScreen({required this.url, this.title, this.footerAction});

  final String url;
  final String? title;
  final BrowserFooterAction? footerAction;

  @override
  State<_InAppBrowserScreen> createState() => _InAppBrowserScreenState();
}

class _InAppBrowserScreenState extends State<_InAppBrowserScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  String? _pageTitle;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
          onPageFinished: (_) async {
            final t = await _controller.getTitle();
            if (mounted) setState(() => _pageTitle = t);
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;
            if (uri.scheme == 'http' || uri.scheme == 'https') return NavigationDecision.navigate;
            // mailto:, tel:, app deep links — hand off to the OS.
            launchUrl(uri, mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.footerAction;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title ?? _pageTitle ?? (Uri.tryParse(widget.url)?.host ?? 'Browser'),
            overflow: TextOverflow.ellipsis,
          ),
          leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop()),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Reload',
              onPressed: () => _controller.reload(),
            ),
            PopupMenuButton<String>(
              onSelected: (_) => launchUrl(Uri.parse(widget.url), mode: LaunchMode.externalApplication),
              itemBuilder: (_) => const [PopupMenuItem(value: 'external', child: Text('Open in browser'))],
            ),
          ],
        ),
        body: Column(
          children: [
            if (_progress < 100) LinearProgressIndicator(value: _progress == 0 ? null : _progress / 100),
            Expanded(child: WebViewWidget(controller: _controller)),
          ],
        ),
        bottomNavigationBar: action == null
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppButton(
                    label: action.label,
                    icon: action.icon,
                    onPressed: () {
                      Navigator.of(context).pop();
                      action.onPressed();
                    },
                  ),
                ),
              ),
      ),
    );
  }
}
