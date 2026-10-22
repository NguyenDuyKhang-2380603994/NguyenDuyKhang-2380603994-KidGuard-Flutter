
import 'package:flutter/material.dart';
import '../utils/utc_time.dart';
import '../services/approval_service.dart';
import 'approved_content_screen.dart';

class ChildApprovalScreen extends StatefulWidget {
  const ChildApprovalScreen({super.key});

  @override
  State<ChildApprovalScreen> createState() =>
      _ChildApprovalScreenState();
}

class _ChildApprovalScreenState
    extends State<ChildApprovalScreen> {
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
      final items = await ApprovalService.mine();

      if (!mounted) return;

      setState(() => _requests = items);
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

  Future<void> _newRequest() async {
    final title = TextEditingController();
    final url = TextEditingController();
    final minutes = TextEditingController(text: '20');

    final formKey = GlobalKey<FormState>();

    try {
      final values = await showDialog<Map<String, String>>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Ask Parent'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: title,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Content Title',
                      hintText: 'English Learning',
                    ),
                    validator: (v) =>
                    v == null || v.trim().isEmpty
                        ? 'Required'
                        : null,
                  ),

                  TextFormField(
                    controller: url,
                    keyboardType: TextInputType.url,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      labelText: 'Website URL',
                      hintText: 'https://example.com/',
                    ),
                    validator: (v) {
                      final uri =
                      Uri.tryParse(v?.trim() ?? '');

                      if (uri == null ||
                          uri.scheme != 'https' ||
                          !uri.hasAuthority ||
                          !uri.isAbsolute) {
                        return 'Enter a valid HTTPS link';
                      }

                      return null;
                    },
                  ),

                  TextFormField(
                    controller: minutes,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Minutes (1-60)',
                    ),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');

                      if (n == null || n < 1 || n > 60) {
                        return 'Enter 1 to 60 minutes';
                      }

                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                Navigator.pop(dialogContext, {
                  'title': title.text.trim(),
                  'url': url.text.trim(),
                  'minutes': minutes.text.trim(),
                });
              },
              child: const Text('Send Request'),
            ),
          ],
        ),
      );

      if (values == null || !mounted) return;

      await ApprovalService.requestContent(
        title: values['title']!,
        url: values['url']!,
        minutes: int.parse(values['minutes']!),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Request sent to Parent successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      await _load();
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
      title.dispose();
      url.dispose();
      minutes.dispose();
    }
  }

  Future<void> _openContent(
      Map<String, dynamic> item,
      ) async {
    try {
      final id = item['id'] as int;

      // Backend kiểm tra Parent đã duyệt chưa
      // và bắt đầu giới hạn thời gian.
      final session = await ApprovalService.open(id);

      if (!mounted) return;

      final approvedUrl =
          session['url']?.toString() ?? '';

      final expiry = parseKidGuardUtc(
        session['expiresAtUtc'],
      );

      if (expiry == null) {
        throw Exception('Thời gian hết hạn không hợp lệ.');
      }

      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => ApprovedContentScreen(
            approvalId: id,
            title: session['title']?.toString()
                ?? 'Approved Content',
            approvedUrl: approvedUrl,
            expiresAtUtc: expiry,
          ),
        ),
      );

      if (!mounted) return;

      if (result != null && result.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result)),
        );
      }

      await _load();
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
    }
  }

  Widget _requestCard(Map<String, dynamic> item) {
    final status = item['status']?.toString()
        ?? 'Pending';

    final approved = status == 'Approved';

    final expires = parseKidGuardUtc(
      item['accessExpiresAtUtc'],
    );

    final expired = expires != null &&
        !expires.isAfter(DateTime.now().toUtc());

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['title']?.toString() ?? 'Content',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '${item['minutes']} minutes requested',
            ),

            const SizedBox(height: 8),

            Text(
              expired && approved
                  ? 'Expired'
                  : status,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: status == 'Pending'
                    ? Colors.orange
                    : approved && !expired
                    ? Colors.green
                    : Colors.red,
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                // Chỉ bật khi Parent phê duyệt
                onPressed: approved && !expired
                    ? () => _openContent(item)
                    : null,
                icon: Icon(
                  approved
                      ? Icons.play_arrow
                      : Icons.lock_outline,
                ),
                label: Text(
                  approved && !expired
                      ? 'Open Approved Content'
                      : 'Waiting / Unavailable',
                ),
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
        title: const Text('My Permissions'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      floatingActionButton:
      FloatingActionButton.extended(
        onPressed: _newRequest,
        icon: const Icon(Icons.add),
        label: const Text('Ask Parent'),
      ),

      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: [
            const Icon(
              Icons.lock_person_outlined,
              size: 67,
              color: Color(0xFF2563EB),
            ),

            const SizedBox(height: 12),

            const Text(
              'Ask Before You Watch',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Request permission to view '
                  'online content inside KidGuard.',
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
                      'No requests yet. Tap Ask Parent.',
                    ),
                  ),
                )
              else
                ..._requests.map(_requestCard),

            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}
