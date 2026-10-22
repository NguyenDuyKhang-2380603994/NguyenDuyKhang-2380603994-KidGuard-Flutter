
import 'package:flutter/material.dart';
import '../utils/utc_time.dart';
import '../services/approval_service.dart';

class ParentApprovalScreen extends StatefulWidget {
  const ParentApprovalScreen({super.key});

  @override
  State<ParentApprovalScreen> createState() =>
      _ParentApprovalScreenState();
}

class _ParentApprovalScreenState
    extends State<ParentApprovalScreen> {
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _requests = [];

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
      final data = await ApprovalService.family();

      if (!mounted) return;

      setState(() => _requests = data);
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

  Future<void> _decide(
      Map<String, dynamic> item,
      bool approve,
      ) async {
    final title = item['title']?.toString() ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          approve ? 'Approve Content' : 'Reject Content',
        ),
        content: Text(
          '${approve ? "Allow" : "Reject"} "$title"?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: Text(
              approve ? 'Approve' : 'Reject',
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ApprovalService.decide(
        id: item['id'] as int,
        approve: approve,
      );

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

  Widget _requestCard(Map<String, dynamic> item) {
    final status = item['status']?.toString()
        ?? 'Pending';

    final pending = status == 'Pending';
    final approved = status == 'Approved';

    final child = item['childName']?.toString()
        ?? 'Child';

    final title = item['title']?.toString() ?? '';

    final url = item['url']?.toString() ?? '';

    final minutes = item['minutes'];

    final expiry = parseKidGuardUtc(
      item['accessExpiresAtUtc'],
    );

    final expired = expiry != null &&
        !expiry.isAfter(DateTime.now().toUtc());

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              child,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.blueGrey,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            SelectableText(url),

            const SizedBox(height: 8),

            Text('Requested time: $minutes minutes'),

            const SizedBox(height: 10),

            Text(
              expired && approved
                  ? 'Expired'
                  : status,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: pending
                    ? Colors.orange
                    : approved && !expired
                    ? Colors.green
                    : Colors.red,
              ),
            ),

            const SizedBox(height: 12),

            if (pending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _decide(item, false),
                      child: const Text('Reject'),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          _decide(item, true),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),

            if (approved && !expired)
              OutlinedButton.icon(
                onPressed: () => _decide(item, false),
                icon: const Icon(Icons.block),
                label: const Text('Revoke Access'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _requests
        .where((x) => x['status'] == 'Pending')
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),

      appBar: AppBar(
        title: const Text('Parent Approval Center'),
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
            const Icon(
              Icons.fact_check_outlined,
              size: 65,
              color: Color(0xFF2563EB),
            ),

            const SizedBox(height: 12),

            const Text(
              'Approval Requests',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '$pending requests waiting for approval',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            if (_loading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_error != null)
              Text(
                _error!,
                style: const TextStyle(
                  color: Colors.red,
                ),
              )
            else if (_requests.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(22),
                    child: Text(
                      'No requests yet.',
                    ),
                  ),
                )
              else
                ..._requests.map(_requestCard),
          ],
        ),
      ),
    );
  }
}
