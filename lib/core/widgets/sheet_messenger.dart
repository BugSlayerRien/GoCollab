import 'package:flutter/material.dart';

/// Gives a modal bottom sheet its own [ScaffoldMessenger] so SnackBars shown
/// while the sheet is still open render above it. By default a SnackBar is
/// hosted by the page's own Scaffold, which sits *underneath* an open modal
/// bottom sheet route — so validation errors shown before the sheet closes
/// were invisible behind the modal.
class SheetMessenger extends StatelessWidget {
  const SheetMessenger({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: child,
      ),
    );
  }
}
