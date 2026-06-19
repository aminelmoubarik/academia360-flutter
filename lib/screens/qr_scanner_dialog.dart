import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/theme.dart';

class ScannedAttendanceCode {
  final String code;
  final String method;
  final String formatLabel;

  const ScannedAttendanceCode({
    required this.code,
    required this.method,
    required this.formatLabel,
  });
}

class QrBarcodeScannerDialog extends StatefulWidget {
  const QrBarcodeScannerDialog({super.key});

  @override
  State<QrBarcodeScannerDialog> createState() => _QrBarcodeScannerDialogState();
}

class _QrBarcodeScannerDialogState extends State<QrBarcodeScannerDialog> {
  late final MobileScannerController _controller;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value == null || value.isEmpty) continue;
      _handled = true;
      await _controller.stop();
      if (!mounted) return;
      Navigator.of(context).pop(
        ScannedAttendanceCode(
          code: value,
          method: barcode.format == BarcodeFormat.qrCode ? 'qr' : 'barcode',
          formatLabel: _formatLabel(barcode.format),
        ),
      );
      return;
    }
  }

  String _formatLabel(BarcodeFormat format) {
    return format == BarcodeFormat.qrCode ? 'QR Code' : 'Código de barras';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final size = MediaQuery.sizeOf(context);
    final width = size.width >= 780 ? 680.0 : size.width - 24;
    final height = size.height >= 760 ? 680.0 : size.height - 24;

    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(bottom: BorderSide(color: c.line)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Brand.blue.withValues(alpha: c.isDark ? 0.22 : 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.qr_code_scanner_outlined, color: Brand.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ler QR / código de barras', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: c.ink)),
                        Text('Aponte a câmera para o cartão do estudante.', style: TextStyle(fontSize: 12.5, color: c.muted)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _controller,
                    fit: BoxFit.cover,
                    onDetect: _onDetect,
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.45),
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.45),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(color: Brand.blue.withValues(alpha: 0.35), blurRadius: 24),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Quando o código for detetado, o campo da picagem será preenchido automaticamente.',
                              style: TextStyle(color: Colors.white, fontSize: 12.5, height: 1.35),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            tooltip: 'Lanterna',
                            onPressed: () => _controller.toggleTorch(),
                            icon: const Icon(Icons.flashlight_on_outlined),
                          ),
                          const SizedBox(width: 6),
                          IconButton.filledTonal(
                            tooltip: 'Trocar câmera',
                            onPressed: () => _controller.switchCamera(),
                            icon: const Icon(Icons.cameraswitch_outlined),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
