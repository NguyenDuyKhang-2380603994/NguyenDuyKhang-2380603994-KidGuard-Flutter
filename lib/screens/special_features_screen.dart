
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';

// ============================================
// MÀN HÌNH CHÍNH - 3 CHỨC NĂNG NÂNG CAO
// ============================================
class SpecialFeaturesScreen extends StatelessWidget {
  const SpecialFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FC),
        appBar: AppBar(
          title: const Text('KidGuard Features'),
          backgroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.location_on),
                text: 'GPS',
              ),
              Tab(
                icon: Icon(Icons.sensors),
                text: 'Motion',
              ),
              Tab(
                icon: Icon(Icons.qr_code_scanner),
                text: 'QR',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            LocationFeature(),
            MotionFeature(),
            QrFeature(),
          ],
        ),
      ),
    );
  }
}

// ============================================
// 1. GPS - LẤY VÀ CHIA SẺ VỊ TRÍ
// ============================================
class LocationFeature extends StatefulWidget {
  const LocationFeature({super.key});

  @override
  State<LocationFeature> createState() =>
      _LocationFeatureState();
}

class _LocationFeatureState extends State<LocationFeature> {
  Position? _position;
  String? _error;
  bool _loading = false;

  Future<void> _getLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final enabled =
      await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        throw Exception(
          'Please enable Location on your device.',
        );
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
        await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission denied. '
              'Please allow location access in Settings.',
        );
      }

      final location =
      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 25));

      if (!mounted) return;

      setState(() => _position = location);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString()
            .replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _shareLocation() async {
    final position = _position;
    if (position == null) return;

    final latitude = position.latitude;
    final longitude = position.longitude;

    final mapLink =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

    try {
      await SharePlus.instance.share(
        ShareParams(
          text:
          'KidGuard - My Current Location\n'
              'Latitude: $latitude\n'
              'Longitude: $longitude\n'
              'Google Maps: $mapLink',
          subject: 'KidGuard Location Sharing',
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sharing failed: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const Icon(
          Icons.location_on,
          size: 85,
          color: Color(0xFF2563EB),
        ),

        const SizedBox(height: 15),

        const Text(
          'GPS Location Sharing',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          'Get your current location and share '
              'a Google Maps link with someone you trust.',
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 25),

        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current GPS Position',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const Divider(height: 25),

                Text(
                  'Latitude: '
                      '${_position?.latitude.toStringAsFixed(6) ?? "--"}',
                ),

                const SizedBox(height: 12),

                Text(
                  'Longitude: '
                      '${_position?.longitude.toStringAsFixed(6) ?? "--"}',
                ),

                const SizedBox(height: 12),

                Text(
                  'Accuracy: '
                      '${_position?.accuracy.toStringAsFixed(1) ?? "--"} m',
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 22),

        FilledButton.icon(
          onPressed: _loading ? null : _getLocation,
          icon: const Icon(Icons.my_location),
          label: Text(
            _loading ? 'Getting Location...' : 'Get Location',
          ),
        ),

        const SizedBox(height: 12),

        OutlinedButton.icon(
          onPressed:
          _position == null ? null : _shareLocation,
          icon: const Icon(Icons.share),
          label: const Text('Share Location'),
        ),

        const SizedBox(height: 16),

        const Text(
          'Location is requested only when you '
              'tap Get Location. Sharing requires '
              'your action and recipient selection.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.blueGrey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ============================================
// 2. MOTION SENSOR - GIA TỐC ĐIỆN THOẠI
// ============================================
class MotionFeature extends StatefulWidget {
  const MotionFeature({super.key});

  @override
  State<MotionFeature> createState() =>
      _MotionFeatureState();
}

class _MotionFeatureState extends State<MotionFeature> {
  StreamSubscription<UserAccelerometerEvent>? _sensor;

  double _x = 0;
  double _y = 0;
  double _z = 0;
  double _strength = 0;

  int _movementCount = 0;
  bool _isMoving = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    _sensor = userAccelerometerEvents.listen(
          (event) {
        if (!mounted) return;

        final strength = sqrt(
          event.x * event.x +
              event.y * event.y +
              event.z * event.z,
        );

        final moving = strength > 1.8;

        setState(() {
          _x = event.x;
          _y = event.y;
          _z = event.z;
          _strength = strength;

          if (moving && !_isMoving) {
            _movementCount++;
          }

          _isMoving = moving;
          _error = null;
        });
      },
      onError: (error) {
        if (!mounted) return;

        setState(() {
          _error = 'Sensor error: $error';
        });
      },
      cancelOnError: true,
    );
  }

  @override
  void dispose() {
    _sensor?.cancel();
    super.dispose();
  }

  Widget _axis(String name, double value) {
    return ListTile(
      title: Text('$name Axis'),
      trailing: Text(
        value.toStringAsFixed(2),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Icon(
          _isMoving
              ? Icons.vibration
              : Icons.smartphone,
          size: 85,
          color: _isMoving
              ? Colors.orange
              : const Color(0xFF2563EB),
        ),

        const SizedBox(height: 16),

        const Text(
          'Motion Detection',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          'Detect acceleration and movement '
              'using the phone sensor.',
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 25),

        Card(
          color: _isMoving
              ? Colors.orange.shade50
              : Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Text(
                  _isMoving
                      ? 'MOVEMENT DETECTED'
                      : 'DEVICE STABLE',
                  style: TextStyle(
                    color: _isMoving
                        ? Colors.deepOrange
                        : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Acceleration: '
                      '${_strength.toStringAsFixed(2)} m/s²',
                ),

                const SizedBox(height: 10),

                Text(
                  'Movement Events: $_movementCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        Card(
          color: Colors.white,
          child: Column(
            children: [
              _axis('X', _x),
              _axis('Y', _y),
              _axis('Z', _z),
            ],
          ),
        ),

        const SizedBox(height: 16),

        OutlinedButton.icon(
          onPressed: () {
            setState(() => _movementCount = 0);
          },
          icon: const Icon(Icons.restart_alt),
          label: const Text('Reset Counter'),
        ),

        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          ),

        const SizedBox(height: 12),

        const Text(
          'Shake or move the device to trigger detection. '
              'This is a movement demo, not fall detection.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.blueGrey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ============================================
// 3. QR SCANNER - QUÉT MÃ BẰNG CAMERA
// ============================================
class QrFeature extends StatefulWidget {
  const QrFeature({super.key});

  @override
  State<QrFeature> createState() =>
      _QrFeatureState();
}

class _QrFeatureState extends State<QrFeature> {
  String? _result;

  void _onDetect(BarcodeCapture capture) {
    if (_result != null) return;
    if (capture.barcodes.isEmpty) return;

    final value = capture.barcodes.first.rawValue;

    if (value == null || value.isEmpty) return;

    setState(() {
      _result = value;
    });
  }

  Future<void> _copyResult() async {
    final result = _result;
    if (result == null) return;

    await Clipboard.setData(
      ClipboardData(text: result),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR content copied!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'QR Code Scanner',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Scan a QR code with your camera.',
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 18),

        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 280,
            child: _result == null
                ? MobileScanner(
              onDetect: _onDetect,
            )
                : Container(
              color: const Color(0xFFE8F0FF),
              child: const Center(
                child: Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Colors.green,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scanned Result',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 12),

                SelectableText(
                  _result ?? 'Waiting for QR code...',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 15),

        if (_result != null) ...[
          FilledButton.icon(
            onPressed: _copyResult,
            icon: const Icon(Icons.copy),
            label: const Text('Copy Result'),
          ),

          const SizedBox(height: 10),

          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _result = null;
              });
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan Again'),
          ),
        ],

        const SizedBox(height: 15),

        const Text(
          'For safety, scanned QR content is displayed '
              'but not opened automatically.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.blueGrey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
