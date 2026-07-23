import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Currently-selected bottom-navigation tab index within [AppShellScreen].
/// Kept as simple global state (rather than encoding tabs in the go_router
/// path) so "See all" shortcuts from the Dashboard can jump straight to a
/// tab without pushing a new route / losing the shell chrome.
final selectedTabIndexProvider = StateProvider<int>((ref) => 0);
