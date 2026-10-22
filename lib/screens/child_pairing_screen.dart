
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/pairing_service.dart';

class ChildPairingScreen extends StatefulWidget {
  const ChildPairingScreen({super.key});

  @override
  State<ChildPairingScreen> createState() =>
      _ChildPairingScreenState();
}

class _ChildPairingScreenState
    extends State<ChildPairingScreen> {
  static const blue = Color(0xFF2563EB);

  final _deviceName = TextEditingController(
    text: 'My Android Phone',
  );

  final MobileScannerController _camera =
  MobileScannerController(
    formats: [BarcodeFormat.qrCode],
  );

  bool _processing = false;
  bool _success = false;
  String? _message;

  @override
  void dispose() {
    _deviceName.dispose();
    unawaited(_camera.dispose());
    super.dispose();
  }

  // CAMERA PHÁT HIỆN QR
  void _onDetect(BarcodeCapture capture) {
    if (_processing || _success) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;

      if (value != null && value.isNotEmpty) {
        _pairDevice(value);
        return;
      }
    }
  }

  // GỬI QR CHO API XÁC NHẬN
  Future<void> _pairDevice(String qr) async {
    if (_processing) return;

    final name = _deviceName.text.trim();

    setState(() {
      _processing = true;
      _message = null;
    });

    try {
      await _camera.stop();

      if (name.isEmpty) {
        throw Exception(
          'Please enter your device name.',
        );
      }

      if (!qr.startsWith('kidguard-pair:v1:')) {
        throw Exception(
          'This is not a KidGuard pairing QR.',
        );
      }

      final result = await PairingService.redeem(
        qrPayload: qr,
        deviceName: name,
      );

      if (!mounted) return;

      setState(() {
        _success = true;
        _message = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _message = e.toString()
            .replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }


  void _scanAgain() {
    if (_processing) return;

    setState(() {
      _message = null;
      _success = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    final showCamera =
        !_success && _message == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),

      appBar: AppBar(
        title: const Text('Scan Family QR'),
        backgroundColor: Colors.white,
      ),

      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Icon(
            Icons.qr_code_scanner,
            color: blue,
            size: 66,
          ),

          const SizedBox(height: 14),

          const Text(
            'Pair My Device',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Ask your parent to open '
                'Generate QR Code in KidGuard.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.blueGrey,
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: _deviceName,
            maxLength: 80,
            decoration: InputDecoration(
              labelText: 'Device Name',
              hintText: 'e.g. Samsung Galaxy A55',
              prefixIcon:
              const Icon(Icons.smartphone),
              border: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(14),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 300,
              child: showCamera
                  ? MobileScanner(
                controller: _camera,
                onDetect: _onDetect,
              )
                  : Container(
                color: _success
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                child: Center(
                  child: Icon(
                    _success
                        ? Icons.check_circle
                        : Icons.info_outline,
                    size: 80,
                    color: _success
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          if (_processing)
            const Center(
              child: CircularProgressIndicator(),
            ),

          if (_message != null)
            Card(
              color: _success
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _success
                        ? Colors.green.shade800
                        : Colors.deepOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          if (!_success &&
              _message != null &&
              !_processing)
            FilledButton.icon(
              onPressed: _scanAgain,
              icon: const Icon(
                Icons.qr_code_scanner,
              ),
              label: const Text('Scan Again'),
            ),

          if (_success)
            FilledButton.icon(
              onPressed: () =>
                  Navigator.pop(context),
              icon: const Icon(Icons.check),
              label: const Text('Done'),
            ),

          const SizedBox(height: 20),

          const Text(
            'Only scan the QR generated by '
                'your parent inside KidGuard.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.blueGrey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
