/// Central registry of bundled asset paths. Keep every Image.asset /
/// Decoration.asset reference pointed at a constant here so renames stay
/// one-line changes.
abstract final class AppAssets {
  static const String gocollabLogo = 'assets/icons/gocollab_logo.png';
  static const String googleLogo = 'assets/icons/google_logo.png';

  /// Legacy GDGoC logo — kept for reference; prefer [gocollabLogo].
  @Deprecated('Use gocollabLogo instead')
  static const String gdgocLogo = gocollabLogo;
}
