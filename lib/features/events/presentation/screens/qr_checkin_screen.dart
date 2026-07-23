import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/event_providers.dart';

/// Officer-only QR attendance scanner. Uses `mobile_scanner` (native camera
/// pipeline, no external API) to read each attendee's registration QR code
/// and validate it server-side via [EventRepository.checkInWithQrCode].
class QrCheckInScreen extends ConsumerStatefulWidget {
  const QrCheckInScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<QrCheckInScreen> createState() => _QrCheckInScreenState();
}

class _QrCheckInScreenState extends ConsumerState<QrCheckInScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  String? _lastMessage;
  bool? _lastSuccess;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_isProcessing) return;
    if (capture.barcodes.isEmpty) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() => _isProcessing = true);

    final officer = ref.read(currentUserProvider).valueOrNull;
    if (officer == null) {
      setState(() {
        _isProcessing = false;
        _lastSuccess = false;
        _lastMessage = 'Officer session not found. Please re-login.';
      });
      return;
    }

    final repository = ref.read(eventRepositoryProvider);
    final result = await repository.checkInWithQrCode(
      eventId: widget.eventId,
      qrCode: code,
      officerId: officer.id,
    );

    result.when(
      success: (name) {
        setState(() {
          _lastSuccess = true;
          _lastMessage = '$name checked in successfully!';
        });
      },
      failure: (failure) {
        setState(() {
          _lastSuccess = false;
          _lastMessage = failure.message;
        });
      },
    );

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan attendance QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () => _scannerController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _scannerController, onDetect: _handleDetection),
          _ScannerFrameOverlay(),
          if (_lastMessage != null)
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.xxl,
              child: _ResultBanner(message: _lastMessage!, success: _lastSuccess ?? false),
            ),
        ],
      ),
    );
  }
}

class _ScannerFrameOverlay extends StatelessWidget {
  const _ScannerFrameOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 3),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
        ),
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.message, required this.success});

  final String message;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final color = success ? AppColors.googleGreen : AppColors.googleRed;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16)],
      ),
      child: Row(
        children: [
          Icon(success ? Icons.check_circle_rounded : Icons.error_rounded, color: Colors.white),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
