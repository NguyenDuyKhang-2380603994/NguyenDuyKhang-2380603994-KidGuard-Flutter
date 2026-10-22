
import 'package:flutter/material.dart';
import 'safe_timer_screen.dart';
import '../services/admin_service.dart';
import '../utils/logout_helper.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() =>
      _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const blue = Color(0xFF2563EB);
  static const navy = Color(0xFF172554);

  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await AdminService.getUsers();

      if (!mounted) return;
      setState(() => _users = result);
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

  Future<void> _deleteUser(
      Map<String, dynamic> user,
      ) async {
    final username =
        user['username']?.toString() ?? '';
    final id = user['id']?.toString() ?? '';

    if (id.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text(
          'Delete account "$username" permanently?\n'
              'This action cannot be undone.',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await AdminService.deleteUser(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadUsers();
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

  Widget _stat(
      String label,
      int value,
      IconData icon,
      ) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE6EAF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: blue, size: 29),
          const SizedBox(height: 12),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parents = _users.where((u) =>
    (u['roles'] as List?)?.contains('Parent') == true
    ).length;

    final children = _users.where((u) =>
    (u['roles'] as List?)?.contains('Child') == true
    ).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          'KidGuard Admin',
          style: TextStyle(
            color: navy,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(
              Icons.logout,
              color: Colors.redAccent,
            ),
            onPressed: () =>
                LogoutHelper.signOut(context),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadUsers,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'System Overview',
              style: TextStyle(
                color: navy,
                fontWeight: FontWeight.bold,
                fontSize: 25,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Manage registered KidGuard accounts',
              style: TextStyle(color: Colors.blueGrey),
            ),

            const SizedBox(height: 20),

            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(25),
                  child: CircularProgressIndicator(),
                ),
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
            else ...[
                Row(
                  children: [
                    Expanded(
                      child: _stat(
                        'Total Accounts',
                        _users.length,
                        Icons.people_outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _stat(
                        'Parent Accounts',
                        parents,
                        Icons.family_restroom,
                      ),
                    ),
                  ],
                ),

                Card(
                  color: Colors.white,
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE0F2FE),
                      child: Icon(
                        Icons.timer_outlined,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    title: const Text(
                      'Safety Promise',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      'Check in on time or trigger SOS',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SafeTimerScreen(),
                        ),
                      );
                    },
                  ),
                ),


                const SizedBox(height: 12),

                _stat(
                  'Child Accounts',
                  children,
                  Icons.child_care,
                ),

                const SizedBox(height: 28),

                const Text(
                  'Account Management',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),

                const SizedBox(height: 12),

                if (_users.isEmpty)
                  const Text('No accounts found.'),

                ..._users.map((user) {
                  final roles =
                      (user['roles'] as List?)
                          ?.map((r) => r.toString())
                          .toList() ??
                          [];

                  final isAdmin = roles.contains('Admin');

                  return Card(
                    color: Colors.white,
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                              const Color(0xFFE4EDFF),
                              child: Icon(
                                isAdmin
                                    ? Icons.shield
                                    : Icons.person,
                                color: blue,
                              ),
                            ),
                            title: Text(
                              user['fullName']
                                  ?.toString() ??
                                  'Unnamed User',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Username: ${user['username'] ?? ''}\n'
                                  'Email: ${user['email'] ?? ''}\n'
                                  'Role: ${roles.join(', ')}',
                            ),
                            isThreeLine: true,
                          ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: isAdmin
                                ? const Chip(
                              label: Text('Protected Admin'),
                            )
                                : TextButton.icon(
                              onPressed: () =>
                                  _deleteUser(user),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              label: const Text(
                                'Delete Account',
                                style: TextStyle(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
          ],
        ),
      ),
    );
  }
}
