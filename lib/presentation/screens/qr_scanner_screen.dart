import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sumadhura_visitor_management/presentation/controllers/visitor_controller.dart';
import 'package:sumadhura_visitor_management/presentation/screens/visitor_details_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _handled = false;
  String? _message;
  bool _busy = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan visitor QR'),
        actions: [
          IconButton(
            tooltip: 'Toggle camera',
            onPressed: _scannerController.switchCamera,
            icon: const Icon(Icons.cameraswitch_outlined),
          ),
          IconButton(
            tooltip: 'Toggle flashlight',
            onPressed: _scannerController.toggleTorch,
            icon: const Icon(Icons.flash_on_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: _onDetect,
                      errorBuilder: (context, error, child) =>
                          _CameraError(error: error, onRetry: _resume),
                    ),
                    IgnorePointer(
                      child: Center(
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 3),
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                    if (_busy)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 26),
            child: Column(
              children: [
                Text(
                  _message ?? 'Align the visitor QR code inside the frame.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _resume,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Scan another code'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final value = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstOrNull
        ?.trim();
    if (value == null ||
        value.isEmpty ||
        !RegExp(r'^[A-Za-z0-9_-]{1,100}$').hasMatch(value)) {
      _handled = true;
      setState(() => _message = 'Invalid QR code. Scan a visitor pass QR.');
      return;
    }
    _handled = true;
    setState(() {
      _busy = true;
      _message = null;
    });
    final controller = Get.find<VisitorController>();
    final visitor = await controller.fetchVisitor(value);
    if (!mounted) return;
    if (visitor == null) {
      setState(() {
        _busy = false;
        _message = controller.errorMessage.value ?? 'Visitor not found.';
      });
      return;
    }
    await Get.to(() => VisitorDetailsScreen(visitorId: visitor.id));
    if (mounted) _resume();
  }

  Future<void> _resume() async {
    _handled = false;
    if (mounted) {
      setState(() {
        _busy = false;
        _message = null;
      });
    }
    await _scannerController.start();
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.error, required this.onRetry});

  final MobileScannerException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black87,
    padding: const EdgeInsets.all(24),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.no_photography_outlined,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            error.errorCode == MobileScannerErrorCode.permissionDenied
                ? 'Camera permission is needed to scan visitor passes. Enable it in app settings.'
                : 'Camera unavailable. Check camera permission and try again.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry camera')),
        ],
      ),
    ),
  );
}
