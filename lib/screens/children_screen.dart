
import 'package:flutter/material.dart';

import '../services/child_service.dart';
import 'add_child_account_screen.dart';

class ChildrenScreen extends StatefulWidget {
  const ChildrenScreen({super.key});

  @override
  State<ChildrenScreen> createState() =>
      _ChildrenScreenState();
}

class _ChildrenScreenState extends State<ChildrenScreen> {
  static const blue = Color(0xFF2563EB);
  static const navy = Color(0xFF172554);

  List<Map<String, dynamic>> _children = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ChildService.getChildren();

      if (!mounted) return;

      setState(() {
        _children = result
            .map((e) =>
        Map<String, dynamic>.from(e as Map))
            .toList();
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

  // TẠO ACCOUNT CHILD + LIÊN KẾT PARENT
  Future<void> _addChild() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddChildAccountScreen(),
      ),
    );

    if (created == true && mounted) {
      await _loadChildren();
    }
  }

  // CHỈNH SỬA HỒ SƠ CHILD
  Future<void> _editChild(
      Map<String, dynamic> child,
      ) async {
    final updated = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EditChildDialog(child: child),
    );

    if (updated == null || !mounted) return;

    try {
      await ChildService.updateChild(
        id: child['id'] as int,
        name: updated['name'] as String,
        age: updated['age'] as int,
        device: updated['device'] as String,
      );

      if (!mounted) return;
      await _loadChildren();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
        ),
      );
    } catch (e) {
      _showError(e);
    }
  }

  // XÓA HỒ SƠ
  Future<void> _deleteChild(
      Map<String, dynamic> child,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Child Profile'),
        content: Text(
          'Delete profile "${child['name']}"?\n'
              'This deletes the profile, not necessarily '
              'the linked login account.',
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
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ChildService.deleteChild(
        child['id'] as int,
      );

      if (!mounted) return;
      await _loadChildren();
    } catch (e) {
      _showError(e);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error.toString()
              .replaceFirst('Exception: ', ''),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _childCard(Map<String, dynamic> child) {
    final name = child['name']?.toString() ?? 'Child';
    final age = child['age']?.toString() ?? '-';
    final device = child['device']?.toString() ?? '-';

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(19),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 27,
                  backgroundColor: Color(0xFFE4EDFF),
                  child: Icon(
                    Icons.child_care,
                    color: blue,
                    size: 29,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Age: $age',
                        style: const TextStyle(
                          color: Colors.blueGrey,
                        ),
                      ),
                      Text(
                        'Device: $device',
                        style: const TextStyle(
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 25),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editChild(child),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),

                TextButton.icon(
                  onPressed: () => _deleteChild(child),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  label: const Text(
                    'Delete',
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
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
        backgroundColor: Colors.white,
        title: const Text(
          'Manage Children',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChildren,
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        onPressed: _addChild,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Child Account'),
      ),

      body: RefreshIndicator(
        onRefresh: _loadChildren,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'My Children',
              style: TextStyle(
                color: navy,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Child accounts are linked to your '
                  'Parent account automatically.',
              style: TextStyle(
                color: Colors.blueGrey,
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
                    padding: EdgeInsets.all(25),
                    child: Column(
                      children: [
                        Icon(
                          Icons.family_restroom,
                          size: 48,
                          color: Colors.blueGrey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No children yet',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Tap Add Child Account to get started.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                  Text(
                    '${_children.length} linked profiles',
                    style: const TextStyle(
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._children.map(_childCard),
                ],

            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}

// DIALOG EDIT RIÊNG ĐỂ QUẢN LÝ CONTROLLER AN TOÀN
class _EditChildDialog extends StatefulWidget {
  final Map<String, dynamic> child;

  const _EditChildDialog({required this.child});

  @override
  State<_EditChildDialog> createState() =>
      _EditChildDialogState();
}

class _EditChildDialogState extends State<_EditChildDialog> {
  final _key = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _device;

  @override
  void initState() {
    super.initState();

    _name = TextEditingController(
      text: widget.child['name']?.toString(),
    );

    _age = TextEditingController(
      text: widget.child['age']?.toString(),
    );

    _device = TextEditingController(
      text: widget.child['device']?.toString(),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _device.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Child Profile'),
      content: Form(
        key: _key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Full Name',
              ),
              validator: (v) =>
              v == null || v.trim().isEmpty
                  ? 'Required'
                  : null,
            ),
            TextFormField(
              controller: _age,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Age',
              ),
              validator: (v) {
                final age = int.tryParse(v ?? '');
                if (age == null || age < 1 || age > 17) {
                  return 'Enter age from 1 to 17';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _device,
              decoration: const InputDecoration(
                labelText: 'Device Name',
              ),
              validator: (v) =>
              v == null || v.trim().isEmpty
                  ? 'Required'
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_key.currentState!.validate()) return;

            Navigator.pop(context, {
              'name': _name.text.trim(),
              'age': int.parse(_age.text.trim()),
              'device': _device.text.trim(),
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
