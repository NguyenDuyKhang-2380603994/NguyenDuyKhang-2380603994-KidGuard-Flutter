
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/location_service.dart';

class ParentLocationScreen extends StatefulWidget {
  const ParentLocationScreen({super.key});

  @override
  State<ParentLocationScreen> createState() =>
      _ParentLocationScreenState();
}

class _ParentLocationScreenState
    extends State<ParentLocationScreen> {
  static const Color blue = Color(0xFF2563EB);

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ĐỌC VỊ TRÍ CỦA CON TỪ API
  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items =
      await LocationService.familyHistory();

      if (!mounted) return;

      setState(() {
        _items = items;
      });
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

  // MỞ GOOGLE MAPS
  Future<void> _openMap(
      Map<String, dynamic> item,
      ) async {
    final lat = item['latitude'].toString();
    final lng = item['longitude'].toString();

    final url = Uri.https(
      'www.google.com',
      '/maps/search/',
      {
        'api': '1',
        'query': '$lat,$lng',
      },
    );

    try {
      final success = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!success) {
        throw Exception(
          'Không mở được Google Maps.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),

      appBar: AppBar(
        title: const Text('Family Location'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: [
            const Icon(
              Icons.family_restroom,
              color: blue,
              size: 62,
            ),

            const SizedBox(height: 10),

            const Text(
              'Vị trí con đã chia sẻ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Chỉ xem vị trí của các hồ sơ con '
                  'thuộc gia đình đang đăng nhập.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blueGrey,
              ),
            ),

            const SizedBox(height: 24),

            if (_loading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ),
              )
            else if (_items.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Chưa có vị trí nào được chia sẻ. '
                          'Kiểm tra Child đã liên kết Parent '
                          'và gửi GPS chưa.',
                    ),
                  ),
                )
              else
                ..._items.map(
                      (p) => Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: blue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  p['childName']
                                      ?.toString() ??
                                      'Child',
                                  style: const TextStyle(
                                    fontWeight:
                                    FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'Thời gian: '
                                '${kidGuardDate(p['recordedAtUtc'])}',
                          ),

                          Text(
                            'Latitude: ${p['latitude']}',
                          ),

                          Text(
                            'Longitude: ${p['longitude']}',
                          ),

                          Text(
                            'Sai số: '
                                '${p['accuracyMeters']} m',
                          ),

                          const SizedBox(height: 9),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () =>
                                  _openMap(p),
                              icon: const Icon(
                                Icons.map_outlined,
                              ),
                              label: const Text(
                                'Open Google Maps',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
