
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/sos_service.dart';

class ParentSosScreen extends StatefulWidget {
  const ParentSosScreen({super.key});

  @override
  State<ParentSosScreen> createState() =>
      _ParentSosScreenState();
}

class _ParentSosScreenState extends State<ParentSosScreen> {
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _alerts = [];

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
      final items = await SosService.getFamilyAlerts();

      if (!mounted) return;
      setState(() => _alerts = items);
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

  Future<void> _acknowledge(int id) async {
    try {
      await SosService.acknowledge(id);

      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> _openMap(
      Map<String, dynamic> item,
      ) async {
    final latitude = item['latitude'];
    final longitude = item['longitude'];

    if (latitude == null || longitude == null) return;

    final url = Uri.https(
      'www.google.com',
      '/maps/search/',
      {
        'api': '1',
        'query': '$latitude,$longitude',
      },
    );

    final success = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot open Google Maps'),
        ),
      );
    }
  }

  String _date(dynamic value) {
    final date =
    DateTime.tryParse(value?.toString() ?? '');

    if (date == null) return '-';

    final local = date.toLocal();

    String two(int n) => n.toString().padLeft(2, '0');

    return '${two(local.day)}/${two(local.month)}/'
        '${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  Widget _alertCard(Map<String, dynamic> item) {
    final acknowledged =
        item['acknowledgedAtUtc'] != null;

    final hasGps =
        item['latitude'] != null &&
            item['longitude'] != null;

    final id = item['id'] as int;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 13),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  acknowledged
                      ? Icons.check_circle
                      : Icons.warning_amber_rounded,
                  color: acknowledged
                      ? Colors.green
                      : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item['childName']?.toString() ??
                        'Child',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              acknowledged
                  ? 'Acknowledged'
                  : 'Needs Attention',
              style: TextStyle(
                color: acknowledged
                    ? Colors.green
                    : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Trigger: ${item['triggerType']}',
            ),

            Text(
              'Sent: ${_date(item['createdAtUtc'])}',
            ),

            if (acknowledged)
              Text(
                'Seen: ${_date(item['acknowledgedAtUtc'])}',
              ),

            if (!hasGps)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'GPS not available for this alert',
                  style: TextStyle(
                    color: Colors.blueGrey,
                  ),
                ),
              ),

            const SizedBox(height: 12),

            if (hasGps)
              OutlinedButton.icon(
                onPressed: () => _openMap(item),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Open Location'),
              ),

            if (!acknowledged)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _acknowledge(id),
                  icon: const Icon(Icons.check),
                  label: const Text('Mark as Seen'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _alerts.where(
          (x) => x['acknowledgedAtUtc'] == null,
    ).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('Safety Alerts'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
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
            const Text(
              'Family SOS Alerts',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              '$pending alerts need attention',
              style: TextStyle(
                color: pending > 0
                    ? Colors.red
                    : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            if (_loading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(_error!),
                ),
              )
            else if (_alerts.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(22),
                    child: Text(
                      'No SOS alerts from your children.',
                    ),
                  ),
                )
              else
                ..._alerts.map(_alertCard),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}
