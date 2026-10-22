
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/pairing_service.dart';

class ParentPairingScreen extends StatefulWidget {
  const ParentPairingScreen({super.key});

  @override
  State<ParentPairingScreen> createState() =>
      _ParentPairingScreenState();
}

class _ParentPairingScreenState
    extends State<ParentPairingScreen> {
  static const blue = Color(0xFF2563EB);

  bool _loading = true;
  bool _creating = false;
  String? _error;

  List<Map<String, dynamic>> _children = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await PairingService.family();

      if (!mounted) return;

      setState(() {
        _children = data;
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


  Future<void> _generateQr(
      Map<String, dynamic> child,
      ) async {
    if (_creating) return;

    setState(() => _creating = true);

    try {
      final childId = child['childId'] as int;

      // Tạo QR thật bằng ASP.NET Core API
      final data = await PairingService.create(childId);

      if (!mounted) return;

      final qr = data['qrPayload']?.toString() ?? '';

      if (qr.isEmpty) {
        throw Exception('API không trả về mã QR.');
      }

      final childName =
          child['childName']?.toString() ?? 'Child';

      // Mở lại nút sau khi API đã tạo QR
      setState(() => _creating = false);

      // Mở mã QR trên màn hình riêng
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: const Color(0xFFF5F7FC),

            appBar: AppBar(
              title: const Text('KidGuard QR Code'),
              backgroundColor: Colors.white,
            ),

            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),

                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 65,
                      color: Color(0xFF2563EB),
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      'Connect Child Device',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Child: $childName',
                      style: const TextStyle(
                        fontSize: 17,
                      ),
                    ),

                    const SizedBox(height: 25),

                    Container(
                      padding: const EdgeInsets.all(20),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(22),
                      ),

                      child: QrImageView(
                        data: qr,
                        version: QrVersions.auto,
                        size: 250,
                        backgroundColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'QR expires in 5 minutes',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Open KidGuard on your child phone.\n'
                          'Go to Scan Family QR and scan this code.',
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      if (mounted) {
        await _load();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }


  Widget _childCard(Map<String, dynamic> child) {
    final childName =
        child['childName']?.toString() ?? 'Child';

    final paired = child['isPaired'] == true;

    final hasAccount =
        child['hasChildAccount'] == true;

    final deviceName =
    child['deviceName']?.toString();

    final pairedTime = DateTime.tryParse(
      child['pairedAtUtc']?.toString() ?? '',
    )?.toLocal();

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: paired
                      ? Colors.green.shade50
                      : const Color(0xFFE8F0FF),
                  child: Icon(
                    paired
                        ? Icons.verified
                        : Icons.smartphone,
                    color: paired ? Colors.green : blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    childName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              paired
                  ? 'Device Paired'
                  : 'Not Paired Yet',
              style: TextStyle(
                color: paired
                    ? Colors.green
                    : Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),

            if (paired && deviceName != null)
              Text('Device: $deviceName'),

            if (pairedTime != null)
              Text(
                'Paired: '
                    '${pairedTime.day}/${pairedTime.month}/'
                    '${pairedTime.year} '
                    '${pairedTime.hour.toString().padLeft(2, "0")}:'
                    '${pairedTime.minute.toString().padLeft(2, "0")}',
              ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: !_creating && hasAccount
                    ? () => _generateQr(child)
                    : null,
                icon: const Icon(Icons.qr_code),
                label: Text(
                  paired
                      ? 'Pair Another Device'
                      : 'Generate QR Code',
                ),
              ),
            ),

            if (!hasAccount)
              const Text(
                'Create a Child login account first.',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),

      appBar: AppBar(
        title: const Text('Family Device Pairing'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
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
              Icons.qr_code_2,
              color: blue,
              size: 68,
            ),

            const SizedBox(height: 12),

            const Text(
              'Connect Child Device',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Generate a secure QR code and '
                  'scan it from the KidGuard app '
                  'on your child phone.',
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
            else if (_children.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'No child accounts found. '
                          'Open Manage Children first.',
                    ),
                  ),
                )
              else
                ..._children.map(_childCard),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
