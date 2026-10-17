import 'package:flutter/widgets.dart';
import 'in_app_browser.dart';

/// Web build: [openInApp] never reaches this (it opens a new tab instead).
Widget buildInAppBrowser({required String url, String? title, BrowserFooterAction? footerAction}) =>
    const SizedBox.shrink();
