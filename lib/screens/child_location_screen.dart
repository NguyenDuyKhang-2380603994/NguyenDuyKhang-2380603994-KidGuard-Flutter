

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';

class ChildLocationScreen extends StatefulWidget {
  const ChildLocationScreen({super.key});

  @override
  State<ChildLocationScreen> createState() =>
      _ChildLocationScreenState();
}

class _ChildLocationScreenState
    extends State<ChildLocationScreen> {
  static const Color blue = Color(0xFF2563EB);

  bool _sending = false;
  bool _loadingHistory = false;

  String? _message;

  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // TẢI LỊCH SỬ TỪ SQL SERVER
  Future<void> _loadHistory() async {
    if (!mounted) return;

    setState(() => _loadingHistory = true);

    try {
      final list = await LocationService.myHistory();

      if (!mounted) return;

      setState(() {
        _history = list;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _message = e.toString()
            .replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loadingHistory = false);
      }
    }
  }

  // LẤY GPS THẬT VÀ LƯU VÀO DATABASE
  Future<void> _shareCurrentLocation() async {
    if (_sending) return;

    setState(() {
      _sending = true;
      _message = null;
    });

    try {
      // Kiểm tra GPS có bật không
      final enabled =
      await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        throw Exception(
          'Hãy bật Location/GPS trong cài đặt điện thoại.',
        );
      }

      // Kiểm tra quyền vị trí
      var permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
        await Geolocator.requestPermission();
      }

      if (permission ==
          LocationPermission.deniedForever) {
        throw Exception(
          'Quyền GPS bị chặn. '
              'Mở Settings > Apps > KidGuard > Permissions.',
        );
      }

      if (permission == LocationPermission.denied) {
        throw Exception(
          'Bạn chưa cấp quyền vị trí cho KidGuard.',
        );
      }

      // Đọc tọa độ thật từ điện thoại
      final position =
      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 30));

      // Gửi API và lưu SQL Server
      await LocationService.checkIn(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
      );

      if (!mounted) return;

      setState(() {
        _message =
        'Đã gửi vị trí và lưu vào SQL Server thành công!';
      });

      // Làm mới lịch sử
      await _loadHistory();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _message = e.toString()
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
        title: const Text('Share My Location'),
        backgroundColor: Colors.white,
      ),

      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: [
            const Icon(
              Icons.location_on,
              color: blue,
              size: 68,
            ),

            const SizedBox(height: 12),

            const Text(
              'Gửi vị trí cho phụ huynh',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'KidGuard chỉ lấy và lưu GPS khi bạn '
                  'chủ động nhấn nút chia sẻ. '
                  'Không theo dõi vị trí nền.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blueGrey,
              ),
            ),

            const SizedBox(height: 22),

            // NÚT CHIA SẺ GPS
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: blue,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
              ),
              onPressed: _sending
                  ? null
                  : _shareCurrentLocation,
              icon: _sending
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.my_location),
              label: Text(
                _sending
                    ? 'Đang lấy GPS và gửi...'
                    : 'Share My Location',
              ),
            ),

            // THÔNG BÁO KẾT QUẢ
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _message!,
                      style: const TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 25),

            const Text(
              'Lịch sử chia sẻ của tôi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 10),

            if (_loadingHistory)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_history.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Chưa có vị trí nào được lưu.',
                  ),
                ),
              )
            else
              ..._history.map(
                    (p) => Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(
                        Icons.check_circle_outline,
                      ),
                    ),
                    title: Text(
                      kidGuardDate(p['recordedAtUtc']),
                    ),
                    subtitle: Text(
                      'Latitude: ${p['latitude']}\n'
                          'Longitude: ${p['longitude']}\n'
                          'Sai số: ${p['accuracyMeters']} m',
                    ),
                    isThreeLine: true,
                  ),
                ),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
