
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../services/sos_service.dart';

class ChildSosScreen extends StatefulWidget {
  const ChildSosScreen({super.key});

  @override
  State<ChildSosScreen> createState() =>
      _ChildSosScreenState();
}

class _ChildSosScreenState extends State<ChildSosScreen> {
  StreamSubscription<UserAccelerometerEvent>? _sensor;

  bool _armed = false;
  bool _confirming = false;
  bool _sending = false;

  int _shakeCount = 0;
  DateTime? _firstShake;
  DateTime? _lastPeak;

  String _status = 'SOS is ready';

  @override
  void dispose() {
    _sensor?.cancel();
    super.dispose();
  }

  void _toggleShake(bool enabled) {
    if (!enabled) {
      _sensor?.cancel();
      _sensor = null;
      _shakeCount = 0;
      _firstShake = null;

      setState(() {
        _armed = false;
        _status = 'Shake detection disabled';
      });
      return;
    }

    _sensor = userAccelerometerEventStream(
      samplingPeriod:
      const Duration(milliseconds: 100),
    ).listen(
      _onMotion,
      onError: (error) {
        if (!mounted) return;
        _toggleShake(false);
        setState(() {
          _status =
          'Motion sensor unavailable: $error';
        });
      },
      cancelOnError: true,
    );

    setState(() {
      _armed = true;
      _status = 'Shake your phone 3 times';
    });
  }

  void _onMotion(UserAccelerometerEvent event) {
    if (!_armed || _confirming || _sending) return;

    final intensity = sqrt(
      event.x * event.x +
          event.y * event.y +
          event.z * event.z,
    );

    // Chỉ tính chuyển động mạnh
    if (intensity < 12.0) return;

    final now = DateTime.now();

    // Tránh đếm liên tục cùng một nhịp lắc
    if (_lastPeak != null &&
        now.difference(_lastPeak!).inMilliseconds < 350) {
      return;
    }

    _lastPeak = now;

    // Ba nhịp phải diễn ra trong 3 giây
    if (_firstShake == null ||
        now.difference(_firstShake!) >
            const Duration(seconds: 3)) {
      _firstShake = now;
      _shakeCount = 1;
    } else {
      _shakeCount++;
    }

    if (_shakeCount >= 3) {
      _shakeCount = 0;
      _firstShake = null;
      _confirmSos('Shake');
    }
  }

  Future<void> _confirmSos(String trigger) async {
    if (_confirming || _sending) return;

    _confirming = true;

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Emergency SOS'),
          content: const Text(
            'Send an SOS alert to your parent? '
                'KidGuard will also try to attach '
                'your current location.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Send SOS'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        await _sendSos(trigger);
      }
    } finally {
      _confirming = false;
    }
  }

  Future<void> _sendSos(String trigger) async {
    setState(() {
      _sending = true;
      _status = 'Sending SOS...';
    });

    double? latitude;
    double? longitude;

    try {
      // Vị trí là tùy chọn; thiếu GPS vẫn gửi SOS
      try {
        final enabled =
        await Geolocator.isLocationServiceEnabled();

        if (enabled) {
          var permission =
          await Geolocator.checkPermission();

          if (permission == LocationPermission.denied) {
            permission =
            await Geolocator.requestPermission();
          }

          if (permission != LocationPermission.denied &&
              permission !=
                  LocationPermission.deniedForever) {
            final position =
            await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
              ),
            ).timeout(const Duration(seconds: 7));

            latitude = position.latitude;
            longitude = position.longitude;
          }
        }
      } catch (_) {
        // GPS không có vẫn tiếp tục gửi SOS
      }

      await SosService.send(
        triggerType: trigger,
        latitude: latitude,
        longitude: longitude,
      );

      if (!mounted) return;

      _sensor?.cancel();
      _sensor = null;

      setState(() {
        _armed = false;
        _status =
        'SOS saved successfully! '
            'Ask your parent to check Safety Alerts.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Emergency alert saved to KidGuard!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _status = e.toString()
            .replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 20),

          const Icon(
            Icons.sos,
            size: 86,
            color: Colors.red,
          ),

          const SizedBox(height: 15),

          const Text(
            'Emergency Help',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'Request help from your parent '
                'when you feel unsafe.',
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // NÚT SOS THỦ CÔNG
          SizedBox(
            height: 75,
            child: FilledButton.icon(
              onPressed: _sending
                  ? null
                  : () => _confirmSos('Button'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              icon: const Icon(
                Icons.warning_amber_rounded,
                size: 30,
              ),
              label: const Text(
                'SEND SOS',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),

          // CẢM BIẾN LẮC
          Card(
            color: Colors.white,
            child: SwitchListTile(
              title: const Text(
                'Enable Shake Detection',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Shake the phone 3 times to '
                    'request an SOS confirmation.',
              ),
              secondary: const Icon(
                Icons.vibration,
                color: Color(0xFF2563EB),
              ),
              value: _armed,
              onChanged: _sending
                  ? null
                  : _toggleShake,
            ),
          ),

          const SizedBox(height: 16),

          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 30,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_sending) ...[
                    const SizedBox(height: 15),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 22),

          const Text(
            'SOS requires an internet connection. '
                'If there is immediate danger, contact '
                'local emergency services directly. '
                'Shake detection works only while '
                'this screen is open.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }
}
