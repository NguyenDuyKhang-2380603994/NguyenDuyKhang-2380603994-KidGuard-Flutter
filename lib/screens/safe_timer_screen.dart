import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../services/sos_service.dart';

class SafeTimerScreen extends StatefulWidget {
  const SafeTimerScreen({super.key});

  @override
  State<SafeTimerScreen> createState() => _SafeTimerScreenState();
}

class _SafeTimerScreenState extends State<SafeTimerScreen>
    with WidgetsBindingObserver {
  static const Color blue = Color(0xFF2563EB);
  static const List<int> presetMinutes = [1, 3, 5, 10];

  Timer? _timer;
  DateTime? _deadline;

  int _minutes = 1;
  int _secondsLeft = 0;

  bool _active = false;
  bool _sending = false;
  bool _sosSent = false;
  bool _sendFailed = false;

  String _status = 'Ready to start';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _tick();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Tự nhập số phút trong khoảng 1-180.
  Future<void> _chooseCustomMinutes() async {
    if (_active || _sending) return;

    String value = _minutes.toString();
    final formKey = GlobalKey<FormState>();

    final chosen = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tự chọn thời gian'),
        content: Form(
          key: formKey,
          child: TextFormField(
            initialValue: value,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Số phút',
              hintText: 'Ví dụ: 15',
              helperText: 'Nhập từ 1 đến 180 phút',
              border: OutlineInputBorder(),
            ),
            onChanged: (text) => value = text,
            validator: (text) {
              final minutes = int.tryParse(text ?? '');
              if (minutes == null || minutes < 1 || minutes > 180) {
                return 'Chọn từ 1 đến 180 phút';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogContext, int.parse(value));
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (!mounted || chosen == null) return;
    setState(() => _minutes = chosen);
  }

  Future<void> _startTimer() async {
    if (_active || _sending) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Safety Promise'),
        content: Text(
          'Bắt đầu hẹn giờ $_minutes phút?\n\n'
              'Nếu không bấm "Con an toàn" trước khi hết giờ, '
              'KidGuard sẽ cố gắng gửi SOS cho phụ huynh.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Bắt đầu'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    _timer?.cancel();
    setState(() {
      _deadline = DateTime.now().add(Duration(minutes: _minutes));
      _secondsLeft = _minutes * 60;
      _active = true;
      _sosSent = false;
      _sendFailed = false;
      _status = 'Đang chờ con xác nhận an toàn';
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted || !_active || _sending) return;
    final deadline = _deadline;
    if (deadline == null) return;

    final milliseconds = deadline.difference(DateTime.now()).inMilliseconds;
    final remaining = milliseconds <= 0 ? 0 : (milliseconds + 999) ~/ 1000;

    if (remaining <= 0) {
      _timer?.cancel();
      setState(() {
        _secondsLeft = 0;
        _active = false;
        _deadline = null;
        _sending = true;
        _status = 'Hết giờ! Đang gửi SOS...';
      });
      _sendAutomaticSos();
      return;
    }

    setState(() => _secondsLeft = remaining);
  }

  void _markSafe() {
    if (!_active || _sending) return;
    _timer?.cancel();

    setState(() {
      _active = false;
      _deadline = null;
      _secondsLeft = 0;
      _sosSent = false;
      _sendFailed = false;
      _status = 'Con đã xác nhận an toàn!';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã xác nhận an toàn trước hạn.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _retrySos() async {
    if (_sending || _active || !_sendFailed) return;
    setState(() {
      _sending = true;
      _status = 'Đang thử gửi lại SOS...';
    });
    await _sendAutomaticSos();
  }

  Future<void> _sendAutomaticSos() async {
    double? latitude;
    double? longitude;

    // GPS không bắt buộc: vẫn gửi được SOS nếu không cấp quyền.
    try {
      if (await Geolocator.isLocationServiceEnabled()) {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
            ),
          ).timeout(const Duration(seconds: 6));
          latitude = position.latitude;
          longitude = position.longitude;
        }
      }
    } catch (_) {
      // Lỗi GPS không được làm mất cảnh báo SOS.
    }

    try {
      await SosService.send(
        triggerType: 'SafetyTimer',
        latitude: latitude,
        longitude: longitude,
      );
      if (!mounted) return;
      setState(() {
        _sosSent = true;
        _sendFailed = false;
        _status = 'SOS đã gửi thành công! Phụ huynh có thể xem trong Safety Alerts.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sosSent = false;
        _sendFailed = true;
        _status = 'Không gửi được SOS: '
            '${error.toString().replaceFirst('Exception: ', '')}';
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mm = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final ss = (_secondsLeft % 60).toString().padLeft(2, '0');
    final progress = _active
        ? (_secondsLeft / (_minutes * 60)).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final isCustom = !presetMinutes.contains(_minutes);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        title: const Text('Safety Promise'),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const SizedBox(height: 15),
          Icon(
            _sosSent ? Icons.warning_amber_rounded : Icons.health_and_safety,
            size: 78,
            color: _sosSent ? Colors.red : blue,
          ),
          const SizedBox(height: 16),
          const Text(
            'My Safety Promise',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Xác nhận an toàn trước khi hết giờ.\n'
                'Nếu không, KidGuard sẽ cố gắng gửi SOS.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    '$mm:$ss',
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: _secondsLeft <= 15 && _active ? Colors.red : blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 9,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _sendFailed ? Colors.red : null,
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
          const SizedBox(height: 20),
          const Text(
            'Choose Safety Timer',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final minutes in presetMinutes)
                ChoiceChip(
                  label: Text('$minutes min'),
                  selected: _minutes == minutes,
                  onSelected: _active || _sending
                      ? null
                      : (_) => setState(() => _minutes = minutes),
                ),
              ChoiceChip(
                avatar: const Icon(Icons.edit_outlined, size: 16),
                label: Text(isCustom ? 'Tự chọn ($_minutes phút)' : 'Tự chọn'),
                selected: isCustom,
                onSelected: _active || _sending
                    ? null
                    : (_) => _chooseCustomMinutes(),
              ),
            ],
          ),
          const SizedBox(height: 28),
          if (!_active && !_sending)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: blue,
                padding: const EdgeInsets.all(18),
              ),
              onPressed: _startTimer,
              icon: const Icon(Icons.timer),
              label: Text('Start Safety Promise ($_minutes phút)'),
            ),
          if (_active)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.all(18),
              ),
              onPressed: _markSafe,
              icon: const Icon(Icons.check_circle),
              label: const Text("I'm Safe - Con an toàn"),
            ),
          if (_sendFailed && !_active && !_sending)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton.icon(
                onPressed: _retrySos,
                icon: const Icon(Icons.refresh),
                label: const Text('Gửi lại SOS'),
              ),
            ),
          const SizedBox(height: 20),
          const Text(
            'Giữ màn hình này mở và kết nối internet. '
                'Bản hiện tại chưa đảm bảo gửi SOS khi ứng dụng bị đóng '
                'hoặc hệ điều hành dừng ứng dụng.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }
}
