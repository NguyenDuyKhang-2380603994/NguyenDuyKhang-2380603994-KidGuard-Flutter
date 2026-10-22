import 'child_approval_screen.dart';
import 'safe_timer_screen.dart';
import 'package:flutter/material.dart';
import 'child_pairing_screen.dart';
import '../services/auth_service.dart';
import '../services/child_service.dart';
import '../utils/logout_helper.dart';
import 'child_sos_screen.dart';
import 'child_location_screen.dart';

class ChildDashboard extends StatefulWidget {
  const ChildDashboard({super.key});

  @override
  State<ChildDashboard> createState() =>
      _ChildDashboardState();
}

class _ChildDashboardState extends State<ChildDashboard> {
  static const blue = Color(0xFF2563EB);
  static const navy = Color(0xFF172554);

  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ChildService.getMyProfile();

      if (!mounted) return;

      setState(() => _profile = result);
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

  Widget _detail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 85,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.blueGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: navy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = AuthService.fullName?.trim();

    final displayName =
    name != null && name.isNotEmpty
        ? name
        : (AuthService.username ?? 'Child');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          'KidGuard Child',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: navy,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Profile',
            onPressed: _loadProfile,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sign Out',
            onPressed: () =>
                LogoutHelper.signOut(context),
            icon: const Icon(
              Icons.logout,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              'Hi, $displayName!',
              style: const TextStyle(
                color: navy,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Welcome to your safe family space.',
              style: TextStyle(color: Colors.blueGrey),
            ),

            const SizedBox(height: 22),

            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [blue, Color(0xFF1E40AF)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: Colors.white,
                    size: 40,
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stay Safe!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          'Your family is here to support you.',
                          style: TextStyle(
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'My Profile',
              style: TextStyle(
                fontSize: 20,
                color: navy,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: _loading
                    ? const Center(
                  child: CircularProgressIndicator(),
                )
                    : _error != null
                    ? Column(
                  children: [
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    TextButton(
                      onPressed: _loadProfile,
                      child: const Text('Retry'),
                    ),
                  ],
                )
                    : Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.account_circle,
                          color: blue,
                          size: 29,
                        ),
                        SizedBox(width: 9),
                        Text(
                          'Personal Information',
                          style: TextStyle(
                            fontWeight:
                            FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 25),

                    _detail(
                      'Name',
                      _profile?['name']
                          ?.toString() ??
                          '-',
                    ),
                    _detail(
                      'Age',
                      _profile?['age']
                          ?.toString() ??
                          '-',
                    ),
                    _detail(
                      'Device',
                      _profile?['device']
                          ?.toString() ??
                          '-',
                    ),

                    const Chip(
                      avatar: Icon(
                        Icons.lock_outline,
                        size: 17,
                      ),
                      label: Text('Read-only Profile'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Safety Tools',
              style: TextStyle(
                fontSize: 20,
                color: navy,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(15),
                leading: const CircleAvatar(
                  radius: 25,
                  backgroundColor: Color(0xFFE0F2FE),
                  child: Icon(
                    Icons.location_on,
                    color: blue,
                  ),
                ),
                title: const Text(
                  'Share My Location',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Send a GPS check-in to your parent',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const ChildLocationScreen(),
                    ),
                  );
                },
              ),
            ),

            Card(
              color: Colors.white,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFE6E6),
                  child: Icon(
                    Icons.sos,
                    color: Colors.red,
                  ),
                ),
                title: const Text(
                  'Emergency SOS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Shake phone or send emergency alert',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChildSosScreen(),
                    ),
                  );
                },
              ),
            ),

            Card(
              color: Colors.white,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2FE),
                  child: Icon(
                    Icons.timer_outlined,
                    color: blue,
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

            Card(
              color: Colors.white,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEDE9FE),
                  child: Icon(
                    Icons.lock_person_outlined,
                    color: Colors.deepPurple,
                  ),
                ),
                title: const Text(
                  'Ask Parent',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Request permission to watch or browse',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChildApprovalScreen(),
                    ),
                  );
                },
              ),
            ),



            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(15),
                leading: const CircleAvatar(
                  radius: 25,
                  backgroundColor: Color(0xFFE0F2FE),
                  child: Icon(
                    Icons.qr_code_scanner,
                    color: Color(0xFF2563EB),
                  ),
                ),
                title: const Text(
                  'Scan Family QR',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Connect this phone to your family',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const ChildPairingScreen(),
                    ),
                  );
                },
              ),
            ),


            const SizedBox(height: 15),

            const Text(
              'GPS sharing is initiated by you. '
                  'KidGuard does not track you in the background.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blueGrey,
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
